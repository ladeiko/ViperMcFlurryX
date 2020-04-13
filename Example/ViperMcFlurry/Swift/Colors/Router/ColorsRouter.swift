import Foundation
import ViperMcFlurryX_Swift

class ColorsRouter: ColorsRouterInput {
    weak var calleeOutput: (ViperModuleOutput /* Add supported protocols here, e.g: & AnotherModuleOutput */)!
    weak var transitionHandler: ViperModuleTransitionHandler!

    func createColorPreviewEmbeddableModule(withColor color: UIColor) -> EmbeddableModule<ColorPreviewModuleInput> {
        let builder = EmbeddableModuleBuilder<ColorPreviewModuleInput>(transitionHandler: transitionHandler, moduleFactory: ColorPreviewModuleConfigurator())
        return try! builder.build { colorPreviewModule -> ViperModuleOutput? in
            colorPreviewModule.configure(withColor: color)
            return self.calleeOutput
        }
    }
}
