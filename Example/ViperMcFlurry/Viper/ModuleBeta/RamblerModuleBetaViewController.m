//
//  RamblerModuleBetaViewController.m
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import "RamblerModuleBetaViewController.h"
#import "RamblerModuleBetaViewOutput.h"
#import <ViperMcFlurryX/ViperMcFlurry.h>

@interface RamblerModuleBetaViewController()

@end

@implementation RamblerModuleBetaViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self.output setupView];
}

- (void)setExampleString:(NSString *)exampleString {
    self.exampleStringLabel.text = exampleString;
}

- (IBAction)goBack:(id)sender {
    [self.output didClickBack];
}

- (IBAction)goBackAnimated:(id)sender {
    [self.output didClickBackAnimated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
}

@end
