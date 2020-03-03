//
//  RootViewController.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import SwiftUI

typealias RootViewController = RootViewControllerImpl<RootRootView>

class RootViewControllerImpl<Content>: UIHostingController<Content>, RootViewInput where Content : RootRootViewProtocol {

    // MARK: - VIPER Vars

    var output: RootViewOutput!

    // MARK: - Vars
    // TODO: Place your code here

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewIsReady()
    }

    // MARK: - RootViewInput
    // TODO: Place your code here

    // MARK: - Helpers
    // TODO: Place your code here
}

extension RootViewControllerImpl: RootRootViewDelegate {

    // MARK: - UI Actions
    // TODO: Place your code here

    func didTapOnSampleButton() {
        print("did tap on sample button")
        rootView.viewState.sampleValue += 1
    }
    
    func didTapOnClose() {
        output.didTapOnClose()
    }

}
