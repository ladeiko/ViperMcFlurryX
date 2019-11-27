//
//  RamblerViperModuleTransitionHandlerProtocol.h
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RamblerViperOpenModulePromise;
@protocol RamblerViperModuleInput;
@protocol RamblerViperModuleOutput;
@class RamblerViperModuleFactory;
@protocol RamblerViperModuleTransitionHandlerProtocol;
@protocol RamblerViperModuleFactoryProtocol;

typedef void (^ModuleCloseCompletionBlock)(void);
typedef void (^ModuleTransitionBlock)(id<RamblerViperModuleTransitionHandlerProtocol> sourceModuleTransitionHandler,
                                      id<RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler);
typedef void (^EmbeddedModuleRemoverBlock)(void);
typedef EmbeddedModuleRemoverBlock _Nonnull (^EmbeddedModuleEmbedderBlock)(UIView* containerView);
typedef id<RamblerViperModuleOutput>_Nullable(^EmbeddedModuleConfigurationBlock)(id<RamblerViperModuleInput> moduleInput);

/**
 Protocol defines interface for intermodule transition
 */
@protocol RamblerViperModuleTransitionHandlerProtocol <NSObject>

@optional

// Module input object
@property (nonatomic, strong) id<RamblerViperModuleInput> moduleInput;

// Performs segue without any actions, useful for unwind segues
- (void)performSegue:(NSString *)segueIdentifier;
// Method opens module using segue
- (RamblerViperOpenModulePromise*)openModuleUsingSegue:(NSString*)segueIdentifier;
// Method opens module using module factory
- (RamblerViperOpenModulePromise*)openModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory withTransitionBlock:(ModuleTransitionBlock)transitionBlock;

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
- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock
                                                   lazyAllocation:(BOOL)lazyAllocation;

// Shorter version of 'createEmbeddableModuleUsingFactory' where lazyAllocation is false
- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock;

// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated;
// Method removes/closes module
- (void)closeCurrentModule:(BOOL)animated completion:(_Nullable ModuleCloseCompletionBlock)completion;
// Method removes/closes module until specified transitionHandler becomes top
- (void)closeModulesUntil:(_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)transitionHandler animated:(BOOL)animated completion:(_Nullable ModuleCloseCompletionBlock)completion;
// Method removes/closes module. Uses self as transitionHandler in 'closeModulesUntil'
- (void)closeTopModules:(BOOL)animated completion:(_Nullable ModuleCloseCompletionBlock)completion;
// Returns parent module if possible
- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)parentTransitionHandler;

@property (nonatomic, assign) BOOL skipOnDismiss;

@end

NS_ASSUME_NONNULL_END

