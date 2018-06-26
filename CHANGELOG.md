# CHANGELOG

## 1.8.3
### Fixed
* Crash on adding constraints
* 
## 1.8.2
### Fixed
* Crash on constraint visual format

## 1.8.1
### Added
* ```- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock
                                                   lazyAllocation:(BOOL)lazyAllocation;```
* ```- (EmbeddedModuleEmbedderBlock)createEmbeddableModuleUsingFactory:(id <RamblerViperModuleFactoryProtocol>)moduleFactory
                                               configurationBlock:(EmbeddedModuleConfigurationBlock)configurationBlock;```

## 1.7.3, 1.7.4
### Fixed
* Compilation warnings

## 1.7.2
### Updated
* Update ```parentTransitionHandler``` logic

## 1.7.1
### Added
* ```- (void)closeModulesUntil:(id<RamblerViperModuleTransitionHandlerProtocol>)transitionHandler animated:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion;```
* ```- (void)closeTopModules:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion;```
* ```- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)parentTransitionHandler;```

## v1.6.2

* *openModuleUsingSegue* will be called synchronously if *thenChainUsingBlock* was called on promise just after main call. In another case segue will be executed on next runloop cycle. Sync version ensures that after call to * openModuleUsingSegue* segue was executed.
* Updated code of *- (void)closeCurrentModule:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion* for navigation controller case when completion call is required. Also added *[self willMoveToParentViewController:nil]* before *removeFromParentViewController*.
