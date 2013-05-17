//
//  PHFlipView.h
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    FLIP_NONE,
    FLIP_UP,
    FLIP_DOWN,
    FLIP_LEFT,
    FLIP_RIGHT
}FLIP_DIRECTION;

@protocol PHFlipViewDataSource;
@protocol PHFlipViewDelegate;
@interface PHFlipView : UIView

@property (nonatomic, retain) UIView* backgroundView;

@property (nonatomic) BOOL enableVerticalFlip;

@property (nonatomic) BOOL enableHorizontalFlip;

@property (nonatomic, assign) id<PHFlipViewDataSource> dataSource;

@property (nonatomic, assign) id<PHFlipViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame andInitialView:(UIView*)initialView;

@end

@protocol PHFlipViewDataSource <NSObject>
-(BOOL)flipView:(PHFlipView*)flipView shouldFlipToDirection:(FLIP_DIRECTION)direction;
-(UIView*)flipView:(PHFlipView*)flipView nextViewForFlipDirection:(FLIP_DIRECTION)direction;
@end

@protocol PHFlipViewDelegate <NSObject>
@optional
-(void)flipView:(PHFlipView*)flipView didFlipToNewViewWithDirection:(FLIP_DIRECTION)direction;
-(void)flipView:(PHFlipView*)flipView cancelFlipToNewViewWithDirection:(FLIP_DIRECTION)direction;
@end
