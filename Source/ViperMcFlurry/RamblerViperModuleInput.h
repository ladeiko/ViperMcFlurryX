//
//  RamblerViperModuleInput.h
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RamblerViperModuleOutput;

@protocol RamblerViperModuleInput <NSObject>

@optional
- (void)setModuleOutput:(id<RamblerViperModuleOutput>)moduleOutput;
// is called when skipOnDismiss is YES and child controller is being dismissed
- (void)moduleDidSkipOnDismiss;
@end
