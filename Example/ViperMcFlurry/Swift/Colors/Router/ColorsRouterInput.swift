import Foundation
import UIKit
import ViperMcFlurryX_Swift

protocol ColorsRouterInput: Router  {
    func createColorPreviewEmbeddableModule(withColor color: UIColor) -> EmbeddableModule<ColorPreviewModuleInput>
}
