//
//  ViperMcFlurry_ExampleTests.swift
//  ViperMcFlurry_ExampleTests
//
//  Created by Siarhei Ladzeika on 5/2/19.
//  Copyright © 2019 Egor Tolstoy. All rights reserved.
//

import XCTest
import ViperMcFlurryX

@objcMembers
fileprivate class Presenter: NSObject, RamblerViperModuleInput {
    var moduleDidSkipOnDismissCalledCounter = 0
    func moduleDidSkipOnDismiss() {
        moduleDidSkipOnDismissCalledCounter += 1
    }
}

@objcMembers
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

extension UIViewController {
    fileprivate var isInProgress: Bool {
        return isBeingDismissed || isBeingPresented || isMovingToParent || isMovingFromParent
    }
}

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

class ViperMcFlurry_ExampleTests: XCTestCase {
    
    override func setUp() {
        self.continueAfterFailure = false
    }
    
    func testCompilation() {
        let handler: RamblerViperModuleTransitionHandlerProtocol! = UIViewController()
        handler!.skipOnDismiss = true
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
            controller.closeToModule(withIdentifier: "root", animated: true) {
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
            controller.closeToModule(withIdentifier: "first", animated: true) {
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
                        controller4.closeToModule(withIdentifier: "2", animated: true) {
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
        controller1.view.addSubview(controller2.view)
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

//    func testDeepUnwind() {
//
//        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
//        defer {
//            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
//        }
//
//        let tb = UITabBarController()
//
//        let rootViewController = UIViewController()
//        rootViewController.moduleIdentifier = "stop"
//        let nc1 = UINavigationController(rootViewController: rootViewController)
//        tb.viewControllers = [nc1]
//
//        UIApplication.shared.keyWindow!.rootViewController = tb
//
//        nc1.pushViewController(UIViewController(), animated: false)
//        nc1.pushViewController(UIViewController(), animated: false)
//
//        let sub = UIViewController()
//        nc1.pushViewController(sub, animated: false)
//
//
//        let nc2 = UINavigationController(rootViewController: UIViewController())
//        sub.present(nc2, animated: false, completion: nil)
//
//        nc2.pushViewController(UIViewController(), animated: false)
//
//        let expectation = XCTestExpectation(description: "")
//
//        nc2.topViewController?.closeToModule(withIdentifier: "stop", animated: true, completion: {
////        tb.dismiss(animated: true, completion: {
////            expectation.fulfill()
////        })
//            expectation.fulfill()
//        })
//
//        wait(for: [expectation], timeout: 10)
//
//        XCTAssert(UIApplication.shared.keyWindow!.rootViewController === tb)
//        XCTAssertEqual(tb.viewControllers, [nc1])
//        XCTAssertEqual(nc1.viewControllers, [rootViewController])
//    }
}
