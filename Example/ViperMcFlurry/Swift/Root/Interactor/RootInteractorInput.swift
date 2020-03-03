//
//  RootInteractorInput.swift
//  Demo
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2020-present Sergey Ladeiko. All rights reserved.
//

import Foundation

protocol RootInteractorInput: Interactor {
    func configure(with config: RootModuleInputConfig)
    func deinitialize()
}
