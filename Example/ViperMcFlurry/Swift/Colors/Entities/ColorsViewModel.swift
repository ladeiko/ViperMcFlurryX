import UIKit

struct ColorsViewModel {
    let attacher: ( _ toView: UIView) -> Void
    let detacher: () -> Void
}
