//
//  CoverView.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-17.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "CoverView.h"

@implementation CoverView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //Add background
        UIImageView* backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cover_image.jpg"]] autorelease];
        backgroundView.frame = self.bounds;
        [self addSubview:backgroundView];
        
        //
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(250, 300, 30, 20);
        button.backgroundColor = [UIColor colorWithRed:139./255. green:131./255. blue:120./255. alpha:.5];
        [button setTitle:@"赞" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:button];
    }
    return self;
}

-(void)buttonClicked:(UIButton*)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://weibo.com/republiclue"]];
}

@end
