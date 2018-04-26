//
//  RamblerModuleBetaViewController.h
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RamblerModuleBetaViewInput.h"
#import <ViperMcFlurryX/ViperMcFlurry.h>

@protocol RamblerViperModuleConfiguratorProtocol;
@protocol RamblerModuleBetaViewOutput;

@interface RamblerModuleBetaViewController : UIViewController <RamblerModuleBetaViewInput,RamblerViperModuleTransitionHandlerProtocol>

@property (nonatomic, strong) id<RamblerModuleBetaViewOutput> output;
@property (nonatomic, weak)   id<RamblerViperModuleConfiguratorProtocol> moduleConfigurator;

@property (nonatomic, strong) IBOutlet UILabel *exampleStringLabel;
@property (nonatomic, strong) IBOutlet UIButton *backButton;

- (IBAction)goBack:(id)sender;

@end

