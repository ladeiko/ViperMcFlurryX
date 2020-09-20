//
//  RamblerViperModuleViewControllerDismisser.h
//  ViperMcFlurry
//
//  Copyright (c) 2020 Siarhei Ladzeika. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RamblerViperModuleViewControllerDismisser <NSObject>
@optional
- (void)viperModuleViewControllerDismiss:(BOOL)animated completion:(void(^ _Nullable)())completion;
@end

NS_ASSUME_NONNULL_END

