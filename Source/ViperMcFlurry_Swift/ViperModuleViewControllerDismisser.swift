import Foundation

protocol ViperModuleViewControllerDismisser: class {
    func viperModuleViewControllerDismiss(animated: Bool, _ completion: (() -> Void)?)
}
