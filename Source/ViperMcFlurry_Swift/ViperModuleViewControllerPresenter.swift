import UIKit

public protocol ViperModuleViewControllerPresenter: AnyObject {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool
    func viperModuleViewControllerPresent(in viewController: UIViewController)
}

extension ViperModuleViewControllerPresenter {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool {
        return true
    }
}
