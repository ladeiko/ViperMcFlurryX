import UIKit

class ColorPreviewViewController: UIViewController, ColorPreviewViewInput {
    @IBOutlet weak var colorView: UIView!

    var output: ColorPreviewViewOutput!

    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewIsReady()
    }

    func setColor(_ color: UIColor) {
        colorView.backgroundColor = color
    }
}
