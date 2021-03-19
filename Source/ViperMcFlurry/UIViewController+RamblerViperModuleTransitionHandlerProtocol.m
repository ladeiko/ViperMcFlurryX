//
//  UIViewController+RamblerViperModuleTransitionHandlerProtocol.m
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import "UIViewController+RamblerViperModuleTransitionHandlerProtocol.h"
#import <objc/runtime.h>
#import "RamblerViperOpenModulePromise.h"
#import "RamblerViperModuleFactory.h"
#import "RamblerViperModuleViewControllerDismisser.h"
#import "RamblerViperModuleViewControllerPresenter.h"

static IMP originalPrepareForSegueMethodImp;
static int skipOnDismissKey = 0;
static int moduleIdentifierKey = 0;

static void swizzle(Class class, SEL originalSelector, SEL swizzledSelector) {

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }

}

@implementation UIViewController(ViperMcFlurryHelpers)

- (void)vipermcflurry_helper_waitForAnimationCompleted:(void(^)(void))completion {

    if ([self isBeingPresented] || [self isBeingDismissed] || [self isMovingFromParentViewController] || [self isMovingToParentViewController]) {
        [self performSelector:_cmd withObject:completion afterDelay:1/60 * NSEC_PER_SEC];
        return;
    }

    completion();
}

- (UIViewController* _Nullable)vipermcflurry_helper_findModuleBeforeModuleWithIdentifier:(NSString*)identifier previous:(UIViewController*)previous {

    if ([self respondsToSelector:@selector(moduleIdentifier)] && [[self moduleIdentifier] isEqualToString:identifier]) {
        return previous;
    }

    return [(UIViewController*)[self previousTransitionHandler] vipermcflurry_helper_findModuleBeforeModuleWithIdentifier:identifier previous:self];
}

- (UIViewController* _Nullable)vipermcflurry_helper_findControllerBeforeNextNotSkippableController:(NSMutableArray*)skipped {
    UIViewController* parent = [self previousTransitionHandler];
    if (parent.skipOnDismiss) {
        [skipped addObject:parent];
    }
    return parent.skipOnDismiss ? [parent vipermcflurry_helper_findControllerBeforeNextNotSkippableController:skipped] : self;
}

- (void)vipermcflurry_helper_notifyAboutSkip
{
    NSObject<RamblerViperModuleInput>* moduleInput = [self moduleInput];
    if ([moduleInput conformsToProtocol:@protocol(RamblerViperModuleInput)]
        && [moduleInput respondsToSelector:@selector(moduleDidSkipOnDismiss)])
    {
        [moduleInput performSelector:@selector(moduleDidSkipOnDismiss) withObject:nil];
    }

    if ([self respondsToSelector:@selector(swift_bridge_moduleDidSkipOnDismiss)]) {
        [self performSelector:@selector(swift_bridge_moduleDidSkipOnDismiss) withObject:nil];
    }
}

@end

@implementation UIViewController(ViperMcFlurrySwiftBridge)

- (void)swift_bridge_closeCurrentModule:(NSDictionary*)info {
    const BOOL animated = [info[@"animated"] boolValue];
    const ModuleCloseCompletionBlock completion = info[@"completion"];
    [self closeCurrentModule:animated completion:completion];
}

- (void)swift_bridge_closeModulesUntil:(NSDictionary*)info {
    id<RamblerViperModuleTransitionHandlerProtocol> transitionHandler = info[@"transitionHandler"];
    const BOOL animated = [info[@"animated"] boolValue];
    const ModuleCloseCompletionBlock completion = info[@"completion"];
    [self closeModulesUntil:transitionHandler animated:animated completion:completion];
}

- (void)swift_bridge_closeToModuleWithIdentifier:(NSDictionary*)info {
    NSString* const moduleIdentifier = info[@"moduleIdentifier"];
    const BOOL animated = [info[@"animated"] boolValue];
    const ModuleCloseCompletionBlock completion = info[@"completion"];
    [self closeToModuleWithIdentifier:moduleIdentifier animated:animated completion:completion];
}

- (void)swift_bridge_closeCurrentModuleIgnoringSkipping:(NSDictionary*)info {
    const BOOL animated = [info[@"animated"] boolValue];
    const ModuleCloseCompletionBlock completion = info[@"completion"];
    [self closeCurrentModuleIgnoringSkipping:animated completion:completion];
}

- (void)swift_bridge_closeTopModules:(NSDictionary*)info {
    const BOOL animated = [info[@"animated"] boolValue];
    const ModuleCloseCompletionBlock completion = info[@"completion"];
    [self closeTopModules:animated completion:completion];
}

- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)swift_bridge_previousTransitionHandler {
    return [self previousTransitionHandler];
}

- (NSNumber*)swift_bridge_skipOnDismiss {
    return [NSNumber numberWithBool:[self skipOnDismiss]];
}

- (void)swift_bridge_setSkipOnDismiss:(NSNumber*)skipOnDismiss {
    [self setSkipOnDismiss:[skipOnDismiss boolValue]];
}

@end

@protocol TranditionalViperViewWithOutput <NSObject>
- (id)output;
@end

//static int parentKey = 0;
//
//@interface ParentKeeper : NSObject
//@property (nonatomic, weak) UIViewController* previousConroller;
//@end
//
//@implementation ParentKeeper
//@end

@implementation UIViewController (RamblerViperModuleTransitionHandlerProtocol)

//- (ParentKeeper*)vipermcflurry_helper_parentKeeper {
//    ParentKeeper* keeper = objc_getAssociatedObject(self, &parentKey);
//    if (!keeper) {
//        keeper = [ParentKeeper new];
//        objc_setAssociatedObject(self, &parentKey, keeper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    }
//    return keeper;
//}
//
//- (void)vipermcflurry_helper_didMoveToParentViewController:(nullable UIViewController *)parent {
//
//    [self vipermcflurry_helper_didMoveToParentViewController:parent];
//
//    if (parent) {
//        if (![[self vipermcflurry_helper_parentKeeper] previousConroller]) {
//            [[self vipermcflurry_helper_parentKeeper] setPreviousConroller:parent];
//        }
//    }
//    else {
//        [[self vipermcflurry_helper_parentKeeper] setPreviousConroller:nil];
//    }
//}
//
//- (void)vipermcflurry_helper_presentViewController:(nonnull UIViewController *)controller animated:(BOOL)animated completion:(nullable void(^)(void))completion {
//    [[controller vipermcflurry_helper_parentKeeper] setPreviousConroller:self];
//    [self vipermcflurry_helper_presentViewController:controller animated:animated completion:completion];
//}

#pragma mark - RamblerViperModuleTransitionHandlerProtocol

+ (void)initialize {
    [self vipermcflurry_helper_swizzlePrepareForSegue];

//    swizzle(self, @selector(didMoveToParentViewController:), @selector(vipermcflurry_helper_didMoveToParentViewController:));
//    swizzle(self, @selector(presentViewController:animated:completion:), @selector(vipermcflurry_helper_presentViewController:animated:completion:));
}

- (id)moduleInput {
    id result = objc_getAssociatedObject(self, @selector(moduleInput));
    if (result == nil && [self respondsToSelector:@selector(output)]) {
        result = [(id<TranditionalViperViewWithOutput>)self output];
    }
    return result;
}

- (void)setModuleInput:(id<RamblerViperModuleInput>)moduleInput {
    objc_setAssociatedObject(self, @selector(moduleInput), moduleInput, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Performs segue without any actions, useful for unwind segues
- (void)performSegue:(NSString *)segueIdentifier {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:segueIdentifier sender:nil];
    });
}

- (NSString*)moduleIdentifier {
    return objc_getAssociatedObject(self, &moduleIdentifierKey);
}

- (void)setModuleIdentifier:(NSString *)moduleIdentifier {
    objc_setAssociatedObject(self, &moduleIdentifierKey, moduleIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)skipOnDismiss {
    NSNumber* const value = objc_getAssociatedObject(self, &skipOnDismissKey);
    if (![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    return [value boolValue];
}

- (void)setSkipOnDismiss:(BOOL)skipOnDismiss {
    objc_setAssociatedObject(self, &skipOnDismissKey, @(skipOnDismiss), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Method opens module using segue
- (RamblerViperOpenModulePromise*)openModuleUsingSegue:(NSString*)segueIdentifier {
    RamblerViperOpenModulePromise *openModulePromise = [[RamblerViperOpenModulePromise alloc] init];
    
    static const char key;
    objc_setAssociatedObject(self, &key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    void (^perform)(void) = ^{
        if (!objc_getAssociatedObject(self, &key)) {
            objc_setAssociatedObject(self, &key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self performSegueWithIdentifier:segueIdentifier sender:openModulePromise];
        }
    };
    //
    // defined this to try execute segue if thenChainUsingBlock was called just after current
    // openModuleUsingSegue call (when you should call some input method of module):
    //  [[self.transitionHandler openModuleUsingSegue:SegueIdentifier]
    //        thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<SomeModuleInput> moduleInput) {
    //            [moduleInput moduleConfigurationMethod];
    //            return nil;
    //  }];
    //  NOTE: In this case segue will be called in synchronous manner
    //
    openModulePromise.postChainActionBlock = ^{
        perform();
    };
    //
    // Also try to call segue if postChainActionBlock was not called in current runloop cycle,
    // for example, thenChainUsingBlock was not called just after openModuleUsingSegue:
    //
    //  [self.transitionHandler openModuleUsingSegue:SegueIdentifier];
    //
    //  NOTE: In this case segue will be called in asynchronous manner
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        perform();
    });
    return openModulePromise;
}

- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock
{
    return [self createEmbeddableModuleUsingFactory:moduleFactory configurationBlock:configurationBlock lazyAllocation:NO];
}

- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock
                                                   lazyAllocation:(BOOL)lazyAllocation
{
    __weak __block UIViewController* sourceViewController = self;
    __block UIViewController* destinationViewController;
    
    const void(^allocate)(void) = ^{

        NSAssert(sourceViewController, @"");
        NSAssert(!destinationViewController, @"");

        [[sourceViewController openModuleUsingFactory:moduleFactory withTransitionBlock:^(id<RamblerViperModuleTransitionHandlerProtocol> sourceModuleTransitionHandler, id<RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler) {
            sourceViewController = (UIViewController*)sourceModuleTransitionHandler;
            destinationViewController = (UIViewController*)destinationModuleTransitionHandler;
        }] thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<RamblerViperModuleInput> moduleInput) {
            return configurationBlock(moduleInput);
        }];

        NSAssert(sourceViewController, @"code above should be called synchronously");
        NSAssert(destinationViewController, @"code above should be called synchronously");
    };
    
    const EmbeddedModuleEmbedderBlock embedder  = ^EmbeddedModuleRemoverBlock(UIView* containerView) {

        if (destinationViewController == nil) {
            allocate();
        }
        
        const EmbeddedModuleRemoverBlock remover = ^{
            if (!destinationViewController.isViewLoaded || (destinationViewController.view.superview != containerView)) {
                return;
            }
            [destinationViewController willMoveToParentViewController:nil];
            [destinationViewController beginAppearanceTransition:NO animated:NO];
            [destinationViewController.view removeFromSuperview];
            [destinationViewController endAppearanceTransition];
            [destinationViewController removeFromParentViewController];
        };
        
        const void (^setupConstraints)(void) = ^{

            UIView* const embeddedView = destinationViewController.view;
            embeddedView.translatesAutoresizingMaskIntoConstraints = NO;
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[embeddedView]-0-|"
                                                                                  options:0
                                                                                  metrics:nil views:NSDictionaryOfVariableBindings(embeddedView)]];
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[embeddedView]-0-|"
                                                                                  options:0
                                                                                  metrics:nil views:NSDictionaryOfVariableBindings(embeddedView)]];
        };
        
        if (destinationViewController.isViewLoaded && destinationViewController.view.superview != nil) {
            if (destinationViewController.parentViewController == sourceViewController) { // parent controller is the same
                
                if (destinationViewController.view.superview == containerView) { // and view is the same
                    return remover;
                }
                
                // Does not need 'removeFromSuperview' because
                // it is automatically called whill addSubview
                [destinationViewController.view setFrame:containerView.bounds];
                [containerView addSubview:destinationViewController.view];
                setupConstraints();
                return remover;
            }
            else {
                [destinationViewController willMoveToParentViewController:nil];
                [destinationViewController beginAppearanceTransition:NO animated:NO];
                [destinationViewController.view removeFromSuperview];
                [destinationViewController endAppearanceTransition];
                [destinationViewController removeFromParentViewController];
            }
        }
        
        [sourceViewController addChildViewController:destinationViewController];
        [destinationViewController.view setFrame:containerView.bounds];
        [destinationViewController beginAppearanceTransition:YES animated:NO];
        [containerView addSubview:destinationViewController.view];
        [destinationViewController endAppearanceTransition];
        [destinationViewController didMoveToParentViewController:sourceViewController];
        setupConstraints();
        return remover;
    };
    
    if (!lazyAllocation) {
        allocate();
    }
    
    return embedder;
}

- (RamblerViperOpenModulePromise*)openModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory {
    
    RamblerViperOpenModulePromise *openModulePromise = [[RamblerViperOpenModulePromise alloc] init];
    id<RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler = [moduleFactory instantiateModuleTransitionHandler];
    id<RamblerViperModuleInput> moduleInput = nil;
    if ([destinationModuleTransitionHandler respondsToSelector:@selector(moduleInput)]) {
        moduleInput = [destinationModuleTransitionHandler moduleInput];
    }

    openModulePromise.moduleInput = moduleInput;
    
    if ([destinationModuleTransitionHandler conformsToProtocol:@protocol(RamblerViperModuleViewControllerPresenter)]
        && [destinationModuleTransitionHandler respondsToSelector:@selector(viperModuleViewControllerPresentIn:)]
        &&
        (![destinationModuleTransitionHandler respondsToSelector:@selector(viperModuleViewControllerShouldPresentIn:)]
         || [(id<RamblerViperModuleViewControllerPresenter>)destinationModuleTransitionHandler viperModuleViewControllerShouldPresentIn:self])
        ) {
        id<RamblerViperModuleViewControllerPresenter> const presenter = (id<RamblerViperModuleViewControllerPresenter>)destinationModuleTransitionHandler;
        
        openModulePromise.postLinkActionBlock = ^{
            [presenter viperModuleViewControllerPresentIn:self];
        };
    }
    return openModulePromise;
}

// Method opens module using module factory
- (RamblerViperOpenModulePromise*)openModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory withTransitionBlock:(ModuleTransitionBlock)transitionBlock {
    RamblerViperOpenModulePromise *openModulePromise = [[RamblerViperOpenModulePromise alloc] init];
    id<RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler = [moduleFactory instantiateModuleTransitionHandler];
    id<RamblerViperModuleInput> moduleInput = nil;
    if ([destinationModuleTransitionHandler respondsToSelector:@selector(moduleInput)]) {
        moduleInput = [destinationModuleTransitionHandler moduleInput];
    }

    openModulePromise.moduleInput = moduleInput;
    if (transitionBlock != nil) {
        openModulePromise.postLinkActionBlock = ^{
            transitionBlock(self,destinationModuleTransitionHandler);
        };
    }
    return openModulePromise;
}

- (void)closeToModuleWithIdentifier:(NSString*)moduleIdentifier animated:(BOOL)animated completion:(_Nullable ModuleCloseCompletionBlock)completion {
    UIViewController* const target = [(UIViewController*)[self previousTransitionHandler] vipermcflurry_helper_findModuleBeforeModuleWithIdentifier:moduleIdentifier previous:self];
    if (target) {
        [target closeCurrentModuleIgnoringSkipping:animated completion:completion];
    }
    else {
        [self closeCurrentModule:animated completion:completion];
    }
}

- (void)closeToModuleWithIdentifier:(NSString*)moduleIdentifier animated:(BOOL)animated {
    [self closeToModuleWithIdentifier:moduleIdentifier animated:animated completion:nil];
}

// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
    NSMutableArray* skipped = [NSMutableArray new];
    UIViewController* target = [self vipermcflurry_helper_findControllerBeforeNextNotSkippableController:skipped];
    if (target) {

        [skipped enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj vipermcflurry_helper_notifyAboutSkip];
        }];

        [target closeCurrentModuleIgnoringSkipping:animated completion:completion];
    }
    else {
        [self closeCurrentModule:animated completion:completion];
    }
}

// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated {
    [self closeCurrentModule:animated completion:nil];
}

- (void)closeModulesUntil:(id<RamblerViperModuleTransitionHandlerProtocol>)transitionHandler animated:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {

    if (!transitionHandler) {
        [self closeCurrentModule:animated completion:completion];
        return;
    }

    UIViewController* parent = (UIViewController*)[self previousTransitionHandler];
    if (!parent || parent == transitionHandler) {
        [self closeCurrentModule:animated completion:completion];
        return;
    }

    [parent closeModulesUntil:transitionHandler animated:animated completion:completion];
}

- (BOOL)tryCustomDismiss:(BOOL)animated completion:(void(^)(void))completion {
    
    if ([self conformsToProtocol:@protocol(RamblerViperModuleViewControllerDismisser)]
        && [self respondsToSelector:@selector(viperModuleViewControllerDismiss:completion:)]) {
        id<RamblerViperModuleViewControllerDismisser> dismisser = (id<RamblerViperModuleViewControllerDismisser>)self;
        [dismisser viperModuleViewControllerDismiss:animated completion:completion];
        return YES;
    }
    
    if (![self respondsToSelector:NSSelectorFromString(@"hasViperModuleDismisser")]) {
        return NO;
    }
    
    const id hasViperModuleDismisser = [self performSelector:NSSelectorFromString(@"hasViperModuleDismisser") withObject:nil];
    
    if (![hasViperModuleDismisser boolValue]) {
        return NO;
    }
    
    if (!completion) {
        completion = ^{};
    }
    
    void (^vipermoduleDismisser)(BOOL,void(^)(void)) = [self performSelector:NSSelectorFromString(@"hasViperModuleDismisser") withObject:nil];
    
    vipermoduleDismisser(animated, completion);
    return YES;
}

- (void)closeCurrentModuleIgnoringSkipping:(BOOL)animated completion:(void(^)(void))completion {
    [self vipermcflurry_helper_waitForAnimationCompleted:^{
        
        if ([self tryCustomDismiss: animated completion:completion]) {
            return;
        }
        
        if ([self.parentViewController isKindOfClass:[UITabBarController class]]) {

            UITabBarController* const tc = (UITabBarController*)self.parentViewController;

            NSArray<UIViewController*>* const controllers = [tc.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                return evaluatedObject != self;
            }]];

            [tc setViewControllers:controllers animated:animated];

            if (completion) {
                if (tc.transitionCoordinator) {
                    [tc.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
                                                              completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { completion(); }];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                    return;
                }
            }
        }
        else if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {

            UINavigationController* const navigationController = (UINavigationController*)self.parentViewController;
            NSArray<UIViewController*>* const viewControllers = navigationController.viewControllers;

            if (viewControllers.count > 1) {

                if (viewControllers.lastObject == self) {
                    [navigationController popViewControllerAnimated:animated];
                }
                else {
                    const NSUInteger index = [viewControllers indexOfObject:self];
                    if (index > 0) {
                        [navigationController popToViewController:viewControllers[index - 1] animated:animated];
                    }
                    else if (index == 0) {
                        [navigationController closeCurrentModuleIgnoringSkipping:animated completion:completion];
                        return;
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion();
                        });
                        return;
                    }
                }

                if (completion) {
                    if (navigationController.transitionCoordinator) {
                        [navigationController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
                                                                                    completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { completion(); }];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion();
                        });
                    }
                }
            }
            else {
                [navigationController closeCurrentModuleIgnoringSkipping:animated completion:completion];
                return;
            }
        }
        else if (self.presentingViewController.presentedViewController == self) {
            [self.presentingViewController dismissViewControllerAnimated:animated completion:completion];
        }
        else if (self.parentViewController){

            [self willMoveToParentViewController:nil];
            if (animated) {
                [self beginAppearanceTransition:NO animated:YES];
                [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                                      delay:0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.view.alpha = 0;
                                 }
                                 completion:^(BOOL finished) {
                                     [self.view removeFromSuperview];
                                     [self endAppearanceTransition];
                                     [self removeFromParentViewController];
                                     if (completion) {
                                         completion();
                                     }
                                 }];
            }
            else {
                [self beginAppearanceTransition:NO animated:NO];
                [self.view removeFromSuperview];
                [self endAppearanceTransition];
                [self removeFromParentViewController];
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }
        }
        else {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        }
    }];
}

- (void)closeTopModules:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:animated completion:completion];
    }
    else if (self.navigationController) {
        const NSInteger index = [self.navigationController.viewControllers indexOfObject:self];
        if (index >= 0) {
            if (index < [self.navigationController.viewControllers count] - 1) {
                UIViewController* const next = [self.navigationController.viewControllers objectAtIndex:index + 1];
                [next closeCurrentModuleIgnoringSkipping:animated completion:completion];
            }
            else {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }
        }
        else {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        }
    }
    else {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
}

//// Method removes/closes module
//- (void)closeModulesUntilMatch:(BOOL(^)(id<RamblerViperModuleTransitionHandlerProtocol> transitionHandler))compare animated:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
//
//    if (compare && compare(self)) {
//        if (completion) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completion();
//            });
//        }
//        return;
//    }
//
//    BOOL (^skip)(UIViewController*) = ^BOOL(UIViewController* controller) {
//
//        if (!controller.skipOnDismiss) {
//            return NO;
//        }
//
//        [controller vipermcflurry_helper_notifyAboutSkip];
//        [controller closeModulesUntilMatch:compare animated:animated completion:completion];
//        return YES;
//    };
//
//    if ([self.parentViewController isKindOfClass:[UITabBarController class]]) {
//
//        UITabBarController* const tc = (UITabBarController*)self.parentViewController;
//
//        NSArray<UIViewController*>* const controllers = [tc.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
//            return evaluatedObject != self;
//        }]];
//
//        [tc setViewControllers:controllers animated:animated];
//
//        if (tc.transitionCoordinator) {
//            [tc.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
//                                                      completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//                if (compare) {
//                    [self closeModulesUntilMatch:compare animated:animated completion:completion];
//                }
//                else {
//                    if (completion) {
//                        completion();
//                    }
//                }
//            }];
//        }
//        else {
//            if (compare) {
//                [self closeModulesUntilMatch:compare animated:animated completion:completion];
//            }
//            else {
//                if (completion) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        completion();
//                    });
//                }
//            }
//        }
//    }
//    else if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
//
//        if (skip(self.parentViewController)) {
//            return;
//        }
//
//        UINavigationController* const navigationController = (UINavigationController*)self.parentViewController;
//
//        if (navigationController.viewControllers.count > 1) {
//
//            if (compare) {
//
//                const NSArray<UIViewController*>* const match = [navigationController.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
//                    return compare(evaluatedObject);
//                }]];
//
//                if ([match count] > 0) {
//                    [navigationController popToViewController:[match lastObject] animated:animated];
//                }
//                else {
//                    [navigationController closeModulesUntilMatch:compare animated:animated completion:completion];
//                    return;
//                }
//            }
//            else {
//
//                NSArray<UIViewController*>* const viewControllers = navigationController.viewControllers;
//
//                if (viewControllers.lastObject == self) {
//                    [navigationController popViewControllerAnimated:animated];
//                }
//                else {
//                    const NSUInteger index = [viewControllers indexOfObject:self];
//                    if (index > 0) {
//                        [navigationController popToViewController:viewControllers[index - 1] animated:animated];
//                    }
//                    else {
//                        [navigationController closeModulesUntilMatch:compare animated:animated completion:completion];
//                        return;
//                    }
//                }
//            }
//
//            if (completion) {
//                if (navigationController.transitionCoordinator) {
//                    [navigationController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
//                                                                  completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//                                                                      completion();
//                                                                  }];
//                }
//                else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        completion();
//                    });
//                }
//            }
//        }
//        else if (navigationController.viewControllers.count == 1) {
//            [self.parentViewController closeModulesUntilMatch:compare animated:animated completion:completion];
//        }
//        else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completion();
//            });
//        }
//    }
//    else if (self.presentingViewController.presentedViewController == self) {
//
//        if (skip(self.presentingViewController)) {
//            return;
//        }
//
//        if (self.skipOnDismiss) {
//            [self.presentingViewController dismissViewControllerAnimated:animated completion:completion];
//            return;
//        }
//
//        NSMutableArray<UIViewController*>* const topPresented = [NSMutableArray new];
//        UIViewController* current = self;
//
//        while (current.presentedViewController) {
//            [topPresented addObject:current.presentedViewController];
//            current = current.presentedViewController;
//        }
//
//        if ([topPresented count] == 0) {
//
//            if (compare) {
//                [self.presentingViewController closeModulesUntilMatch:compare animated:animated completion:completion];
//                return;
//            }
//
//            [self dismissViewControllerAnimated:animated completion:completion];
//            return;
//        }
//
//        __block BOOL inProgress = NO;
//
//        [topPresented enumerateObjectsUsingBlock:^(UIViewController*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            if ([obj isBeingPresented] || [obj isBeingDismissed] || [obj isMovingFromParentViewController] || [obj isMovingToParentViewController]) {
//                *stop = YES;
//                inProgress = YES;
//            }
//        }];
//
//        if (inProgress) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self closeModulesUntilMatch:compare animated:animated completion:completion];
//            });
//            return;
//        }
//
//        [[topPresented lastObject] dismissViewControllerAnimated:animated completion:^{
//            [self closeModulesUntilMatch:compare animated:animated completion:completion];
//        }];
//    }
//    else if (self.parentViewController){
//
//        if (skip(self.parentViewController)) {
//            return;
//        }
//
//        [self willMoveToParentViewController:nil];
//        if (animated) {
//            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
//                                  delay:0
//                                options:UIViewAnimationOptionBeginFromCurrentState
//                             animations:^{
//                                 self.view.alpha = 0;
//                             }
//                             completion:^(BOOL finished) {
//                                 [self.view removeFromSuperview];
//                                 [self removeFromParentViewController];
//                                 if (completion) {
//                                     completion();
//                                 }
//                             }];
//        }
//        else {
//            [self.view removeFromSuperview];
//            [self removeFromParentViewController];
//            if (completion) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completion();
//                });
//            }
//        }
//    }
//    else {
//        if (completion) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completion();
//            });
//        }
//    }
//}

- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)previousTransitionHandler {
//    return [[self vipermcflurry_helper_parentKeeper] previousConroller];
    if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {

        UINavigationController *navigationController = (UINavigationController*)self.parentViewController;
        const NSInteger idx = [navigationController.viewControllers indexOfObject:self];

        if (idx == 0) {
            return navigationController;
        }

        return [navigationController.viewControllers objectAtIndex:idx - 1];
    }
    else if (self.presentingViewController.presentedViewController == self) {
        return self.presentingViewController;
    }
    else {
        return self.parentViewController;
    }
}

#pragma mark - PrepareForSegue swizzling

+ (void)vipermcflurry_helper_swizzlePrepareForSegue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IMP reamplerPrepareForSegueImp = (IMP)RamblerViperPrepareForSegueSender;

        Method prepareForSegueMethod = class_getInstanceMethod([self class], @selector(prepareForSegue:sender:));
        originalPrepareForSegueMethodImp = method_setImplementation(prepareForSegueMethod, reamplerPrepareForSegueImp);
    });
}

void RamblerViperPrepareForSegueSender(id self, SEL selector, UIStoryboardSegue * segue, id sender) {

    ((void(*)(id,SEL,UIStoryboardSegue*,id))originalPrepareForSegueMethodImp)(self,selector,segue,sender);

    if (![sender isKindOfClass:[RamblerViperOpenModulePromise class]]) {
        return;
    }

    id<RamblerViperModuleInput> moduleInput = nil;

    UIViewController *destinationViewController = segue.destinationViewController;
    if ([destinationViewController isKindOfClass:[UINavigationController class]]) {
      UINavigationController *navigationController = segue.destinationViewController;
      destinationViewController = navigationController.topViewController;
    }

    id<RamblerViperModuleTransitionHandlerProtocol> targetModuleTransitionHandler = destinationViewController;
    if ([targetModuleTransitionHandler respondsToSelector:@selector(moduleInput)]) {
        moduleInput = [targetModuleTransitionHandler moduleInput];
    }

    RamblerViperOpenModulePromise *openModulePromise = sender;
    openModulePromise.moduleInput = moduleInput;
}

@end
