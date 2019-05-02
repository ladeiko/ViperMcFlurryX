//
//  ViperMcFlurry_ExampleTests.swift
//  ViperMcFlurry_ExampleTests
//
//  Created by Siarhei Ladzeika on 5/2/19.
//  Copyright © 2019 Egor Tolstoy. All rights reserved.
//

import XCTest
import ViperMcFlurryX

class TestController: UIViewController {
    
    typealias Completion = () -> Void
    
    private let completion: Completion
    
    init(_ completion: @escaping Completion) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.completion()
    }
}

class ViperMcFlurry_ExampleTests: XCTestCase {

    func testSimpleDismiss() {
        let closedExpectation = XCTestExpectation(description: "closedExpectation")
        
        let controller = TestController {
            closedExpectation.fulfill()
        }
        
        UIApplication.shared.keyWindow!.rootViewController!.present(controller, animated: true, completion: {
            controller.closeCurrentModule(true)
        })
        
        wait(for: [closedExpectation], timeout: 10)
    }


}
