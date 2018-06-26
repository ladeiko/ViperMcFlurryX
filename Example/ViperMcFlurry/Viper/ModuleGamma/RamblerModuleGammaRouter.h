//
//  RamblerModuleGammaRouter.h
//  ViperMcFlurry
//
//  Copyright (c) 2017 Rambler DS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ViperMcFlurryX/ViperMcFlurry.h>
#import "RamblerModuleGammaRouterInput.h"

@interface RamblerModuleGammaRouter : NSObject <RamblerModuleGammaRouterInput>

@property (nonatomic,weak) id<RamblerViperModuleTransitionHandlerProtocol> transitionHandler;

@end
