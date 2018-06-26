//
//  RamblerModuleBetaRouter.m
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import "RamblerModuleBetaRouter.h"

@implementation RamblerModuleBetaRouter

#pragma mark - RamblerModuleBetaRouterInput

- (void)removeModule:(BOOL)animated {
    [self.transitionHandler closeCurrentModule:animated completion:^{
        NSLog(@"Beta dismiss completed");
    }];
}

@end
