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

// Method opens module using segue
- (RamblerViperOpenModulePromise*)openModuleUsingSegue:(NSString*)segueIdentifier {
    RamblerViperOpenModulePromise *openModulePromise = [[RamblerViperOpenModulePromise alloc] init];
    
    static const char key;
    objc_setAssociatedObject(self, &key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    void (^perform)() = ^{
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
    
    BOOL isInNavigationStack = [self.parentViewController isKindOfClass:[UINavigationController class]];
    BOOL hasManyControllersInStack = isInNavigationStack ? ((UINavigationController *)self.parentViewController).childViewControllers.count > 1 : NO;
    
    if (isInNavigationStack && hasManyControllersInStack) {
        UINavigationController *navigationController = (UINavigationController*)self.parentViewController;
        UIViewController* popped = navigationController.viewControllers.lastObject;
        
        if (transitionHandler) {
            [navigationController popToViewController:(UIViewController*)transitionHandler animated:animated];
        }
        else {
            [navigationController popViewControllerAnimated:animated];
        }
        
        if (completion) {
            if (popped.transitionCoordinator) {
                [popped.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
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
    else if (self.presentingViewController) {
        assert(!transitionHandler && "not implemented");
        [self dismissViewControllerAnimated:animated completion:completion];
    }
    else if (self.view.superview != nil){
        assert(!transitionHandler && "not implemented");
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
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
    // TODO
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
