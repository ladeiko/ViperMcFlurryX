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

static IMP originalPrepareForSegueMethodImp;
static int treatMeAsRootTransitionHandlerKey = 0;
static int passedKey = 0;

@protocol TranditionalViperViewWithOutput <NSObject>
- (id)output;
@end


@implementation UIViewController (RamblerViperModuleTransitionHandlerProtocol)

#pragma mark - RamblerViperModuleTransitionHandlerProtocol

+ (void)initialize {
    [self swizzlePrepareForSegue];
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

- (BOOL)skipOnDismiss {
    NSNumber* const value = objc_getAssociatedObject(self, &treatMeAsRootTransitionHandlerKey);
    if (![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    return [value boolValue];
}

- (void)setSkipOnDismiss:(BOOL)skipOnDismiss {
    objc_setAssociatedObject(self, &treatMeAsRootTransitionHandlerKey, @(skipOnDismiss), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    __block UIViewController* sourceViewController;
    __block UIViewController* destinationViewController;
    
    const void(^allocate)(void) = ^{
        [[self openModuleUsingFactory:moduleFactory withTransitionBlock:^(id<RamblerViperModuleTransitionHandlerProtocol> sourceModuleTransitionHandler, id<RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler) {
            sourceViewController = (UIViewController*)sourceModuleTransitionHandler;
            destinationViewController = (UIViewController*)destinationModuleTransitionHandler;
        }] thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<RamblerViperModuleInput> moduleInput) {
            return configurationBlock(moduleInput);
        }];
        NSAssert(sourceViewController, @"code above should be called synchronously");
        NSAssert(destinationViewController, @"code above should be called synchronously");
    };
    
    const EmbeddedModuleEmbedderBlock embedder  = ^EmbeddedModuleRemoverBlock(UIView* containerView) {
        
        if (lazyAllocation && destinationViewController == nil) {
            allocate();
        }
        
        const EmbeddedModuleRemoverBlock remover = ^{
            if (!destinationViewController.isViewLoaded || (destinationViewController.view.superview != containerView)) {
                return;
            }
            [destinationViewController willMoveToParentViewController:nil];
            [destinationViewController.view removeFromSuperview];
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
                [containerView addSubview:destinationViewController.view];
                setupConstraints();
                return remover;
            }
            else {
                [destinationViewController willMoveToParentViewController:nil];
                [destinationViewController.view removeFromSuperview];
                [destinationViewController removeFromParentViewController];
            }
        }
        
        [sourceViewController addChildViewController:destinationViewController];
        [containerView addSubview:destinationViewController.view];
        [destinationViewController didMoveToParentViewController:sourceViewController];
        setupConstraints();
        return remover;
    };
    
    if (!lazyAllocation) {
        allocate();
    }
    
    return embedder;
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

// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated {
    [self closeCurrentModule:animated completion:nil];
}

// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
    [self closeModulesUntil:nil animated:animated completion:completion];
}

// Method removes/closes module
- (void)closeModulesUntil:(id<RamblerViperModuleTransitionHandlerProtocol>)transitionHandler animated:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
    assert(!transitionHandler || [transitionHandler isKindOfClass:[UIViewController class]]);
    
    if (transitionHandler) {
        if ( self == transitionHandler) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
            return;
        }
    }
    
    BOOL (^skip)(UIViewController*) = ^BOOL(UIViewController* controller) {
        
        if (!controller.skipOnDismiss) {
            return NO;
        }

        NSObject<RamblerViperModuleInput>* moduleInput = [self moduleInput];
        if ([moduleInput conformsToProtocol:@protocol(RamblerViperModuleInput)]
            && [moduleInput respondsToSelector:@selector(moduleDidSkipOnDismiss)]) {
            [moduleInput performSelector:@selector(moduleDidSkipOnDismiss) withObject:nil afterDelay:0];
        }
        
        [controller closeModulesUntil:transitionHandler animated:animated completion:completion];
        return YES;
    };
    
    if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
        
        if (skip(self.parentViewController)) {
            return;
        }
        
        UINavigationController* const navigationController = (UINavigationController*)self.parentViewController;
        
        if (navigationController.viewControllers.count > 1) {
            
            if (transitionHandler) {
                [navigationController popToViewController:(UIViewController*)transitionHandler animated:animated];
            }
            else {
                
                NSArray<UIViewController*>* const viewControllers = navigationController.viewControllers;
                
                if (viewControllers.lastObject == self) {
                    [navigationController popViewControllerAnimated:animated];
                }
                else {
                    const NSUInteger index = [viewControllers indexOfObject:self];
                    if (index > 0) {
                        [navigationController popToViewController:viewControllers[index - 1] animated:animated];
                    }
                    else {
                        [navigationController closeModulesUntil:transitionHandler animated:animated completion:completion];
                        return;
                    }
                }
            }
            
            if (completion) {
                if (navigationController.transitionCoordinator) {
                    [navigationController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
                                                                  completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                                                                      completion();
                                                                  }];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }
        }
        else {
            [self.parentViewController closeModulesUntil:transitionHandler animated:animated completion:completion];
        }
    }
    else if (self.presentingViewController.presentedViewController == self) {
        
        if (skip(self.presentingViewController)) {
            return;
        }
        
        if (self.skipOnDismiss) {
            [self.presentingViewController dismissViewControllerAnimated:animated completion:completion];
            return;
        }
        
        NSMutableArray<UIViewController*>* const topPresented = [NSMutableArray new];
        UIViewController* current = self;
        
        while (current.presentedViewController) {
            [topPresented addObject:current.presentedViewController];
            current = current.presentedViewController;
        }
        
        if ([topPresented count] == 0) {
            [self dismissViewControllerAnimated:animated completion:completion];
            return;
        }
        
        __block BOOL inProgress = NO;
        
        [topPresented enumerateObjectsUsingBlock:^(UIViewController*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isBeingPresented] || [obj isBeingDismissed] || [obj isMovingFromParentViewController] || [obj isMovingToParentViewController]) {
                *stop = YES;
                inProgress = YES;
            }
        }];
        
        if (inProgress) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1/60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self closeModulesUntil:transitionHandler animated:animated completion:completion];
            });
            return;
        }
        
        [[topPresented lastObject] dismissViewControllerAnimated:animated completion:^{
            [self closeModulesUntil:transitionHandler animated:animated completion:completion];
        }];
    }
    else if (self.parentViewController){
        
        if (skip(self.parentViewController)) {
            return;
        }
        
        [self willMoveToParentViewController:nil];
        if (animated) {
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.view.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 [self.view removeFromSuperview];
                                 [self removeFromParentViewController];
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
        else {
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        }
    }
    else {
        assert("not applicable");
    }
}

- (void)closeTopModules:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion {
    [self closeModulesUntil:self animated:animated completion:completion];
}

- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)parentTransitionHandler {
    BOOL isInNavigationStack = [self.parentViewController isKindOfClass:[UINavigationController class]];
    
    if (isInNavigationStack) {
        
        UINavigationController *navigationController = (UINavigationController*)self.parentViewController;
        if (navigationController.viewControllers.count == 1) {
            return nil;
        }
        
        const NSInteger idx = [navigationController.viewControllers indexOfObject:self];
        if (idx == 0 || idx == NSNotFound) {
            return nil;
        }
        
        UIViewController* candidate = [navigationController.viewControllers objectAtIndex:idx - 1];
        if (![candidate conformsToProtocol:@protocol(RamblerViperModuleTransitionHandlerProtocol)]) {
            return nil;
        }
        
        return (id<RamblerViperModuleTransitionHandlerProtocol>)candidate;
    }
    else if (self.presentingViewController.presentedViewController == self) {
        UIViewController* candidate = self.presentingViewController;
        if (![candidate conformsToProtocol:@protocol(RamblerViperModuleTransitionHandlerProtocol)]) {
            return nil;
        }
        
        return (id<RamblerViperModuleTransitionHandlerProtocol>)candidate;
    }
    else {
        UIViewController* candidate = self.parentViewController;
        if (![candidate conformsToProtocol:@protocol(RamblerViperModuleTransitionHandlerProtocol)]) {
            return nil;
        }
        
        return (id<RamblerViperModuleTransitionHandlerProtocol>)candidate;
    }
    return nil;
}

#pragma mark - PrepareForSegue swizzling

+ (void)swizzlePrepareForSegue {
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