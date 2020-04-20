import ViperMcFlurryX_Swift

class ColorPreviewModuleConfigurator: ViperModuleFactory {

    func configureModuleForViewInput<UIViewController>(viewInput: UIViewController) {
         if let viewController = viewInput as? ColorPreviewViewController {
            configure(viewController: viewController)
         }
     }

    private func configure(viewController: ColorPreviewViewController) {

        guard viewController.output == nil else { // prevent double configuration
            return
        }
        let presenter = ColorPreviewPresenter()
        presenter.view = viewController

        viewController.output = presenter
        viewController.moduleInputInterface = presenter
    }

    func create() -> UIViewController {
        let viewController = UIStoryboard(name: "ColorPreview", bundle: .main).instantiateInitialViewController() as! ColorPreviewViewController
        configureModuleForViewInput(viewInput: viewController)
        return viewController
    }

    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler {
        return create()
    }
}
