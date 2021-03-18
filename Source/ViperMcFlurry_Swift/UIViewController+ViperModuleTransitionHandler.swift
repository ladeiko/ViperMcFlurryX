import UIKit

fileprivate func makeObjCBLock(_ block: @escaping (() -> Void)) -> @convention(block) () -> () {
    return {
        block()
    }
}

fileprivate func makeObjCBLock2(_ block: @escaping ((_ animated: Bool, _ completion: (() -> Void)?) -> Void)) -> @convention(block) (_ animated: Bool, _ completion: (() -> Void)?) -> () {
    return { animated, completion in
        block(animated, completion)
    }
}

extension UIViewController: ViperModuleTransitionHandler {

    private static let moduleInputAssociation = ObjectAssociation<AnyObject>()
    private static let openModuleUsingSegueKeyAssociation = ObjectAssociation<NSNumber>()

    // MARK: - Properties

    @nonobjc public var skipOnDismiss: Bool {
        get {

            if let unmanaged = perform(NSSelectorFromString("swift_bridge_skipOnDismiss")),
                let nsBool = unmanaged.takeUnretainedValue() as? NSNumber {
                return nsBool.boolValue
            }

            return false
        }
        set {
            perform(NSSelectorFromString("swift_bridge_setSkipOnDismiss:"), with: NSNumber(booleanLiteral: newValue))
        }
    }

    @nonobjc public var moduleIdentifier: String {
        get {

            if let unmanaged = perform(NSSelectorFromString("moduleIdentifier")),
                let nsString = unmanaged.takeUnretainedValue() as? NSString {
                return nsString as String
            }

            return ""
        }
        set {
            perform(NSSelectorFromString("setModuleIdentifier:"), with: newValue as NSString)
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

    public func embedModuleUsing(_ moduleFactory: ViperModuleFactory, into containerIdentifier: String) -> ViperOpenModulePromise {
        let openModulePromise = ViperOpenModulePromise()
        let destinationModuleTransitionHandler = moduleFactory.instantiateModuleTransitionHandler()
        let moduleInput = destinationModuleTransitionHandler.moduleInputInterface

        var done = false
        let perform = {

            guard !done  else {
                return
            }

            done = true

            guard let containerProvider = self as? EmbedSegueContainerViewProvider else {
                fatalError()
            }

            guard let containerView = containerProvider.containerViewForSegue(containerIdentifier) else {
                fatalError()
            }

            let destinationController = destinationModuleTransitionHandler as! UIViewController
            let moduleView = destinationController.view!

            self.addChild(destinationController)
            destinationController.beginAppearanceTransition(true, animated: false)
            moduleView.frame = self.view.bounds
            containerView.addSubview(moduleView)
            destinationController.endAppearanceTransition()
            destinationController.didMove(toParent: self)

            moduleView.translatesAutoresizingMaskIntoConstraints = false

            let top = NSLayoutConstraint(item: moduleView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0)
            let bot = NSLayoutConstraint(item: moduleView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: moduleView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: moduleView, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1, constant: 0)

            containerView.addConstraints([top, bot, left, right])
        }

        openModulePromise.moduleInput = moduleInput
        openModulePromise.postLinkActionBlock = {
            perform()
        }

        DispatchQueue.main.async { // last chance
            perform()
        }

        return openModulePromise
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

    public func openModuleUsingFactory(_ moduleFactory: ViperModuleFactory, withTransitionBlock transitionHandler: ModuleTransitionBlock?) -> ViperOpenModulePromise {
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
    
    public func openModuleUsingFactory(_ moduleFactory: ViperModuleFactory) -> ViperOpenModulePromise {
        let openModulePromise = ViperOpenModulePromise()
        let destinationModuleTransitionHandler = moduleFactory.instantiateModuleTransitionHandler()
        let moduleInput = destinationModuleTransitionHandler.moduleInputInterface

        openModulePromise.moduleInput = moduleInput
        if let presenter = destinationModuleTransitionHandler as? ViperModuleViewControllerPresenter,
            presenter.viperModuleViewControllerShouldPresent(in: self) {
            openModulePromise.postLinkActionBlock = {
                presenter.viperModuleViewControllerPresent(in: self)
            }
        }
        return openModulePromise
    }


    public func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping EmbeddedModuleConfigurationBlock) -> EmbeddedModuleEmbedderBlock {
        return self.createEmbeddableModuleUsingFactory(moduleFactory, configurationBlock: configurationBlock, lazyAllocation: false)
    }

    public func createEmbeddableModuleUsingFactory(_ moduleFactory: ViperModuleFactory, configurationBlock: @escaping EmbeddedModuleConfigurationBlock, lazyAllocation: Bool) -> EmbeddedModuleEmbedderBlock {

        weak var sourceViewController: UIViewController! = self
        var destinationViewController: UIViewController!

        let allocate = {

            precondition(sourceViewController != nil)
            precondition(destinationViewController == nil)

            sourceViewController.openModuleUsingFactory(moduleFactory) { (sourceModuleTransitionHandler, destinationModuleTransitionHandler) in
                //sourceViewController = sourceModuleTransitionHandler as! UIViewController
                destinationViewController = destinationModuleTransitionHandler as! UIViewController
            }.thenChainUsingBlock { (moduleInput) -> ViperModuleOutput? in
                return configurationBlock(moduleInput)
            }

            assert(sourceViewController != nil, "code above should be called synchronously")
            assert(destinationViewController != nil, "code above should be called synchronously")
        };

        let embedder: EmbeddedModuleEmbedderBlock  = { [weak sourceViewController] containerView -> EmbeddedModuleRemoverBlock in

            if destinationViewController == nil {
                allocate();
            }

            let remover: EmbeddedModuleRemoverBlock = { [weak sourceViewController] in

                guard let strongDestinationViewController = destinationViewController else {
                    return
                }

                if !strongDestinationViewController.isViewLoaded || (strongDestinationViewController.view.superview !== containerView) {
                    return;
                }

                strongDestinationViewController.willMove(toParent: nil)
                strongDestinationViewController.beginAppearanceTransition(false, animated: false)
                strongDestinationViewController.view.removeFromSuperview()
                strongDestinationViewController.endAppearanceTransition()
                strongDestinationViewController.removeFromParent()
            };

            let setupConstraints = { [weak sourceViewController] in

                guard let strongDestinationViewController = destinationViewController else {
                    return
                }

                let embeddedView = strongDestinationViewController.view
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

            if destinationViewController.isViewLoaded && destinationViewController.view.superview != nil {

                if destinationViewController!.parent === sourceViewController { // parent controller is the same

                    if destinationViewController!.view.superview === containerView { // and view is the same
                        return remover
                    }

                    // Does not need 'removeFromSuperview' because
                    // it is automatically called whill addSubview
                    containerView.addSubview(destinationViewController!.view)
                    setupConstraints()
                    return remover
                }
                else {
                    destinationViewController!.willMove(toParent: nil)
                    destinationViewController!.beginAppearanceTransition(false, animated: false)
                    destinationViewController!.view.removeFromSuperview()
                    destinationViewController!.endAppearanceTransition()
                    destinationViewController!.removeFromParent()
                }
            }

            sourceViewController!.addChild(destinationViewController)
            destinationViewController.beginAppearanceTransition(true, animated: false)
            containerView.addSubview(destinationViewController!.view)
            destinationViewController.endAppearanceTransition()
            destinationViewController!.didMove(toParent: sourceViewController)
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

extension UIViewController {
    
    @objc(hasViperModuleDismisser)
    private func hasViperModuleDismisser() -> NSNumber {
        return NSNumber(value: self as? ViperModuleViewControllerDismisser != nil)
    }
    
    @objc(vipermoduleDismisser)
    private func vipermoduleDismisser() -> @convention(block) (_ animated: Bool, _ completion: (() -> Void)?) -> () {
        guard let dismisser = self as? ViperModuleViewControllerDismisser else {
            fatalError()
        }
        return makeObjCBLock2 { [weak dismisser] animated, completion in
            dismisser?.viperModuleViewControllerDismiss(animated: animated, completion)
        }
    }
    
}
