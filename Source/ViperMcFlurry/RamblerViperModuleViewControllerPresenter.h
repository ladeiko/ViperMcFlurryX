//
//  RamblerViperModuleViewControllerPresenter.h
//  ViperMcFlurry
//
//  Copyright (c) 2020 Siarhei Ladzeika. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RamblerViperModuleViewControllerPresenter <NSObject>

@optional

- (BOOL)viperModuleViewControllerShouldPresentIn:(UIViewController*)viewController;
- (void)viperModuleViewControllerPresentIn:(UIViewController*)viewController;

@end

NS_ASSUME_NONNULL_END

