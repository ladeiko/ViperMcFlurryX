import Foundation

@MainActor
public protocol ViperModuleViewControllerDismisser: AnyObject {
    func viperModuleViewControllerDismiss(animated: Bool, _ completion: (() -> Void)?)
}
