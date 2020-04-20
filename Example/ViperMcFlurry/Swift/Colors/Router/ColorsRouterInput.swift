import Foundation
import UIKit
import ViperMcFlurryX_Swift

protocol ColorsRouterInput  {
    func createColorPreviewEmbeddableModule(withColor color: UIColor) -> EmbeddableModule<ColorPreviewModuleInput>
}
