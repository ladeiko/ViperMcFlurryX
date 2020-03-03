//
//  RootRouter.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import ViperMcFlurryX_Swift

class RootRouter: RootRouterInput {

    // MARK: - VIPER Vars

    weak var calleeOutput: (ViperModuleOutput /* Add supported protocols here, e.g: & AnotherModuleOutput */)!
    weak var transitionHandler: ViperModuleTransitionHandler!

    // MARK: - Vars
    // TODO: Place your code here

    // MARK: - RootRouterInput

    func dismiss() {
        transitionHandler.closeCurrentModule(true)
    }

    /* // Example
    func showSomeModule() {
        transitionHandler.openModule!(usingFactory: SomeModuleConfigurator()) { (sourceModuleTransitionHandler, destinationModuleTransitionHandler) in

            let sourceViewController = sourceModuleTransitionHandler as! UIViewController
            let destinationViewController = destinationModuleTransitionHandler as! UIViewController

            sourceViewController.present(destinationViewController, animated: true, completion: nil)

        }.thenChain { (moduleInput) -> ViperModuleOutput? in
            (moduleInput as! SomeModuleInput).configure()
            return nil // or self.calleeOutput
        }
    }
    */

    // MARK: - Helpers
    // TODO: Place your code here

}
