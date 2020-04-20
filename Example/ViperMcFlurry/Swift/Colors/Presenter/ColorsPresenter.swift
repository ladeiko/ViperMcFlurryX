import Foundation
import ViperMcFlurryX_Swift

class ColorsPresenter: ColorsModuleInput, ColorsViewOutput, ViperModuleOutput {
    weak var view: ColorsViewInput!
    var interactor: ColorsInteractorInput!
    var router: ColorsRouterInput!

    var colors = [UIColor]()
    var cacheModules = [UIColor: EmbeddableModule<ColorPreviewModuleInput>]()

    func configure(withColors colors: [UIColor]) {
        self.colors = colors
    }

    // MARK: - ViewOutput
    func viewIsReady() {
        let viewModels = adopt(colors: colors)
        view.setItems(viewModels)
    }

    private func adopt(colors: [UIColor]) -> [ColorsViewModel] {
        colors.map { (color) -> ColorsViewModel in
            if cacheModules[color] == nil {
                cacheModules[color] = router.createColorPreviewEmbeddableModule(withColor: color)
            }
            let module = cacheModules[color]!
            return ColorsViewModel(attacher: module.attacher, detacher: module.detacher)
        }
    }
}
