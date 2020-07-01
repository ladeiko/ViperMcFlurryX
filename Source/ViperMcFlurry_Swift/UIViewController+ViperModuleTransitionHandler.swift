import UIKit

fileprivate func makeObjCBLock(_ block: @escaping (() -> Void)) -> @convention(block) () -> () {
    return {
        block()
    }
}

extension UIViewController: ViperModuleTransitionHandler {

    private static let moduleInputAssociation = ObjectAssociation<AnyObject>()
    private static let openModuleUsingSegueKeyAssociation = ObjectAssociation<NSNumber>()
    
    // MARK: - Properties
    
    @nonobjc public var skipOnDismiss: Bool {
        get {
            return ((perform(NSSelectorFromString("swift_bridge_skipOnDismiss")) as? NSNumber) ?? NSNumber(booleanLiteral: false)).boolValue
        }
        set {
            perform(NSSelectorFromString("swift_bridge_setSkipOnDismiss:"), with: NSNumber(booleanLiteral: newValue))
        }
    }

    @nonobjc public var moduleIdentifier: String {
        get {
            return perform(NSSelectorFromString("moduleIdentifier")) as? String ?? ""
        }
        set {
            perform(NSSelectorFromString("setModuleIdentifier:"), with: newValue)
        }
    }

    public var moduleInput: ViperModuleInput? {
        get {
            return moduleInputInterface
        }
        set {
            moduleInputInterface = newValue
        }
    }

    public var moduleInputInterface: ViperModuleInput? {
        get {
            if let moduleInput = UIViewController.moduleInputAssociation[self] as? ViperModuleInput {
                return moduleInput
            }
            let reflection = Mirror(reflecting: self)
            if let traditionalViperViewOutput = self.findValue(for: "output", in: reflection) as? ViperModuleInput {
                return traditionalViperViewOutput
            }
            return nil
        }
        set {
            UIViewController.moduleInputAssociation[self] = newValue
        }
    }

    // MARK - Navigation

    public func performSegue(_ segueIdentifier: String) {
        swizzlePrepareForSegue()
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: segueIdentifier, sender: nil)
        }
    }
    
    public func openModuleUsingSegue(_ segueIdentifier: String) -> ViperOpenModulePromise {
        swizzlePrepareForSegue()
        let openModulePromise = ViperOpenModulePromise()
        
        UIViewController.openModuleUsingSegueKeyAssociation[self] = nil
        
        let perform = {
            if UIViewController.openModuleUsingSegueKeyAssociation[self] == nil {
                UIViewController.openModuleUsingSegueKeyAssociation[self] = NSNumber(booleanLiteral: true)
                self.performSegue(withIdentifier: segueIdentifier, sender: openModulePromise)
            }
        }
        
        
        //
        // defined this to try execute segue if thenChainUsingBlock was called just after current
        // openModuleUsingSegue call (when you should call some input method of module):
        //  [[self.transitionHandler openModuleUsingSegue:SegueIdentifier]
        //        thenChainUsingBlock:^id<ViperModuleOutput>(id<SomeModuleInput> moduleInput) {
        //            [moduleInput moduleConfigurationMethod];
        //            return nil;
        //  }];
        //  NOTE: In this case segue will be called in synchronous manner
        //
        openModulePromise.postChainActionBlock = {
            perform()
        }
        
        //
        // Also try to call segue if postChainActionBlock was not called in current runloop cycle,
        // for example, thenChainUsingBlock was not called just after openModuleUsingSegue:
        //
        //  [self.transitionHandler openModuleUsingSegue:SegueIdentifier];
        //
        //  NOTE: In this case segue will be called in asynchronous manner
        //
        DispatchQueue.main.async {
            perform()
        }
        return openModulePromise
    }
    
    public func openModuleUsingFactory(_ moduleFactory: ViperModuleFactory, withTransitionBlock transitionHandler: ViperModuleTransitionHandler.ModuleTransitionBlock?) -> ViperOpenModulePromise {
        let openModulePromise = ViperOpenModulePromise()
        let destinationModuleTransitionHandler = moduleFactory.instantiateModuleTransitionHandler()
        let moduleInput = destinationModuleTransitionHandler.moduleInputInterface
        
        openModulePromise.moduleInput = moduleInput
        if let transitionHandler = transitionHandler {
            openModulePromise.postLinkActionBlock = {
                transitionHandler(self, destinationModuleTransitionHandler)
            }
        }
        return openModulePromise
    }
    
    
    public func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping (ViperModuleInput) -> ViperModuleOutput) -> EmbeddedModuleEmbedderBlock {
        return self.createEmbeddableModuleUsingFactory(moduleFactory, configurationBlock: configurationBlock, lazyAllocation: false)
    }

    public func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping (ViperModuleInput) -> ViperModuleOutput, lazyAllocation: Bool) -> EmbeddedModuleEmbedderBlock {
        
        var sourceViewController: UIViewController!
        var destinationViewController: UIViewController!
        
        let allocate = {
            
            precondition(sourceViewController == nil)
            precondition(destinationViewController == nil)
            
            self.openModuleUsingFactory(moduleFactory) { (sourceModuleTransitionHandler, destinationModuleTransitionHandler) in
                sourceViewController = sourceModuleTransitionHandler as! UIViewController
                destinationViewController = destinationModuleTransitionHandler as! UIViewController
            }.thenChainUsingBlock { (moduleInput) -> ViperModuleOutput? in
                return configurationBlock(moduleInput)
            }
            
            assert(sourceViewController != nil, "code above should be called synchronously")
            assert(destinationViewController != nil, "code above should be called synchronously")
        };
        
        let embedder: EmbeddedModuleEmbedderBlock  = { containerView -> EmbeddedModuleRemoverBlock in
            
            if lazyAllocation && destinationViewController == nil {
                allocate();
            }
            
            let remover: EmbeddedModuleRemoverBlock = { [weak destinationViewController] in
                
                guard let destinationViewController = destinationViewController else {
                    return
                }
                
                if !destinationViewController.isViewLoaded || (destinationViewController.view.superview !== containerView) {
                    return;
                }
                
                destinationViewController.willMove(toParent: nil)
                destinationViewController.view.removeFromSuperview()
                destinationViewController.removeFromParent()
            };
            
            let setupConstraints = { [weak destinationViewController] in
                
                guard let destinationViewController = destinationViewController else {
                    return
                }
                
                let embeddedView = destinationViewController.view
                embeddedView!.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[embeddedView]-0-|",
                                                                            options: [],
                                                                            metrics: nil,
                                                                            views: ["embeddedView" : embeddedView]))
                
                containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[embeddedView]-0-|",
                                                                            options: [],
                                                                            metrics: nil,
                                                                            views: ["embeddedView" : embeddedView]))
            };
            
            if (destinationViewController.isViewLoaded && destinationViewController.view.superview != nil) {
                
                if destinationViewController.parent === sourceViewController { // parent controller is the same
                    
                    if destinationViewController.view.superview === containerView { // and view is the same
                        return remover
                    }
                    
                    // Does not need 'removeFromSuperview' because
                    // it is automatically called whill addSubview
                    containerView.addSubview(destinationViewController.view)
                    setupConstraints()
                    return remover
                }
                else {
                    destinationViewController?.willMove(toParent: nil)
                    destinationViewController.removeFromParent()
                }
            }
            
            sourceViewController.addChild(destinationViewController)
            containerView.addSubview(destinationViewController.view)
            destinationViewController.didMove(toParent: sourceViewController)
            setupConstraints()
            return remover
        };
        
        if !lazyAllocation {
            allocate()
        }
        
        return embedder
    }
    
    public func closeCurrentModule(_ animated: Bool) {
        self.closeCurrentModule(animated, completion: nil)
    }

    public func closeCurrentModule(_ animated: Bool, completion: ModuleCloseCompletionBlock?) {

        let info = NSMutableDictionary()
        info.setObject(NSNumber(booleanLiteral: animated), forKey: "animated" as NSString)

        if let completion = completion {
            info.setObject(makeObjCBLock { completion() }, forKey: "completion" as NSString)
        }

        perform(NSSelectorFromString("swift_bridge_closeCurrentModule:"), with: info)
    }
    
    public func closeTopModules(_ animated: Bool, completion: ModuleCloseCompletionBlock?) {

        let info = NSMutableDictionary()
        info.setObject(NSNumber(booleanLiteral: animated), forKey: "animated" as NSString)

        if let completion = completion {
            info.setObject(makeObjCBLock { completion() }, forKey: "completion" as NSString)
        }

        perform(NSSelectorFromString("swift_bridge_closeTopModules:"), with: info)
    }
    
    public func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool) {
        self.closeModulesUntil(transitionHandler, animated: animated, completion: nil)
    }
    
    public func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool, completion: ModuleCloseCompletionBlock?) {

        let info = NSMutableDictionary()
        if let transitionHandler = transitionHandler {
            info.setObject(transitionHandler, forKey: "transitionHandler" as NSString)
        }

        info.setObject(NSNumber(booleanLiteral: animated), forKey: "animated" as NSString)

        if let completion = completion {
            info.setObject(makeObjCBLock { completion() }, forKey: "completion" as NSString)
        }

        perform(NSSelectorFromString("swift_bridge_closeModulesUntil:"), with: info)
    }

    public func closeCurrentModuleIgnoringSkipping(_ animated: Bool, completion: ModuleCloseCompletionBlock?) {

        let info = NSMutableDictionary()
        info.setObject(NSNumber(booleanLiteral: animated), forKey: "animated" as NSString)

        if let completion = completion {
            info.setObject(makeObjCBLock { completion() }, forKey: "completion" as NSString)
        }

        perform(NSSelectorFromString("swift_bridge_closeCurrentModuleIgnoringSkipping:"), with: info)
    }

    public func closeToModuleWithIdentifier(_ moduleIdentifier: String, animated:Bool, completion: ModuleCloseCompletionBlock?) {

        let info = NSMutableDictionary()
        info.setObject(moduleIdentifier as NSString, forKey: "moduleIdentifier" as NSString)
        info.setObject(NSNumber(booleanLiteral: animated), forKey: "animated" as NSString)

        if let completion = completion {
            info.setObject(makeObjCBLock { completion() }, forKey: "completion" as NSString)
        }

        perform(NSSelectorFromString("swift_bridge_closeToModuleWithIdentifier:"), with: info)
    }

    public func closeToModuleWithIdentifier(_ moduleIdentifier: String, animated: Bool) {
        closeToModuleWithIdentifier(moduleIdentifier, animated:animated, completion: nil)
    }
    
    public func previousTransitionHandler() -> ViperModuleTransitionHandler? {
        return perform(NSSelectorFromString("swift_bridge_previousTransitionHandler"), with: nil) as? ViperModuleTransitionHandler
    }
    
    // MARK - Swizzled methods

    private func swizzlePrepareForSegue() {
        DispatchQueue.once(token: "viperinfrastructure.swizzle.prepareForSegue") {
            let originalSelector = #selector(UIViewController.prepare(for: sender:))
            let swizzledSelector = #selector(UIViewController.swizzledPrepare(for: sender:))
            
            let instanceClass = UIViewController.self
            let originalMethod = class_getInstanceMethod(instanceClass, originalSelector)
            let swizzledMethod = class_getInstanceMethod(instanceClass, swizzledSelector)
            
            let didAddMethod = class_addMethod(instanceClass, originalSelector,
                                               method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
            
            if didAddMethod {
                class_replaceMethod(instanceClass, swizzledSelector,
                                    method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
            } else {
                method_exchangeImplementations(originalMethod!, swizzledMethod!)
            }
        }
    }
    
    @objc
    private func swizzledPrepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.swizzledPrepare(for: segue, sender: sender)
        
        guard let openModulePromise = sender as? ViperOpenModulePromise else { return }
        
        var destinationViewController: UIViewController? = segue.destination
        if let navigationViewController = segue.destination as? UINavigationController {
            destinationViewController = navigationViewController.topViewController
        }
        
        let targetModuleTransitionHandler: ViperModuleTransitionHandler? = destinationViewController
        let moduleInput = targetModuleTransitionHandler?.moduleInputInterface
        
        openModulePromise.moduleInput = moduleInput
    }

    @objc
    private func swift_bridge_moduleDidSkipOnDismiss() {
        moduleInputInterface?.moduleDidSkipOnDismiss()
    }

    private func findValue(for propertyName: String, in mirror: Mirror) -> Any? {
        for property in mirror.children {
            if property.label! == propertyName {
                return property.value
            }
        }

        if let superclassMirror = mirror.superclassMirror {
            return findValue(for: propertyName, in: superclassMirror)
        }

        return nil
    }
}
