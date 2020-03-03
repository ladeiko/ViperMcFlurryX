import UIKit

public protocol ViperModuleTransitionHandler: class {
    
    typealias ModuleTransitionBlock = (_ sourceModuleTransitionHandler: ViperModuleTransitionHandler, _ destinationModuleTransitionHandler: ViperModuleTransitionHandler) -> Void
    typealias ModuleCloseCompletionBlock = (() -> Void)

    typealias EmbeddedModuleRemoverBlock = (() -> Void)
    typealias EmbeddedModuleEmbedderBlock = ((_ containerView: UIView) -> EmbeddedModuleRemoverBlock)
    typealias EmbeddedModuleConfigurationBlock = ((_ moduleInput: ViperModuleInput) -> ViperModuleOutput)

    var moduleInput: ViperModuleInput? { get set }

    var skipOnDismiss: Bool { get set }

    // Performs segue without any actions, useful for unwind segues
    func performSegue(_ segueIdentifier: String)
    
    // Method opens module using segue
    func openModuleUsingSegue(_ segueIdentifier: String) -> ViperOpenModulePromise
    
    // Method opens module using module factory
    func openModuleUsingFactory(_ moduleFactory: ViperModuleFactory, withTransitionBlock: ModuleTransitionBlock?) -> ViperOpenModulePromise


    // Method returns block accepting sinlge container view as parameter,
    // if block is called then module is embedded to the specified view,
    // andblock returns another block which can be used to detach embedded
    // module from previous container view. 'lazyAllocation' defines, when
    // embedded module is created and configured: if lazyAllocation is true,
    // then module is create and configured at the moment of attachement,
    // if false, then at the moment when this function is called.
    // Example of usage you can see in SwiftyViperMcFlurryStoryboardComplexTableViewCacheTracker template
    // at https://github.com/ladeiko/SwiftyViperTemplates
    //
    // NOTE: Detaching block will remove from superview only if superview is the same it was while attaching!
    func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping EmbeddedModuleConfigurationBlock, lazyAllocation: Bool) -> EmbeddedModuleEmbedderBlock
    // Shorter version of 'createEmbeddableModuleUsingFactory' where lazyAllocation is false
    func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping EmbeddedModuleConfigurationBlock) -> EmbeddedModuleEmbedderBlock

    // Method removes/closes module
    func closeCurrentModule(_ animated: Bool)
    // Method removes/closes module
    func closeCurrentModule(_ animated: Bool, completion: ModuleCloseCompletionBlock?)
    // Method removes/closes module. Uses self as transitionHandler in 'closeModulesUntil'
    func closeTopModules(_ animated: Bool, completion: ModuleCloseCompletionBlock?)
    // Method removes/closes module until specified transitionHandler becomes top
    func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool)
    func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool, completion: ModuleCloseCompletionBlock?)

    // Returns parent module if possible
    func parentTransitionHandler() -> ViperModuleTransitionHandler?
}
