//
//  RamblerModuleBetaRouter.h
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ViperMcFlurryX/ViperMcFlurry.h>
#import "RamblerModuleBetaRouterInput.h"

@interface RamblerModuleBetaRouter : NSObject <RamblerModuleBetaRouterInput>

@property (nonatomic,weak) id<RamblerViperModuleTransitionHandlerProtocol> transitionHandler;

@end
