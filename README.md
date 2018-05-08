### Overview

[![Pod version](https://badge.fury.io/co/ViperMcFlurryX.svg)](https://badge.fury.io/co/ViperMcFlurryX)

**NOTE**: It is a fork of [Rambler VIPER McFlurry](https://github.com/rambler-digital-solutions/ViperMcFlurry)

**VIPER McFlurry** is a modern framework for implementing [VIPER architecture](https://github.com/rambler-digital-solutions/The-Book-of-VIPER) in iOS application. It offers several tools and components that help either start new projects with VIPER or move from MVC.

![McFlurry](http://67.media.tumblr.com/36413ae65aa3f97fbce9ec53b21aa0ef/tumblr_oa2wlngg6u1r8u8uko1_500.jpg)

### Changes

### v1.7.3
* Remove some compilation warnings

### v1.7.2

* Update ```parentTransitionHandler``` logic

### v1.7.1
* Add more *closeModule* variations to
  ```
  RamblerViperModuleTransitionHandlerProtocol
  ```
  
```
- (void)closeModulesUntil:(id<RamblerViperModuleTransitionHandlerProtocol>)transitionHandler animated:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion;

- (void)closeTopModules:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion;
```

* Add 

```
- (_Nullable id<RamblerViperModuleTransitionHandlerProtocol>)parentTransitionHandler;
```

#### v1.6.2

* *openModuleUsingSegue* will be called synchronously if *thenChainUsingBlock* was called on promise just after main call. In another case segue will be executed on next runloop cycle. Sync version ensures that after call to * openModuleUsingSegue* segue was executed.
* Updated code of *- (void)closeCurrentModule:(BOOL)animated completion:(ModuleCloseCompletionBlock)completion* for navigation controller case when completion call is required. Also added *[self willMoveToParentViewController:nil]* before *removeFromParentViewController*.

### Key Features

- The framework itself pushes you to implement a **proper VIPER architecture**,
- It provides an extremely nice and easy way to implement **intermodule data transfer**,
- Used in [default Generamba template](https://github.com/rambler-digital-solutions/generamba-catalog/tree/master/rviper_controller).

### Usage

> This example works only for Module with `UIViewController` as View. However, it's possible to use this approach even with `UIView` and `UITableViewCell` acting as View.

- Create Module input protocol for target module inherited from ``RamblerViperModuleInput``:

```objective-c
@protocol SomeModuleInput <RamblerViperModuleInput>

- (void)moduleConfigurationMethod;

@end
```    

- Make Presenter of target module conform to this protocol.
- Inject Presenter as moduleInput property of the view. You can skip this step if presenter is a view property with name "output".
- Add Segue from source module ViewController to target module ViewController.
- Inject Source ViewController into Source Router as property "transition handler".
- In Router method call transition handler to open target module with configuration during segue.

```objective-c
[[self.transitionHandler openModuleUsingSegue:SegueIdentifier]
	thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<SomeModuleInput> moduleInput) {
		[moduleInput moduleConfigurationMethod];
		return nil;
	}];

```

#### Working with Module output

- Create Module output protocol for target module inherited from ``RamblerViperModuleOutput``:

```objective-c
@protocol SomeModuleOutput <RamblerViperModuleOutput>

- (void)moduleConfigurationMethod;

@end
```    
- Make source module presenter to conform to this protocol.
- Add to target module presenter method:

```objective-c
- (void)setModuleOutput:(id<RamblerViperModuleOutput>)moduleOutput;
```

- Return source module presenter from configuration block in router:

```objective-c
[[self.transitionHandler openModuleUsingSegue:SegueIdentifier]
	thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<SomeModuleInput> moduleInput) {
		[moduleInput moduleConfigurationMethod];
		return sourceRouterPresenter; // Return of module output
	}];

```

#### Working with Module Factory

Module factory can be replaced with segues for most cases. Except you need to create complex module or nontrivial module instantiation logic.

- Use ```RamblerViperModuleFactory``` object as module fabric with Typhoon.
- Set definition Initializer to ```initWithViewControllerLoader:andViewControllerIdentifier:```
    - First parameter is the object which loads the view controller, e.g. UIStoryboard or TyphoonNibLoader instance,
    - Second parameter is view controller's identifier, e.g. RestorationID or NibName of ViewController.
- Typhoon will initialize module from ViewController.
- Inject this Factory into router.
- Call Transition Handler's method ``- openModuleUsingFactory:withTransitionBlock:``.
- Second block is place where transition from one to another viewController/transitionHandler should be performed:
```objective-c
    [[self.transitionHandler openModuleUsingFactory:self.betaModuleFactory
                                withTransitionBlock:^(id <RamblerViperModuleTransitionHandlerProtocol> sourceModuleTransitionHandler,
                                        id <RamblerViperModuleTransitionHandlerProtocol> destinationModuleTransitionHandler) {

                                    UIViewController *sourceViewController = (id) sourceModuleTransitionHandler;
                                    UIViewController *destinationViewController = (id) destinationModuleTransitionHandler;

                                    [sourceViewController.navigationController pushViewController:destinationViewController
                                                                                         animated:YES];

                                }] thenChainUsingBlock:^id<RamblerViperModuleOutput>(id<RamblerModuleBetaInput> moduleInput) {
                                   [moduleInput configureWithExampleString:exampleString];
                                   return nil;
                               }];
```
- In example above one module is pushed to navigation stack of another module.
- Modules are linked with intermodule data transfer block.

### Installation

Add to podfile

```ruby
pod "ViperMcFlurryX"
```

### License

MIT

## Authors

**Rambler&Co** team:

- Andrey Zarembo-Godzyatsky / a.zarembo-godyzatsky@rambler-co.ru
- Valery Popov / v.popov@rambler-co.ru
- Egor Tolstoy / e.tolstoy@rambler-co.ru

**ViperMcFlurryX** fork:
- Siarhei Ladzeika / sergey.ladeiko@gmail.com
