//
//  RootInteractor.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

class RootInteractor: RootInteractorInput {

    // MARK: - VIPER Vars

    weak var output: RootInteractorOutput!

    // MARK: - Vars
    
    private final var config: RootModuleInputConfig!

    // MARK: - RootInteractorInput
    
    func configure(with config: RootModuleInputConfig) {
        assert(self.config == nil)
        self.config = config
    }
    
    func deinitialize() {
        // TODO: Place your code here
    }

    // MARK: - Helpers
    // TODO: Place your code here
}
