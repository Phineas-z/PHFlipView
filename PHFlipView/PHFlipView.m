//
//  PHFlipView.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "PHFlipView.h"
#import "UIView+Render.h"

#define FRONT_POSITION 1000//Use this position to make layer front most
#define MAX_FLIP_OFFSET 200
#define FLIP_DURATION_FOR_M_PI 1.
#define LAYER_CONTENTS_SCALE [UIScreen mainScreen].scale
#define MAX_BOUNCE_PROGRESS .3

@interface PHFlipView()<UIGestureRecognizerDelegate>
//Current View
@property (nonatomic, retain) UIView* currentView;
@property (nonatomic, retain) UIView* nextView;
@property (nonatomic, readonly) CGImageRef currentLayerContents;

//All layer container
@property (nonatomic, retain) CALayer* containerLayer;

//Flip card
@property (nonatomic, retain) CATransformLayer* flipCardLayer;

//Background layer
@property (nonatomic, retain) CALayer* currentBackgroundLayer;
@property (nonatomic, retain) CALayer* nextBackgroundLayer;

//Current flip transaction direction
@property (nonatomic) FLIP_DIRECTION currentFlipTransactionDirection;

//In animation state
@property (nonatomic) BOOL isInAnimation;

@end

@implementation PHFlipView

-(void)dealloc{
    self.currentView = nil;
    self.nextView = nil;
    
    self.containerLayer = nil;
    self.flipCardLayer = nil;
    self.currentBackgroundLayer = nil;
    self.nextBackgroundLayer = nil;
    
    [super dealloc];
}

//Overide set current view
-(void)setCurrentView:(UIView *)currentView{
    if (![_currentView isEqual:currentView]) {
        //Remove old one
        [_currentView removeFromSuperview];
        
        //
        _currentView = [currentView retain];
        _currentView.frame = self.bounds;
        
        //Add the new one
        [self addSubview:_currentView];
    }
}

-(id)initWithFrame:(CGRect)frame andInitialView:(UIView *)initialView
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        //
        self.currentView = initialView;
        
        //
        self.currentFlipTransactionDirection = FLIP_NONE;
        
        //
        UIPanGestureRecognizer* panGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)] autorelease];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

#pragma mark - Flip process
-(void)initialFlipWithDirection:(FLIP_DIRECTION)direction{
    //
    self.currentFlipTransactionDirection = direction;
    //
    self.nextView = [self fetchNextViewWithDirection:direction];
    
    //Initial all widgets
    self.containerLayer = [CALayer layer];
    self.containerLayer.frame = self.bounds;
    
    self.flipCardLayer = [CATransformLayer layer];
    CALayer* frontLayer = [CALayer layer];
    CALayer* backLayer = [CALayer layer];
    
    self.currentBackgroundLayer = [CALayer layer];
    self.nextBackgroundLayer = [CALayer layer];
    
    //Set flipCardLayer
    self.flipCardLayer.anchorPoint = [self anchorPointForFlipContainerWithDirection:direction];
    self.flipCardLayer.frame = [self frameForFlipContainerWithDirection:direction];
    self.flipCardLayer.zPosition = FRONT_POSITION;
    
    //Set front and back layer
    id currentLayerContents = (id)self.currentLayerContents;
    id nextLayerContents = (id)[self nextLayerContentsWithDirection:direction];
    
    frontLayer.contents = currentLayerContents;
    frontLayer.frame = self.flipCardLayer.bounds;
    frontLayer.doubleSided = NO;//
    frontLayer.contentsGravity = [self gravityForFrontLayerWithDirection:direction];
    frontLayer.masksToBounds = YES;
    frontLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    backLayer.contents = nextLayerContents;
    backLayer.frame = self.flipCardLayer.bounds;
    backLayer.doubleSided = NO;//
    backLayer.contentsGravity = [self gravityForBackLayerWithDirection:direction];
    backLayer.transform = [self initialTransformForBackLayerWithDirection:direction];
    backLayer.masksToBounds = YES;
    backLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    //Set current and next background layer
    self.currentBackgroundLayer.contents = currentLayerContents;
    self.currentBackgroundLayer.frame = [self frameForCurrentBackgroundLayerWithDirection:direction];
    self.currentBackgroundLayer.contentsGravity = [self gravityForCurrentBackgroundLayerWithDirection:direction];
    self.currentBackgroundLayer.masksToBounds = YES;
    self.currentBackgroundLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    self.nextBackgroundLayer.contents = nextLayerContents;
    self.nextBackgroundLayer.frame = [self frameForNextBackgroundLayerWithDirection:direction];
    self.nextBackgroundLayer.contentsGravity = [self gravityForNextBackgroundLayerWithDirection:direction];
    self.nextBackgroundLayer.masksToBounds = YES;
    self.nextBackgroundLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    //Compose these widgets    
    [self.containerLayer addSublayer:self.currentBackgroundLayer];
    [self.containerLayer addSublayer:self.nextBackgroundLayer];
    
    [self.flipCardLayer addSublayer:frontLayer];
    [self.flipCardLayer addSublayer:backLayer];
    
    [self.containerLayer addSublayer:self.flipCardLayer];
    
    [self.layer addSublayer:self.containerLayer];
}

-(void)flipCardDidDragToOffset:(CGFloat)offset{
    
    float flipProgress = [self flipProgressWithGestureOffset:offset andDirection:self.currentFlipTransactionDirection];
    
    self.flipCardLayer.transform = [self flipCardTransformWithDirection:self.currentFlipTransactionDirection andProgress:flipProgress];    
}

-(void)flipCardDidEndDraggingWithCurrentOffset:(CGFloat)offset{
    float currentProgress = [self flipProgressWithGestureOffset:offset andDirection:self.currentFlipTransactionDirection];
    
    BOOL flipToNextPage;
    CATransform3D endTransform;
    float duration;

    //Get end transform corresponding current flip transaction
    if (currentProgress < 0.5) {
        flipToNextPage = NO;
        endTransform = [self flipCardTransformWithDirection:self.currentFlipTransactionDirection andProgress:0];
        duration = currentProgress * FLIP_DURATION_FOR_M_PI;
    }else{
        flipToNextPage = YES;
        endTransform = [self flipCardTransformWithDirection:self.currentFlipTransactionDirection andProgress:1];
        duration = ( 1. - currentProgress ) * FLIP_DURATION_FOR_M_PI;
    }
    
    self.isInAnimation = YES;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setCompletionBlock:^{        
        if (flipToNextPage) {
            [self presentNextView];
        }else{
            [self cancelFlipToNextPage];
        }
        
        //End the flip transaction
        [self.containerLayer removeFromSuperlayer];
        self.isInAnimation = NO;
    }];
    
    self.flipCardLayer.transform = endTransform;
    
    [CATransaction commit];
}

-(void)presentNextView{
    //Set new current view
    self.currentView = self.nextView;
    self.nextView = nil;
    
    //Notify delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(flipView:didFlipToNewViewWithDirection:)]) {
        [self.delegate flipView:self didFlipToNewViewWithDirection:self.currentFlipTransactionDirection];
    }
}

-(void)cancelFlipToNextPage{
    //Notify delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(flipView:cancelFlipToNewViewWithDirection:)]) {
        [self.delegate flipView:self cancelFlipToNewViewWithDirection:self.currentFlipTransactionDirection];
    }
}

#pragma mark - Utils
//Flip container
-(CGRect)frameForFlipContainerWithDirection:(FLIP_DIRECTION)direction{
    CGRect frame = CGRectZero;
    
    switch (direction) {
        case FLIP_UP:
            frame = CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_DOWN:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        default:
            break;
    }
    
    return frame;
}

-(CGPoint)anchorPointForFlipContainerWithDirection:(FLIP_DIRECTION)direction{
    CGPoint anchorPoint = CGPointZero;

    switch (direction) {
        case FLIP_UP:
            anchorPoint = CGPointMake(0.5, 0);
            break;
            
        case FLIP_DOWN:
            anchorPoint = CGPointMake(0.5, 1);
            break;
            
        default:
            break;
    }
    
    return anchorPoint;
}

//Content to load
-(NSString*)gravityForFrontLayerWithDirection:(FLIP_DIRECTION)direction{
    switch (direction) {
        case FLIP_UP:
            return kCAGravityTop;
            break;
            
        case FLIP_DOWN:
            return kCAGravityBottom;
            break;
            
        default:
            return kCAGravityCenter;
            break;
    }
}

-(NSString*)gravityForBackLayerWithDirection:(FLIP_DIRECTION)direction{
    switch (direction) {
        case FLIP_UP:
            return kCAGravityBottom;
            break;
            
        case FLIP_DOWN:
            return kCAGravityTop;
            break;
            
        default:
            return kCAGravityCenter;
            break;
    }
}

-(NSString*)gravityForCurrentBackgroundLayerWithDirection:(FLIP_DIRECTION)direction{
    return [self gravityForBackLayerWithDirection:direction];
}

-(NSString*)gravityForNextBackgroundLayerWithDirection:(FLIP_DIRECTION)direction{
    return [self gravityForFrontLayerWithDirection:direction];
}

//Background layer
-(CGRect)frameForCurrentBackgroundLayerWithDirection:(FLIP_DIRECTION)direction{
    CGRect frame = CGRectZero;
    
    switch (direction) {
        case FLIP_UP:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_DOWN:
            frame = CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        default:
            break;
    }
    
    return frame;
}

-(CGRect)frameForNextBackgroundLayerWithDirection:(FLIP_DIRECTION)direction{
    CGRect frame = CGRectZero;
    
    switch (direction) {
        case FLIP_UP:
            frame = CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_DOWN:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        default:
            break;
    }
    
    return frame;
}

//Contents to load
-(CGImageRef)currentLayerContents{
    return [self.currentView imageByRenderingView].CGImage;
}

-(CGImageRef)nextLayerContentsWithDirection:(FLIP_DIRECTION)direction{
    if (self.nextView) {
        return [self.nextView imageByRenderingView].CGImage;
    }
    
    return NULL;
}

//Initial transform for back layer
-(CATransform3D)initialTransformForBackLayerWithDirection:(FLIP_DIRECTION)direction{
    CATransform3D transform = CATransform3DIdentity;
    
    switch (direction) {
        case FLIP_UP:
        case FLIP_DOWN:
            transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
            break;
            
        default:
            break;
    }
    
    return transform;
}

//Flip card transform with progress
-(CATransform3D)flipCardTransformWithDirection:(FLIP_DIRECTION)direction andProgress:(float)progress{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1. / 2500.;
    
    switch (direction) {
        case FLIP_UP:
            transform = CATransform3DRotate(transform, progress*M_PI, 1, 0, 0);
            break;
            
        case FLIP_DOWN:
            transform = CATransform3DRotate(transform, -progress*M_PI, 1, 0, 0);
            break;
            
        default:
            break;
    }
    
    return transform;
}

//Flip progress with gesture offset and direction
-(float)flipProgressWithGestureOffset:(CGFloat)offset andDirection:(FLIP_DIRECTION)direction{
    if (self.currentFlipTransactionDirection == FLIP_UP) {
        offset = -offset;
    }
    
    CGFloat currentOffset = MAX( MIN(offset, MAX_FLIP_OFFSET), 0 );
    
    float progress = currentOffset / MAX_FLIP_OFFSET;
    
    if (self.dataSource
        && [self.dataSource respondsToSelector:@selector(flipView:shouldFlipToDirection:)]
        && ![self.dataSource flipView:self shouldFlipToDirection:0]) {
        progress = MAX_BOUNCE_PROGRESS;
    }
    
    return progress;
}

-(UIView*)fetchNextViewWithDirection:(FLIP_DIRECTION)direction{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(flipView:nextViewForFlipDirection:)]) {
        UIView* nextView = [self.dataSource flipView:self nextViewForFlipDirection:direction];
        
        return nextView;
    }
    
    return nil;
}

#pragma mark - Handle Gesture
-(void)pan:(UIPanGestureRecognizer*)recognizer{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            
            [self initialFlipWithDirection: [recognizer translationInView:self].y > 0 ? FLIP_DOWN : FLIP_UP];
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            [self flipCardDidDragToOffset:[recognizer translationInView:self].y];
        
            break;
            
        case UIGestureRecognizerStateEnded:
            
            [self flipCardDidEndDraggingWithCurrentOffset:[recognizer translationInView:self].y];
            
            break;
            
        default:
            break;
    }
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return !self.isInAnimation;
}

@end
