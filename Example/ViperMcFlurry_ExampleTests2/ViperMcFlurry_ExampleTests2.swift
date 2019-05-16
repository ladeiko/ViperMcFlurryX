//
//  ViperMcFlurry_ExampleTests2.swift
//  ViperMcFlurry_ExampleTests2
//
//  Created by Siarhei Ladzeika on 5/2/19.
//  Copyright © 2019 Egor Tolstoy. All rights reserved.
//

import XCTest
import ViperMcFlurryX

class TestController: UIViewController {
    
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
    var isInProgress: Bool {
        return isBeingDismissed || isBeingPresented || isMovingToParent || isMovingFromParent
    }
}

extension XCTestCase {
    
    func setupCustomRootController() {
        // HACK :)
        // Wait a little to avoid: Unbalanced calls to begin/end appearance transitions for <UIViewController: 0x7ffe17e28000>
        // while changed rootViewController
        //
        let hackExpectation = XCTestExpectation(description: "")
        UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        DispatchQueue.main.async {
            hackExpectation.fulfill()
        }
        wait(for: [hackExpectation], timeout: 1)
    }
}

class ViperMcFlurry_ExampleTests2: XCTestCase {
    
    override func setUp() {
        self.continueAfterFailure = false
    }
    
    func testSimpleDismiss() {
        
        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
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
        
}
