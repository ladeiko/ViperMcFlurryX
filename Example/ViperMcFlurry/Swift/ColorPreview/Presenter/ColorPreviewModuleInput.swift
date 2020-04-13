import Foundation
import ViperMcFlurryX_Swift

protocol ColorPreviewModuleInput: ViperModuleInput {
    func configure(withColor: UIColor)
}
