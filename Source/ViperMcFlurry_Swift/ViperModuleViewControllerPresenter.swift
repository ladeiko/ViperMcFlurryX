import UIKit

@MainActor
public protocol ViperModuleViewControllerPresenter: AnyObject {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool
    func viperModuleViewControllerPresent(in viewController: UIViewController)
}

@MainActor
extension ViperModuleViewControllerPresenter {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool {
        return true
    }
}
