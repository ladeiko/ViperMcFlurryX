import Foundation

public protocol ViperModuleViewControllerDismisser: AnyObject {
    func viperModuleViewControllerDismiss(animated: Bool, _ completion: (() -> Void)?)
}
