import Foundation
import ViperMcFlurryX_Swift

protocol ColorsModuleInput: ViperModuleInput {
    func configure(withColors colors: [UIColor])
}
