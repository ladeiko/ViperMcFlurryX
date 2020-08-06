//
//  ViperMcFlurry_Swift_EmbeddableTests.swift
//  ViperMcFlurry_ExampleTests
//
//  Created by Sergey Ladeiko on 8/5/20.
//  Copyright © 2020 Egor Tolstoy. All rights reserved.
//

import Foundation
import XCTest
import ViperMcFlurryX_Swift

fileprivate protocol ViewInput: class {
    func embed(_ embedder: EmbeddableEmbedBlock)
    func remove()
}
fileprivate protocol ViewOutput: class {
    func viewIsReady()
}
fileprivate protocol RouterInput: class {
    func embed() -> EmbeddableEmbedBlock
}
fileprivate protocol ModuleInput: class {}
fileprivate protocol EmbeddedModuleInput: class {
    func configure()
    func didBecomeVisible()
    func didBecomeInvisible()
}
fileprivate protocol ModuleOutput: class {}
fileprivate protocol EmbeddedModuleOutput: class {
    func iamCreated(_ input: EmbeddedModuleInput)
}

fileprivate protocol InteractorInput: class {}
fileprivate protocol InteractorOutput: class {}


fileprivate typealias EmbeddableRemoveBlock = () -> Void
fileprivate typealias EmbeddableEmbedBlock = (_ containerView: UIView) -> EmbeddableRemoveBlock

fileprivate protocol Embeddable {
    var embed: EmbeddableEmbedBlock! { get }
}

fileprivate class Main {
    class MainViewController: UIViewController, ViewInput {

        static var count = 0

        var output: ViewOutput!
        var remover: EmbeddableRemoveBlock?

        init() {
            type(of: self).count += 1
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            output.viewIsReady()
        }

        deinit {
            type(of: self).count -= 1
        }

        func embed(_ embedder: EmbeddableEmbedBlock) {
            remover = embedder(view)
        }

        func remove() {
            remover?()
            remover = nil
        }

    }

    class MainRouter: RouterInput {
        weak var calleeOutput: ViperModuleOutput!
        weak var transitionHandler: ViperModuleTransitionHandler!

        func embed() -> EmbeddableEmbedBlock {

            weak var embeddedInput: EmbeddedModuleInput!

            let factory = Embedded.Configurator()
            let configurationBlock: EmbeddedModuleConfigurationBlock = { [weak self] (moduleInput) -> ViperModuleOutput? in
                let moduleInput = moduleInput as! EmbeddedModuleInput
                embeddedInput = moduleInput
                moduleInput.configure()
                return self?.calleeOutput
            }

            let nativeEmbedder = transitionHandler.createEmbeddableModuleUsingFactory(factory, configurationBlock: configurationBlock, lazyAllocation: false)

            // Sometimes embeddable mobule can be reattached to another containerView
            // therefore we should track number of add/remove operations
            // and call remove only when required
            var embedBalanceCounter = 0

            let embedder: EmbeddableEmbedBlock = { [weak embeddedInput] containerView in
                let nativeRemover = nativeEmbedder(containerView)
                embedBalanceCounter += 1
                if embedBalanceCounter == 1 {
                    embeddedInput?.didBecomeVisible()
                }
                let  remover: EmbeddableRemoveBlock = { [weak embeddedInput] in
                    embedBalanceCounter -= 1
                    assert(embedBalanceCounter >= 0)
                    if embedBalanceCounter == 0 {
                        let embeddedInput = embeddedInput
                        nativeRemover()
                        embeddedInput?.didBecomeInvisible()
                    }
                }
                return remover
            }

            return embedder

        }

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }
    }

    class MainInteractor: InteractorInput {
        weak var output: InteractorOutput!

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }
    }

    class MainPresenter: ViperModuleInput, ViperModuleOutput, ViewOutput, InteractorOutput, ModuleInput, EmbeddedModuleOutput {

        weak var view: ViewInput!
        var interactor: InteractorInput!
        var router: RouterInput!
        weak var output: ModuleOutput?

        weak var embedded: EmbeddedModuleInput?

        // MARK: - ViperModuleInput

        func setModuleOutput(_ moduleOutput: ViperModuleOutput) {
            output = moduleOutput as? ModuleOutput
        }

        func viewIsReady() {
            let embedded = router.embed()
            view.embed(embedded)
        }

        func remove() {
            view.remove()
        }

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }

        func iamCreated(_ input: EmbeddedModuleInput) {
            self.embedded = input
        }
    }

    class MainConfigurator:  ViperModuleFactory {


        func configureModuleForViewInput<UIViewController>(viewInput: UIViewController) {
            if let viewController = viewInput as? MainViewController {

                configure(viewController: viewController)
            }
        }

        private func configure(viewController: MainViewController) {

            guard viewController.output == nil else { // prevent double configuration
                return
            }

            let router = MainRouter()

            let presenter = MainPresenter()
            presenter.view = viewController
            presenter.router = router

            let interactor = MainInteractor()
            interactor.output = presenter

            presenter.interactor = interactor
            viewController.output = presenter
            viewController.moduleInputInterface = presenter

            router.transitionHandler = viewController
            router.calleeOutput = presenter
        }

        func create() -> MainViewController {
            let viewController = MainViewController()
            configureModuleForViewInput(viewInput: viewController)
            return viewController
        }

        // MARK: - ViperModuleFactory

        func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler {
            return create()
        }

    }
}

fileprivate class Embedded {
    class ViewController: UIViewController, ViewInput {

        static var count = 0

        var output: ViewOutput!

        override func viewDidLoad() {
            super.viewDidLoad()
            type(of: self).count += 1
            output.viewIsReady()
        }

        deinit {
            type(of: self).count -= 1
        }

        func embed(_ embedder: EmbeddableEmbedBlock) {
            fatalError()
        }

        func remove() {

        }

    }

    class Router: RouterInput {
        weak var calleeOutput: ViperModuleOutput!
        weak var transitionHandler: ViperModuleTransitionHandler!

        func embed() -> EmbeddableEmbedBlock {
            fatalError()
        }

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }
    }

    class Interactor: InteractorInput {
        weak var output: InteractorOutput!

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }
    }

    class Presenter: ViperModuleInput, ViperModuleOutput, ViewOutput, InteractorOutput, EmbeddedModuleInput {

        weak var view: ViewInput!
        var interactor: InteractorInput!
        var router: RouterInput!
        weak var output: EmbeddedModuleOutput?

        static var count = 0
        init() {
            type(of: self).count += 1
        }
        deinit {
            type(of: self).count -= 1
        }

        // MARK: - ViperModuleInput

        func setModuleOutput(_ moduleOutput: ViperModuleOutput) {
            output = moduleOutput as? EmbeddedModuleOutput
        }

        func configure() {

        }

        func viewIsReady() {
            output?.iamCreated(self)
        }

        func remove() {

        }

        var visibilityCounter = 0

        func didBecomeVisible() {
            visibilityCounter += 1
        }

        func didBecomeInvisible() {
            visibilityCounter -= 1
        }
    }

    class Configurator:  ViperModuleFactory {


        func configureModuleForViewInput<UIViewController>(viewInput: UIViewController) {
            if let viewController = viewInput as? ViewController {

                configure(viewController: viewController)
            }
        }

        private func configure(viewController: ViewController) {

            guard viewController.output == nil else { // prevent double configuration
                return
            }

            let router = Router()

            let presenter = Presenter()
            presenter.view = viewController
            presenter.router = router

            let interactor = Interactor()
            interactor.output = presenter

            presenter.interactor = interactor
            viewController.output = presenter
            viewController.moduleInputInterface = presenter

            router.transitionHandler = viewController
            router.calleeOutput = presenter
        }

        func create() -> ViewController {
            let viewController = ViewController()
            configureModuleForViewInput(viewInput: viewController)
            return viewController
        }

        // MARK: - ViperModuleFactory

        func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler {
            return create()
        }

    }
}

class ViperMcFlurry_Swift_EmbeddableTests: XCTestCase {

    func testDeallocation() {

        let done = XCTestExpectation()

        autoreleasepool {

            var mainController: Main.MainViewController! = Main.MainConfigurator().create()
            XCTAssertNil((mainController.output as! Main.MainPresenter).embedded)

            let view = mainController.view // force load

            XCTAssertNotNil((mainController.output as! Main.MainPresenter).embedded)

            XCTAssertEqual(view?.subviews.count, 1)

            let ePresenter = (mainController.output as! Main.MainPresenter).embedded as! Embedded.Presenter
            XCTAssertEqual(ePresenter.visibilityCounter, 1)

            (mainController.output as! Main.MainPresenter).remove()
            XCTAssertEqual(ePresenter.visibilityCounter, 0)

            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
                if Main.MainViewController.count == 0
                    && Main.MainPresenter.count == 0
                    && Main.MainInteractor.count == 0
                    && Main.MainRouter.count == 0
                    && Embedded.ViewController.count == 0
                    && Embedded.Presenter.count == 0
                    && Embedded.Interactor.count == 0
                    && Embedded.Router.count == 0
                {
                    timer.invalidate()
                    done.fulfill()
                }
                else {
                    print(Main.MainViewController.count,
                          Main.MainPresenter.count,
                          Main.MainInteractor.count,
                          Main.MainRouter.count,
                          Embedded.ViewController.count,
                          Embedded.Presenter.count,
                          Embedded.Interactor.count,
                          Embedded.Router.count)
                }
            })

            mainController = nil
        }

        wait(for: [done], timeout: 10)
    }
}
