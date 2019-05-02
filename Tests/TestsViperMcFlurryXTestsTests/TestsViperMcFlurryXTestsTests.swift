//
//  TestsViperMcFlurryXTestsTests.swift
//  TestsViperMcFlurryXTestsTests
//
//  Created by Siarhei Ladzeika on 5/2/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import XCTest
import ViperMcFlurryX

class TestController: UIViewController {
    
    typealias Completion = () -> Void
    
    private let disappearCompletion: Completion
    
    init(_ disappearCompletion: @escaping Completion) {
        self.disappearCompletion = disappearCompletion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disappearCompletion()
    }
}

class TestsViperMcFlurryXTestsTests: XCTestCase {
    
    func testSimpleDismiss() {
        
        UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        let controller = TestController {
            closedExpectation.fulfill()
        }
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller, animated: true, completion: {
            controller.closeCurrentModule(true)
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nil)
    }
    
    func testSimpleNavigationDismiss() {
        
        UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        let controller = TestController {
            closedExpectation.fulfill()
        }
        
        let nc = UINavigationController(rootViewController: controller)
        
        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeCurrentModule(true)
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nil)
    }
    
    func testComplexNavigationDismiss() {
        
        UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        let controller = TestController {
            closedExpectation.fulfill()
        }
        
        let nc = UINavigationController(rootViewController: UIViewController())
        nc.pushViewController(controller, animated: false)
        
        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeCurrentModule(true)
        })
        
        wait(for: [closedExpectation], timeout: 10)
        
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.children.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nc)
        XCTAssert(nc.children.count == 1)
    }
    
}
