import Foundation
import ViperMcFlurryX_Swift

class ColorsModuleConfigurator: ViperModuleFactory {

    func configureModuleForViewInput<UIViewController>(viewInput: UIViewController) {
         if let viewController = viewInput as? ColorsViewController {
             configure(viewController: viewController)
         }
     }

    private func configure(viewController: ColorsViewController) {

        guard viewController.output == nil else { // prevent double configuration
            return
        }

        let router = ColorsRouter()

        let presenter = ColorsPresenter()
        presenter.view = viewController
        presenter.router = router

        let interactor = ColorsInteractor()

        presenter.interactor = interactor
        viewController.output = presenter
        viewController.moduleInputInterface = presenter
        
        router.transitionHandler = viewController
        router.calleeOutput = presenter
    }

    func create() -> UIViewController {
        let viewController = UIStoryboard(name: "Colors", bundle: .main).instantiateInitialViewController() as! ColorsViewController
        configureModuleForViewInput(viewInput: viewController)
        return viewController
    }

    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler {
        return create()
    }
}
