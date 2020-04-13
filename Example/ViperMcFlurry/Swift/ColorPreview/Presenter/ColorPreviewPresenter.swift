import Foundation
import ViperMcFlurryX_Swift

class ColorPreviewPresenter: ColorPreviewModuleInput, ViperModuleOutput, ColorPreviewViewOutput {
    weak var view: ColorPreviewViewInput!

    var color: UIColor!

    func configure(withColor color: UIColor) {
        self.color = color
    }

    // MARK: - ViewOutput
    func viewIsReady() {
        view.setColor(color)
    }

}
