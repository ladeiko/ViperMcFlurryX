import UIKit

extension UIViewController: ViperModuleTransitionHandler {
    
    private static let skipOnDismissAssociation = ObjectAssociation<NSNumber>()
    private static let moduleInputAssociation = ObjectAssociation<AnyObject>()
    private static let openModuleUsingSegueKeyAssociation = ObjectAssociation<NSNumber>()
    
    // MARK: - Properties
    
    public var skipOnDismiss: Bool {
        get {
            return UIViewController.skipOnDismissAssociation[self]?.boolValue ?? false
        }
        set {
            UIViewController.skipOnDismissAssociation[self] = NSNumber(value: newValue)
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
        self.closeModulesUntil(nil, animated: animated, completion: completion)
    }
    
    public func closeTopModules(_ animated: Bool, completion: ModuleCloseCompletionBlock?) {
        self.closeModulesUntil(self, animated: animated, completion: completion)
    }
    
    public func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool) {
        self.closeModulesUntil(transitionHandler, animated: animated, completion: nil)
    }
    
    public func closeModulesUntil(_ transitionHandler: ViperModuleTransitionHandler?, animated: Bool, completion: ModuleCloseCompletionBlock?) {
        assert(transitionHandler == nil || transitionHandler is UIViewController)
        
        func skip(_ viewController: UIViewController) -> Bool {
            
            guard viewController.skipOnDismiss else {
                return false
            }
            
            self.moduleInputInterface?.moduleDidSkipOnDismiss()
            
            viewController.closeModulesUntil(transitionHandler, animated: animated, completion: completion)
            return true
        }
        
        if let parentNavigationController = self.parent as? UINavigationController {
            if skip(parentNavigationController) { return }
            if parentNavigationController.viewControllers.count > 1 {
                if let transitionHandler = transitionHandler as? UIViewController {
                    parentNavigationController.popToViewController(transitionHandler, animated: animated)
                }
                else {
                    let viewControllers = parentNavigationController.viewControllers
                    if viewControllers.last == self {
                        parentNavigationController.popViewController(animated: animated)
                    } else {
                        let index = viewControllers.firstIndex(of: self)!
                        if index > 0 {
                            parentNavigationController.popToViewController(viewControllers[index - 1], animated: animated)
                        } else {
                            parentNavigationController.closeModulesUntil(transitionHandler, animated: animated, completion: completion)
                            return
                        }
                    }
                }
                if let completion = completion {
                    if let transitionCoordinator = parentNavigationController.transitionCoordinator {
                        transitionCoordinator.animate(alongsideTransition: { _ in }, completion: { _ in completion() })
                    } else {
                        DispatchQueue.main.async {
                            completion()
                        }
                    }
                }
            } else {
                self.parent?.closeModulesUntil(transitionHandler, animated: animated, completion: completion)
            }
        } else if self.presentingViewController?.presentedViewController == self {
            if skip(self.presentingViewController!) { return }
            var topPresented = [UIViewController]()
            var current = self
            
            while let currentPresentedViewController = current.presentedViewController {
                topPresented.append(currentPresentedViewController)
                current = currentPresentedViewController
            }
            if topPresented.count == 0 {
                self.dismiss(animated: animated, completion: completion)
                return
            }
            
            var inProgress = false
            for obj in topPresented {
                if obj.isBeingPresented || obj.isBeingDismissed || obj.isMovingFromParent || obj.isMovingToParent {
                    inProgress = true
                    break
                }
            }
            if inProgress {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1/60) {
                    self.closeModulesUntil(transitionHandler, animated: animated, completion: completion)
                }
                return
            }
            topPresented.last?.dismiss(animated: animated) {
                self.closeModulesUntil(transitionHandler, animated: animated, completion: completion)
            }
        } else if self.parent != nil {
            if skip(self.parent!) { return }
            self.willMove(toParent: nil)
            if animated {
                UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration), delay: 0,
                               options: .beginFromCurrentState,
                               animations: { self.view.alpha = 0 },
                               completion: { _ in
                                self.view.removeFromSuperview()
                                self.removeFromParent()
                                if let completion = completion { completion() }
                })
            } else {
                self.view.removeFromSuperview()
                self.removeFromParent()
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        } else {
            fatalError("not applicable")
        }
        
    }
    
    
    public func parentTransitionHandler() -> ViperModuleTransitionHandler? {
        if let parentNavigationController = self.parent as? UINavigationController {
            if parentNavigationController.viewControllers.count == 1 {
                return nil
            }
            
            if let currentIndexInNavigationStack = parentNavigationController.viewControllers.firstIndex(of: self) {
                if currentIndexInNavigationStack == 0 || currentIndexInNavigationStack == NSNotFound {
                    return nil
                }
                
                let candidate = parentNavigationController.viewControllers[currentIndexInNavigationStack - 1]
                return candidate
            }
            return nil
        } else if self.presentingViewController?.presentedViewController == self {
            guard let candidate = self.presentingViewController else { return nil }
            return candidate
        } else {
            guard let candidate = self.parent else { return nil }
            return candidate
        }
    }
    
    // MARK - Swizzled methods
    func swizzlePrepareForSegue() {
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
    
    @objc func swizzledPrepare(for segue: UIStoryboardSegue, sender: Any?) {
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
}
