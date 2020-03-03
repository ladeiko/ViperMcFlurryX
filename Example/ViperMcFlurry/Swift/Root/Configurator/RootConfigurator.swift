//
//  RootConfigurator.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import UIKit
import OnDeallocateX
import ViperMcFlurryX_Swift

class RootModuleConfigurator: ViperModuleFactory {

    func configureModuleForViewInput<UIViewController>(viewInput: UIViewController, with config: RootModuleInputConfig) {
        if let viewController = viewInput as? RootViewController {
            configure(viewController: viewController, with: config)
        }
    }

    private func configure(viewController: RootViewController, with config: RootModuleInputConfig) {

        guard viewController.output == nil else { // prevent double configuration
            return
        }

        let router = RootRouter()

        let presenter = RootPresenter()
        presenter.view = viewController
        presenter.router = router

        let interactor = RootInteractor()
        interactor.output = presenter

        presenter.interactor = interactor
        viewController.output = presenter

        router.transitionHandler = viewController
        router.calleeOutput = presenter
        
        viewController.onWillDeallocate {
            presenter.willDeinit()
        }

        
        presenter.configure(with: config)
        
    }

    func create(with config: RootModuleInputConfig) -> UIViewController {
        let viewController = RootViewController(rootView: RootRootView())
        viewController.rootView.delegate = viewController
        
        configureModuleForViewInput(viewInput: viewController, with: config)
        
        return viewController
    }

    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler {
        return create(with: RootModuleInputConfig(services: Services()))
    }
}
