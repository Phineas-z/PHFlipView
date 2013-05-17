//
//  PHDarkLayer.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-17.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "PHDarkLayer.h"
#import <QuartzCore/QuartzCore.h>

@interface PHDarkLayer()
@property (nonatomic, retain) CALayer* overlay;
@end

@implementation PHDarkLayer

-(void)dealloc{
    self.overlay = nil;
    
    [super dealloc];
}

-(void)setDarkness:(float)darkness{
    if (darkness < 0.) {
        darkness = 0.;
    }else if (darkness > 1.){
        darkness = 1.;
    }
    
    //
    if (!self.overlay) {
        self.overlay = [CALayer layer];
        self.overlay.backgroundColor = [UIColor blackColor].CGColor;
        self.overlay.frame = self.bounds;
        [self addSublayer:self.overlay];
    }
    
    self.overlay.opacity = darkness;
}

@end
