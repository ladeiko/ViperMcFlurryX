//
//  RootPresenter.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import Foundation
import ViperMcFlurryX_Swift

fileprivate enum RootPresenterState {
    case initial
    case ready
    case deinitialized
}

class RootPresenter: NSObject, ViperModuleInput, RootModuleInput, RootViewOutput, RootInteractorOutput, ViperModuleOutput {

    // MARK: - VIPER Vars

    weak var view: RootViewInput!
    var interactor: RootInteractorInput!
    var router: RootRouterInput!
    weak var output: RootModuleOutput?
    private final var state: RootPresenterState = .initial

    // MARK: - Vars

    private final var config: RootModuleInputConfig!

    // MARK: - Life cycle

    func willDeinit() {
        if state == .ready {
            interactor.deinitialize()
            // TODO: Place your code here
        }
        state = .deinitialized
    }

    // MARK: - ViperModuleInput

    func setModuleOutput(_ moduleOutput: ViperModuleOutput!) {
        output = moduleOutput as? RootModuleOutput
    }

    // MARK: - RootViewOutput

    func viewIsReady() {
        assert(state == .ready)
        // TODO: Place your code here
    }
    
    func didTapOnClose() {
        router.dismiss()
    }

    // MARK: - RootModuleInput

    func configure(with config: RootModuleInputConfig) {
        assert(state == .initial)
        state = .ready
        
        self.config = config
        interactor.configure(with: config)
        
    }

    // MARK: - RootInteractorOutput
    // TODO: Place your code here

    // MARK: - Helpers
    // TODO: Place your code here
}
