import UIKit

protocol ViperModuleViewControllerPresenter: class {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool
    func viperModuleViewControllerPresent(in viewController: UIViewController)
}

extension ViperModuleViewControllerPresenter {
    func viperModuleViewControllerShouldPresent(in viewController: UIViewController) -> Bool {
        return true
    }
}
