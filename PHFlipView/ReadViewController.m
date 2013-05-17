//
//  ReadViewController.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "ReadViewController.h"
#import "PHFlipView.h"
#import "CoverView.h"
#import "ContentView.h"

@interface ReadViewController()<PHFlipViewDataSource, PHFlipViewDelegate>
@property (nonatomic, retain) PHFlipView* containerView;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger maxPage;
@end

@implementation ReadViewController

-(void)dealloc{
    self.containerView = nil;
    
    [super dealloc];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    //CoverView for initial
    CoverView* coverView = [[CoverView alloc] initWithFrame:self.view.bounds];
    
    //Add flip container view
    self.containerView = [[PHFlipView alloc] initWithFrame:self.view.bounds andInitialView:coverView];
    self.containerView.enableVerticalFlip = YES;
    self.containerView.enableHorizontalFlip = YES;
    self.containerView.dataSource = self;
    self.containerView.delegate = self;
    [self.view addSubview:self.containerView];
}

#pragma mark - PHFlipViewDataSource
-(BOOL)flipView:(PHFlipView*)flipView shouldFlipToDirection:(FLIP_DIRECTION)direction{
    if ( self.currentPage == 0 && ( direction == FLIP_DOWN || direction == FLIP_RIGHT) ) {
        return NO;
    }
    
    return YES;
}

-(UIView *)flipView:(PHFlipView*)flipView nextViewForFlipDirection:(FLIP_DIRECTION)direction{
    switch (direction) {
        case FLIP_DOWN:
        case FLIP_RIGHT:
            //Flip to previous page
            if (self.currentPage == 1) {
                return [[[CoverView alloc] initWithFrame:self.view.bounds] autorelease];
            }else{
                return [ContentView contentViewForPage:self.currentPage-2 withFrame:self.view.bounds];
            }
            break;
            
        case FLIP_UP:
        case FLIP_LEFT:
            //Flip to succeeding page
            return [ContentView contentViewForPage:self.currentPage withFrame:self.view.bounds];
            break;
            
        default:
            return nil;
            break;
    }    
}

#pragma mark - PHFlipViewDelegate
-(void)flipView:(PHFlipView *)flipView didFlipToNewViewWithDirection:(FLIP_DIRECTION)direction{
    if (direction == FLIP_UP || direction == FLIP_LEFT) {
        self.currentPage++;
    }else if (direction == FLIP_DOWN || direction == FLIP_RIGHT){
        self.currentPage--;
    }
}

-(void)flipView:(PHFlipView *)flipView cancelFlipToNewViewWithDirection:(FLIP_DIRECTION)direction{
    
}

@end
