//
//  RamblerModuleBetaPresenter.m
//  ViperMcFlurry
//
//  Copyright (c) 2015 Rambler DS. All rights reserved.
//

#import "RamblerModuleBetaPresenter.h"
#import "RamblerModuleBetaViewInput.h"
#import "RamblerModuleBetaInteractorInput.h"
#import "RamblerModuleBetaRouterInput.h"

@interface RamblerModuleBetaPresenter()

@property (nonatomic,strong) NSString* exampleString;

@end

@implementation RamblerModuleBetaPresenter

#pragma mark - RamblerModuleBetaInput

- (void)configureWithExampleString:(NSString*)exampleString {
    self.exampleString = exampleString;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.moduleOutput betaModuleDidChangeSomething];
    });
}

#pragma mark - RamblerModuleBetaViewOutput

- (void)setupView {
    [self.view setExampleString:self.exampleString];
}

- (void)didClickBack {
    [self.router removeModule:NO];
}

- (void)didClickBackAnimated {
    [self.router removeModule:YES];
}

#pragma mark - RamblerModuleBetaInteractorOutput

@end
