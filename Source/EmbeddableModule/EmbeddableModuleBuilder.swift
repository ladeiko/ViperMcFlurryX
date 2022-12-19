import Foundation
import ViperMcFlurryX_Swift

public enum EmbeddableModuleBuilderError: Error {
    case transitionHandlerIsNull
    case moduleFactoryIsNull
    case transitionHanderOpenModuleFailed
}

@MainActor
public class EmbeddableModuleBuilder<T> {
    public typealias ModuleConfigurationClosure = (_ moduleInput: T) -> ViperModuleOutput?
    
    public var transitionHandler: ViperModuleTransitionHandler?
    public var moduleFactory: ViperModuleFactory?
    
    public init() {
    }
    
    /**
     Initializer
     
     let builder = EmbeddableModuleBuilder<SomeModuleInput>(transitionHandler: transitionHandler, moduleFactory: SomeModuleConfigurator())
     
     or
     
     let builder = EmbeddableModuleBuilder<SomeModuleInput>()
     builder.transitionHandler = self.transitionHandler
     builder.moduleFactory = GalleryGroupsModuleConfigurator()
     
     - Parameter transitionHandler: source router transition handler
     - Parameter moduleFactory: Instance of ModuleConfigurator, which implement protocol ViperModuleFactory
     - Returns: A new `EmbeddableModule`
     */
    public init(transitionHandler: ViperModuleTransitionHandler, moduleFactory: ViperModuleFactory) {
        self.transitionHandler = transitionHandler
        self.moduleFactory = moduleFactory
    }
    
    
    /**
     Build a new EmbeddableModule
     
     let embeddableModule = try! builder.build { (moduleInput) -> ViperModuleOutput? in
        moduleInput.configure(using: services)
        return self.calleeOutput
     }
     
     - Parameter moduleConfigurator: The closure that configure a new module
     - Returns: A new `EmbeddableModule`
     */
    public func build(withConfigurationBlock moduleConfigurator: @escaping ModuleConfigurationClosure) throws -> EmbeddableModule<T> {
        guard let transitionHandler = self.transitionHandler else { throw EmbeddableModuleBuilderError.transitionHandlerIsNull }
        guard let moduleFactory = self.moduleFactory else { throw EmbeddableModuleBuilderError.moduleFactoryIsNull }
        
        var sourceViewController: UIViewController?
        var destinationViewController: UIViewController?
        var module: T?

        transitionHandler.openModuleUsingFactory(moduleFactory) { (sourceModuleTransitionHandler, destinationModuleTransitionHandler) in
            sourceViewController = (sourceModuleTransitionHandler as! UIViewController)
            destinationViewController = (destinationModuleTransitionHandler as! UIViewController)
        }.thenChainUsingBlock { moduleInput -> ViperModuleOutput? in
            guard let moduleInput = moduleInput as? T else { return nil }
            module = moduleInput
            return moduleConfigurator(moduleInput)
        }
        
        guard let sourceVC = sourceViewController, let destinationVC = destinationViewController,
            let resultModule = module else {
                throw EmbeddableModuleBuilderError.transitionHanderOpenModuleFailed
        }
        
        let attacher = createAttacher(sourceViewController: sourceVC, destinationViewController: destinationVC)
        let detacher = createDetacher(destinationViewController: destinationVC)
        return EmbeddableModule<T>(module: resultModule, attacher: attacher, detacher: detacher)
    }
    
    private func createAttacher(sourceViewController: UIViewController,
                                      destinationViewController: UIViewController) -> EmbeddableModuleAttacher {
        // Source module hold the Attacher. Attacher hold the UIViewController of source module.
        // And for true deallocate SourceViewController and his Module we need to use 'weak' reference for sourceViewController in Attacher block.
        return { [weak sourceViewController] view in
            assert(sourceViewController != nil)
            assert(!destinationViewController.isViewLoaded || (destinationViewController.view.superview == nil))
            guard let sourceViewController = sourceViewController else { return }

            sourceViewController.addChild(destinationViewController)
            destinationViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            destinationViewController.view.frame = view.bounds
            destinationViewController.beginAppearanceTransition(true, animated: false)
            view.addSubview(destinationViewController.view)
            destinationViewController.endAppearanceTransition()
            destinationViewController.didMove(toParent: sourceViewController)
        }
    }
    
    private func createDetacher(destinationViewController: UIViewController) -> EmbeddableModuleDetacher {
        return { [weak destinationViewController] in
            assert(destinationViewController != nil)
            guard let destinationViewController = destinationViewController else { return }
            assert(destinationViewController.isViewLoaded && (destinationViewController.view.superview != nil))

            destinationViewController.willMove(toParent: nil)
            destinationViewController.beginAppearanceTransition(false, animated: false)
            destinationViewController.view.removeFromSuperview()
            destinationViewController.endAppearanceTransition()
            destinationViewController.removeFromParent()
        }
    }
    
}
