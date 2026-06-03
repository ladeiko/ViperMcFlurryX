//
//  ViperMcFlurry_ExampleTests.swift
//  ViperMcFlurry_ExampleTests
//
//  Created by Siarhei Ladzeika on 5/2/19.
//  Copyright © 2019 Egor Tolstoy. All rights reserved.
//

import XCTest
import ViperMcFlurryX_Swift

fileprivate class Presenter: ViperModuleInput {
    var moduleDidSkipOnDismissCalledCounter = 0
    func moduleDidSkipOnDismiss() {
        moduleDidSkipOnDismissCalledCounter += 1
    }
}

fileprivate class TestController: UIViewController {
    
    let output = Presenter()
    
    private static func rnd() -> CGFloat {
        return CGFloat(arc4random() % 256)/255
    }
    
    private static var i = 0
    private static let colors: [UIColor] = stride(from: 0, to: 10, by: 1).map({ _ -> UIColor in UIColor(red: rnd(),
                                                                                                        green: rnd(),
                                                                                                        blue: rnd(),
                                                                                                        alpha: 1) })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cl = type(of: self)
        view.backgroundColor = cl.colors[cl.i % cl.colors.count]
        cl.i += 1
    }
}

//extension TestController: ViperModuleViewControllerPresenter {
//    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool {
//        return true
//    }
//
//    func viperModuleViewControllerPresent(in viewController: UIViewController) {
//        viewController.present(self, animated: true, completion: nil)
//    }
//}
//
//
//extension TestController: ViperModuleViewControllerDismisser {
//    func viperModuleViewControllerDismiss(animated: Bool, _ completion: (() -> Void)?) {
//        dismiss(animated: animated, completion: completion)
//    }
//}

extension UIViewController {
    fileprivate var isInProgress: Bool {
        return isBeingDismissed || isBeingPresented || isMovingToParent || isMovingFromParent
    }
}

@MainActor
extension XCTestCase {

    fileprivate func setupCustomRootController() {
        // HACK :)
        // Wait a little to avoid: Unbalanced calls to begin/end appearance transitions for <UIViewController: 0x7ffe17e28000>
        // while changed rootViewController
        //
        let hackExpectation = XCTestExpectation(description: "")

        waitForAnimationCompletion(UIApplication.shared.keyWindow!.rootViewController!)

        UIView.performWithoutAnimation {
            UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        }

        waitForAnimationCompletion(UIApplication.shared.keyWindow!.rootViewController!)

        DispatchQueue.main.async {
            hackExpectation.fulfill()
        }
        wait(for: [hackExpectation], timeout: 1)
    }
    
    fileprivate func waitForAnimationCompletion(_ viewController: UIViewController) {
        // TODO

        while viewController.isBeingPresented || viewController.isBeingDismissed || viewController.isMovingToParent || viewController.isMovingFromParent {
            RunLoop.current.run(until: .distantFuture)
        }
    }
}

@MainActor
class ViperMcFlurry_Swift_ExampleTests: XCTestCase {
    
    override func setUp() {
        self.continueAfterFailure = false
    }
    
    func testCompilation() {
        let handler: ViperModuleTransitionHandler! = UIViewController()
        handler!.skipOnDismiss = true
    }
    
    func test_skipOnDismiss_set_get() {
        let controller = UIViewController() as ViperModuleTransitionHandler
        
        XCTAssertFalse(controller.skipOnDismiss)
        
        controller.skipOnDismiss = true
        XCTAssertTrue(controller.skipOnDismiss)
        
        controller.skipOnDismiss = false
        XCTAssertFalse(controller.skipOnDismiss)
    }
    
    func test_moduleIdentifier_set_get() {
        let controller = UIViewController() as ViperModuleTransitionHandler
        
        XCTAssertEqual(controller.moduleIdentifier, "")
        
        controller.moduleIdentifier = "29348902384"
        XCTAssertEqual(controller.moduleIdentifier, "29348902384")
        
        controller.moduleIdentifier = ""
        XCTAssertEqual(controller.moduleIdentifier, "")
    }
    
    func testSimpleDismiss() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            waitForAnimationCompletion(UIApplication.shared.keyWindow!.rootViewController!)
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        let controller = TestController()
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller, animated: true, completion: {
            controller.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })
        
        wait(for: [closedExpectation], timeout: 10)
        XCTAssertFalse(controller.isInProgress)
    }
    
    func testDeepDismiss() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        func test(animated: Bool) {
            let depth = 5
            
            for i in stride(from: depth - 1, through: 0, by: -1) {
                
                setupCustomRootController()
            
                let controllers = stride(from: 0, to: depth, by: 1).map({ _ -> TestController in TestController() })
                
                let presentExpectation = XCTestExpectation(description: "presentExpectation")
                
                var controllersToPresent = controllers
                
                func present() {
                    
                    if controllersToPresent.isEmpty {
                        presentExpectation.fulfill()
                        return
                    }
                    
                    var top = UIApplication.shared.keyWindow!.rootViewController!
                    
                    while top.presentedViewController != nil {
                        top = top.presentedViewController!
                    }
                    
                    top.present(controllersToPresent.removeFirst(), animated: false, completion: {
                        present()
                    })
                }
                
                present()
                
                wait(for: [presentExpectation], timeout: 10)
                
                let closedExpectation = XCTestExpectation(description: "closedExpectation")
                
                controllers[i].closeCurrentModule(animated) {
                    closedExpectation.fulfill()
                }
                
                wait(for: [closedExpectation], timeout: 10)
                
                XCTAssertFalse(controllers.reduce(false) { $0 || $1.isInProgress })
                XCTAssertEqual(controllers.filter({ $0.presentingViewController != nil && controllers.firstIndex(of: $0)! < i }).count, i)
            }
        }
        
        test(animated: false)
        test(animated: true)
    }
    
    func testSimpleNavigationControllerDismiss() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        func test(animated: Bool) {
            let depth = 5
            
            for i in stride(from: depth - 1, through: 0, by: -1) {
                
                setupCustomRootController()
                
                let controllers = stride(from: 0, to: depth, by: 1).map({ _ -> TestController in TestController() })
                
                let presentExpectation = XCTestExpectation(description: "presentExpectation")
                
                let nc = UINavigationController()
                nc.viewControllers = controllers
                
                UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: false) {
                    presentExpectation.fulfill()
                }
                
                wait(for: [presentExpectation], timeout: 10)
                
                let closedExpectation = XCTestExpectation(description: "closedExpectation")
                
                controllers[i].closeCurrentModule(animated) {
                    closedExpectation.fulfill()
                }
                
                wait(for: [closedExpectation], timeout: 10)
                
                XCTAssertFalse(controllers.reduce(false) { $0 || $1.isInProgress })
                XCTAssertTrue(
                    (i > 0 && UIApplication.shared.keyWindow!.rootViewController!.presentedViewController!.isKind(of: UINavigationController.self) && nc.viewControllers.count == i)
                    || (i == 0 && UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nil)
                )
                XCTAssertEqual(controllers.filter({ $0.presentingViewController != nil && controllers.firstIndex(of: $0)! < i }).count, i)
            }
        }
        
        test(animated: false)
        test(animated: true)
    }
    
    func testComplexNavigationControllerDismiss() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller = TestController()
        
        let nc = UINavigationController(rootViewController: UIViewController())
        nc.pushViewController(controller, animated: false)
        
        waitForAnimationCompletion(nc)
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nc)
        XCTAssert(nc.children.count == 1)
    }

    func testCloseToIdentifier() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller = TestController()

        let nc = UINavigationController(rootViewController: UIViewController())
        nc.pushViewController(controller, animated: false)

        waitForAnimationCompletion(nc)

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.moduleIdentifier = "root"

        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeToModuleWithIdentifier("root", animated: true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
    }

    func testCloseToIdentifier2() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller = TestController()

        let nc = UINavigationController(rootViewController: UIViewController())
        nc.pushViewController(UIViewController(), animated: false)
        nc.pushViewController(controller, animated: false)

        waitForAnimationCompletion(nc)

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        nc.viewControllers.first!.moduleIdentifier = "first"

        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeToModuleWithIdentifier("first", animated: true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nc)
        XCTAssert(nc.children.count == 1)
    }

    func testCloseToIdentifier3() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        let controller1 = UIViewController()
        let controller2 = UIViewController()
        let controller3 = UIViewController()
        let controller4 = UIViewController()

        controller2.moduleIdentifier = "2"

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: false, completion: {
            controller1.present(controller2, animated: false) {
                controller2.present(controller3, animated: false) {
                    controller3.present(controller4, animated: false) {
                        controller4.closeToModuleWithIdentifier("2", animated: true) {
                            closedExpectation.fulfill()
                        }
                    }
                }
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == controller1)
        XCTAssert(controller1.presentedViewController == controller2)
        XCTAssertNil(controller2.presentedViewController)
    }
    
    func testPassthroughSimple() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller1 = TestController()
        let controller2 = TestController()
        
        controller1.skipOnDismiss = true
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.closeCurrentModule(true) {
                    closedExpectation.fulfill()
                }
            })
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 0)
    }
    
    func testPassthroughTriplexHalf() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller1 = TestController()
        let controller2 = TestController()
        let controller3 = TestController()
        
        controller2.skipOnDismiss = true
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.present(controller3, animated: true, completion: {
                    controller3.closeCurrentModule(true) {
                        closedExpectation.fulfill()
                    }
                })
            })
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController === controller1)
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller3.output.moduleDidSkipOnDismissCalledCounter, 0)
    }
    
    func testPassthroughSimpleTriplex() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller1 = TestController()
        let controller2 = TestController()
        let controller3 = TestController()
        
        controller1.skipOnDismiss = true
        controller2.skipOnDismiss = true
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.present(controller3, animated: true, completion: {
                    controller3.closeCurrentModule(true) {
                        closedExpectation.fulfill()
                    }
                })
            })
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller3.output.moduleDidSkipOnDismissCalledCounter, 0)
    }
    
    func testPassthroughNavigation() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller1 = TestController()

        let rootViewController = TestController()
        rootViewController.skipOnDismiss = true
        let nc = UINavigationController(rootViewController: rootViewController)

        nc.pushViewController(controller1, animated: false)
        
        waitForAnimationCompletion(nc)
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller1.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(rootViewController.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
    }

    func testPassthroughNavigation2() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()

        let rootViewController = TestController()
        let nc = UINavigationController(rootViewController: rootViewController)
        nc.skipOnDismiss = true
        nc.pushViewController(controller1, animated: false)

        waitForAnimationCompletion(nc)

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller1.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertEqual(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController, nc)
        XCTAssertEqual(nc.viewControllers, [rootViewController])
        XCTAssertEqual(rootViewController.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
    }
        
    func testPassthroughChild() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }
        
        setupCustomRootController()
        
        let controller1 = TestController()
        let controller2 = TestController()
        
        controller2.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller2.view.frame = controller2.view.bounds
        
        controller1.addChild(controller2)
        controller2.beginAppearanceTransition(true, animated: false)
        controller1.view.addSubview(controller2.view)
        controller2.endAppearanceTransition()
        controller2.didMove(toParent: controller1)
        
        controller1.skipOnDismiss = true
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller2.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 0)
    }

    func testCloseTop() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()
        let controller2 = TestController()
        let controller3 = TestController()

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.present(controller3, animated: true, completion: {
                    controller1.closeTopModules(true) {
                        closedExpectation.fulfill()
                    }
                })
            })
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertEqual(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController, controller1)
        XCTAssertNil(controller1.presentedViewController)
    }

}

// MARK: - Bug-fix regression tests

private final class BugFixOutput: ViperModuleOutput {}

private final class BugFixInput: ViperModuleInput {
    private(set) var setOutputCallCount = 0
    private(set) var lastSetOutput: ViperModuleOutput?
    func setModuleOutput(_ moduleOutput: ViperModuleOutput) {
        setOutputCallCount += 1
        lastSetOutput = moduleOutput
    }
}

/// A destination view controller that exposes its module input via the
/// "traditional" `output` property (exercised by the Mirror-based lookup in
/// `moduleInputInterface`).
private final class BugFixTraditionalVC: UIViewController {
    let output = BugFixInput()
}

/// A destination presenter view controller that has NO module input but wants
/// to be presented. Records how many times it was asked to present.
private final class BugFixPresenterVC: UIViewController, ViperModuleViewControllerPresenter {
    private(set) var presentCallCount = 0
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool { return true }
    func viperModuleViewControllerPresent(in viewController: UIViewController) { presentCallCount += 1 }
}

private final class BugFixFactory: ViperModuleFactory {
    private let viewController: UIViewController
    init(_ viewController: UIViewController) { self.viewController = viewController }
    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler { return viewController }
}

@MainActor
class ViperMcFlurry_Swift_BugFixTests: XCTestCase {

    // #2: when a module has a module input, thenChainUsingBlock must receive it
    // and the returned output must be wired back via setModuleOutput.
    func test_openModuleUsingFactory_deliversModuleInput_andWiresOutput() {
        let destination = UIViewController()
        let input = BugFixInput()
        destination.moduleInputInterface = input

        let output = BugFixOutput()
        var receivedInput: ViperModuleInput?

        let source = UIViewController()
        source.openModuleUsingFactory(BugFixFactory(destination))
            .thenChainUsingBlock { moduleInput -> ViperModuleOutput? in
                receivedInput = moduleInput
                return output
            }

        XCTAssertTrue(receivedInput === input, "chain block should receive the destination's module input")
        XCTAssertEqual(input.setOutputCallCount, 1)
        XCTAssertTrue(input.lastSetOutput === output, "returned output should be set back on the module input")
    }

    // #2 regression: a module with a NIL module input must still (a) invoke the
    // chain block (with a nil input, matching the Obj-C implementation) and
    // (b) run the post-link action (the present/transition step). Before the
    // fix the Swift promise gated linking on `moduleInput != nil`, so neither
    // the block nor present fired.
    func test_openModuleUsingFactory_firesPresent_evenWhenModuleInputIsNil() {
        let destination = BugFixPresenterVC()
        XCTAssertNil(destination.moduleInputInterface, "precondition: destination has no module input")

        var chainCalled = false
        var receivedNonNilInput = false
        let source = UIViewController()
        source.openModuleUsingFactory(BugFixFactory(destination))
            .thenChainUsingBlock { moduleInput -> ViperModuleOutput? in
                chainCalled = true
                receivedNonNilInput = (moduleInput != nil)
                return nil
            }

        XCTAssertTrue(chainCalled, "chain block must be invoked even with a nil module input")
        XCTAssertFalse(receivedNonNilInput, "chain block should receive nil when the module has no input")
        XCTAssertEqual(destination.presentCallCount, 1, "post-link present must fire despite a nil module input")
    }

    // #5: thenChainUsingBlock links regardless of call order relative to the
    // module input being set (here the chain is set first via openModuleUsingFactory).
    func test_chain_links_whenModuleInputPresent_singleSetOutput() {
        let destination = UIViewController()
        let input = BugFixInput()
        destination.moduleInputInterface = input

        let source = UIViewController()
        source.openModuleUsingFactory(BugFixFactory(destination))
            .thenChainUsingBlock { _ -> ViperModuleOutput? in return BugFixOutput() }

        XCTAssertEqual(input.setOutputCallCount, 1, "link should run exactly once")
    }

    // #4: moduleInputInterface resolves the "traditional" `output` property via
    // reflection.
    func test_moduleInputInterface_reflectsOutputProperty() {
        let vc = BugFixTraditionalVC()
        XCTAssertTrue(vc.moduleInputInterface === vc.output)
    }

    // #4 robustness: reflecting an arbitrary controller with no `output` and no
    // association must return nil and must not crash (the previous force-unwrap
    // of a Mirror child label could trap).
    func test_moduleInputInterface_nilForPlainController_doesNotCrash() {
        let vc = UIViewController()
        XCTAssertNil(vc.moduleInputInterface)
    }

    // An explicitly assigned module input takes precedence and round-trips.
    func test_moduleInputInterface_explicitAssignmentRoundTrips() {
        let vc = UIViewController()
        let input = BugFixInput()
        vc.moduleInputInterface = input
        XCTAssertTrue(vc.moduleInputInterface === input)
    }

    // #3: the Swift segue bridge. The single Obj-C `prepareForSegue:` swizzle
    // hands the (nav-unwrapped) destination to the Swift ViperOpenModulePromise
    // via the `swift_bridge_prepareForSegueWithDestination:` selector. Driving
    // that selector directly proves the promise gets populated with the
    // destination's module input (the new code path behind fix #3, which the
    // example app only exercises for the Obj-C promise).
    func test_swiftBridge_deliversDestinationModuleInputToPromise() {
        let promise = ViperOpenModulePromise()
        let destination = UIViewController()
        let input = BugFixInput()
        destination.moduleInputInterface = input

        promise.perform(NSSelectorFromString("swift_bridge_prepareForSegueWithDestination:"),
                        with: destination)

        var received: ViperModuleInput?
        promise.thenChainUsingBlock { moduleInput -> ViperModuleOutput? in
            received = moduleInput
            return nil
        }
        XCTAssertTrue(received === input,
                      "segue bridge should populate the promise with the destination's module input")
    }
}
