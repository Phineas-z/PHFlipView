//
//  PHFlipView.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "PHFlipView.h"
#import "UIView+Render.h"

#define FRONT_POSITION 1000 //Use this position to make layer front most
#define MAX_FLIP_OFFSET 200 //Flip touch offset range [0, MAX_FLIP_OFFSET]
#define FLIP_DURATION_FOR_M_PI 1. //Flip duration for M_PI
#define MAX_BOUNCE_PROGRESS .3 //When there is no next page, can only flip less than 30% of M_PI
#define LAYER_CONTENTS_SCALE [UIScreen mainScreen].scale

@interface PHFlipView()<UIGestureRecognizerDelegate>
//View and render image
@property (nonatomic, retain) UIView* currentView;
@property (nonatomic, retain) UIView* nextView;
@property (nonatomic) CGImageRef currentViewImage;
@property (nonatomic) CGImageRef nextViewImage;

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

//Can flip to next page
@property (nonatomic) BOOL canFlipToNextPage;

@end

@implementation PHFlipView

#pragma mark - Life circle
-(void)dealloc{
    self.currentView = nil;
    self.nextView = nil;
    self.backgroundView = nil;
    
    self.containerLayer = nil;
    self.flipCardLayer = nil;
    self.currentBackgroundLayer = nil;
    self.nextBackgroundLayer = nil;
    
    [super dealloc];
}

-(id)initWithFrame:(CGRect)frame andInitialView:(UIView *)initialView
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //Default background view
        UIView* backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
        backgroundView.backgroundColor = [UIColor whiteColor];
        self.backgroundView = backgroundView;
        
        //Default flip mode is vertical
        self.enableVerticalFlip = YES;
        
        self.currentView = initialView;
        
        self.currentFlipTransactionDirection = FLIP_NONE;
        
        //
        UIPanGestureRecognizer* panGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)] autorelease];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
        
    }
    return self;
}

#pragma mark - Handle Gesture
-(void)pan:(UIPanGestureRecognizer*)recognizer{
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            
            [self initFlipWithTouchOffset:[recognizer translationInView:self]];
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            [self flipCardDidDragToOffset:[recognizer translationInView:self]];
            
            break;
            
        case UIGestureRecognizerStateEnded:
            
            [self flipCardDidEndDraggingWithCurrentOffset:[recognizer translationInView:self]];
            
            break;
            
        default:
            break;
    }
}

#pragma mark - Flip process
//Init flip
-(void)initFlipWithTouchOffset:(CGPoint)offset{
    //Determine flip direction
    self.currentFlipTransactionDirection = [self flipDirectionWithInitialTouchOffset:offset];
    
    //Prepare render content and state variable for flip action
    [self prepareForFlip];
    
    //Set up animate layer
    [self setUpFlipLayers];
}

//Prepare flip
-(void)prepareForFlip{
    //Determine can flip to next page
    self.canFlipToNextPage = NO;
    if ([self.dataSource respondsToSelector:@selector(flipView:shouldFlipToDirection:)]) {
        self.canFlipToNextPage = [self.dataSource flipView:self shouldFlipToDirection:self.currentFlipTransactionDirection];
    }
    
    //Fetch next view
    if (self.canFlipToNextPage && [self.dataSource respondsToSelector:@selector(flipView:nextViewForFlipDirection:)]) {
        self.nextView = [self.dataSource flipView:self nextViewForFlipDirection:self.currentFlipTransactionDirection];
    }else{
        self.nextView = self.backgroundView;
    }
    
    //Get layer content
    self.currentViewImage = [self.currentView imageByRenderingView].CGImage;
    self.nextViewImage = [self.nextView imageByRenderingView].CGImage;
}

//Set up trick layers
-(void)setUpFlipLayers{    
    //Initial all widgets
    self.containerLayer = [CALayer layer];
    self.containerLayer.frame = self.bounds;
    
    self.flipCardLayer = [CATransformLayer layer];
    CALayer* frontLayer = [CALayer layer];
    CALayer* backLayer = [CALayer layer];
    
    self.currentBackgroundLayer = [CALayer layer];
    self.nextBackgroundLayer = [CALayer layer];
    
    //Set flipCardLayer
    self.flipCardLayer.anchorPoint = [self anchorPointForFlipContainerLayer];
    self.flipCardLayer.frame = [self frameForFlipContainerLayer];
    self.flipCardLayer.zPosition = FRONT_POSITION;
    
    //Set front and back layer
    id currentLayerContents = (id)self.currentViewImage;
    id nextLayerContents = (id)self.nextViewImage;
    
    frontLayer.contents = currentLayerContents;
    frontLayer.frame = self.flipCardLayer.bounds;
    frontLayer.doubleSided = NO;//
    frontLayer.contentsGravity = [self gravityForFrontLayer];
    frontLayer.masksToBounds = YES;
    frontLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    backLayer.contents = nextLayerContents;
    backLayer.frame = self.flipCardLayer.bounds;
    backLayer.doubleSided = NO;//
    backLayer.contentsGravity = [self gravityForBackLayer];
    backLayer.transform = [self initialTransformForBackLayer];
    backLayer.masksToBounds = YES;
    backLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    //Set current and next background layer
    self.currentBackgroundLayer.contents = currentLayerContents;
    self.currentBackgroundLayer.frame = [self frameForCurrentBackgroundLayer];
    self.currentBackgroundLayer.contentsGravity = [self gravityForCurrentBackgroundLayer];
    self.currentBackgroundLayer.masksToBounds = YES;
    self.currentBackgroundLayer.contentsScale = LAYER_CONTENTS_SCALE;
    
    self.nextBackgroundLayer.contents = nextLayerContents;
    self.nextBackgroundLayer.frame = [self frameForNextBackgroundLayer];
    self.nextBackgroundLayer.contentsGravity = [self gravityForNextBackgroundLayer];
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

-(void)flipCardDidDragToOffset:(CGPoint)offset{
        
    self.flipCardLayer.transform = [self flipCardTransformWithProgress:[self flipProgressWithGestureOffset:offset]];
    
}

-(void)flipCardDidEndDraggingWithCurrentOffset:(CGPoint)offset{
    float currentProgress = [self flipProgressWithGestureOffset:offset];
    
    BOOL flipToNextPage;
    CATransform3D endTransform;
    float duration;

    //Get end transform corresponding current flip transaction
    if (currentProgress < 0.5) {
        flipToNextPage = NO;
        endTransform = [self flipCardTransformWithProgress:0];
        duration = currentProgress * FLIP_DURATION_FOR_M_PI;
    }else{
        flipToNextPage = YES;
        endTransform = [self flipCardTransformWithProgress:1];
        duration = ( 1. - currentProgress ) * FLIP_DURATION_FOR_M_PI;
    }
    
    self.isInAnimation = YES;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setCompletionBlock:^{        
        if (flipToNextPage) {
            [self didFlipToNextView];
        }else{
            [self didFlipBack];
        }
        //End the flip transaction
        [self.containerLayer removeFromSuperlayer];
        self.isInAnimation = NO;
    }];
    
    self.flipCardLayer.transform = endTransform;
    
    [CATransaction commit];
}

-(void)didFlipToNextView{
    //Set new current view
    self.currentView = self.nextView;
    self.nextView = nil;
    
    //Notify delegate
    if ([self.delegate respondsToSelector:@selector(flipView:didFlipToNewViewWithDirection:)]) {
        [self.delegate flipView:self didFlipToNewViewWithDirection:self.currentFlipTransactionDirection];
    }
}

-(void)didFlipBack{
    //Notify delegate
    if ([self.delegate respondsToSelector:@selector(flipView:cancelFlipToNewViewWithDirection:)]) {
        [self.delegate flipView:self cancelFlipToNewViewWithDirection:self.currentFlipTransactionDirection];
    }
}

#pragma mark - Utils
//Flip container
-(CGRect)frameForFlipContainerLayer{
    CGRect frame = CGRectZero;
    
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            frame = CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_DOWN:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_LEFT:
            frame = CGRectMake(CGRectGetWidth(self.bounds)/2, 0, CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds));
            break;
            
        case FLIP_RIGHT:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds));
            break;
            
        default:
            break;
    }
    
    return frame;
}

-(CGPoint)anchorPointForFlipContainerLayer{
    CGPoint anchorPoint = CGPointZero;

    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            anchorPoint = CGPointMake(0.5, 0);
            break;
            
        case FLIP_DOWN:
            anchorPoint = CGPointMake(0.5, 1);
            break;
            
        case FLIP_LEFT:
            anchorPoint = CGPointMake(0, 0.5);
            break;
            
        case FLIP_RIGHT:
            anchorPoint = CGPointMake(1, 0.5);
            break;
            
        default:
            break;
    }
    
    return anchorPoint;
}

//Content gravity for layers
-(NSString*)gravityForFrontLayer{
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            return kCAGravityTop;
            break;
            
        case FLIP_DOWN:
            return kCAGravityBottom;
            break;
            
        case FLIP_LEFT:
            return kCAGravityRight;
            break;
            
        case FLIP_RIGHT:
            return kCAGravityLeft;
            break;
            
        default:
            return kCAGravityCenter;
            break;
    }
}

-(NSString*)gravityForBackLayer{
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            return kCAGravityBottom;
            break;
            
        case FLIP_DOWN:
            return kCAGravityTop;
            break;
            
        case FLIP_LEFT:
            return kCAGravityLeft;
            break;
            
        case FLIP_RIGHT:
            return kCAGravityRight;
            break;
            
        default:
            return kCAGravityCenter;
            break;
    }
}

-(NSString*)gravityForCurrentBackgroundLayer{
    return [self gravityForBackLayer];
}

-(NSString*)gravityForNextBackgroundLayer{
    return [self gravityForFrontLayer];
}

//Frame for layers
-(CGRect)frameForCurrentBackgroundLayer{
    CGRect frame = CGRectZero;
    
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_DOWN:
            frame = CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)/2);
            break;
            
        case FLIP_LEFT:
            frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds));
            break;
            
        case FLIP_RIGHT:
            frame = CGRectMake(CGRectGetWidth(self.bounds)/2, 0, CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds));
            break;
            
        default:
            break;
    }
    
    return frame;
}

-(CGRect)frameForNextBackgroundLayer{
    return [self frameForFlipContainerLayer];
}

//Progress and transform
//Initial transform for back layer
-(CATransform3D)initialTransformForBackLayer{
    CATransform3D transform = CATransform3DIdentity;
    
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
        case FLIP_DOWN:
            transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
            break;
            
        case FLIP_LEFT:
        case FLIP_RIGHT:
            transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
            
        default:
            break;
    }
    
    return transform;
}

//Flip card transform with progress
-(CATransform3D)flipCardTransformWithProgress:(float)progress{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1. / 2500.;
    
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            transform = CATransform3DRotate(transform, progress*M_PI, 1, 0, 0);
            break;
            
        case FLIP_DOWN:
            transform = CATransform3DRotate(transform, -progress*M_PI, 1, 0, 0);
            break;
            
        case FLIP_LEFT:
            transform = CATransform3DRotate(transform, -progress*M_PI, 0, 1, 0);
            break;
            
        case FLIP_RIGHT:
            transform = CATransform3DRotate(transform, progress*M_PI, 0, 1, 0);
            break;
            
        default:
            break;
    }
    
    return transform;
}

//Flip progress with gesture offset and direction
-(float)flipProgressWithGestureOffset:(CGPoint)offset{
    CGFloat validOffsetValue = 0.;
    
    switch (self.currentFlipTransactionDirection) {
        case FLIP_UP:
            validOffsetValue = -offset.y;
            break;
            
        case FLIP_DOWN:
            validOffsetValue = offset.y;
            break;
            
        case FLIP_LEFT:
            validOffsetValue = -offset.x;
            break;
            
        case FLIP_RIGHT:
            validOffsetValue = offset.x;
            break;
            
        default:
            break;
    }
    
    CGFloat currentOffset = MAX( MIN(validOffsetValue, MAX_FLIP_OFFSET), 0 );
    
    float progress = currentOffset / MAX_FLIP_OFFSET;
    
    if (!self.canFlipToNextPage) {
        progress = MIN(progress, MAX_BOUNCE_PROGRESS);
    }
    
    return progress;
}

//Determine flip direction
-(FLIP_DIRECTION)flipDirectionWithInitialTouchOffset:(CGPoint)offset{
    
    if (self.enableHorizontalFlip && self.enableHorizontalFlip) {
        
        if (fabs(offset.x) > fabs(offset.y)) {
            //Horizontal flip
            return offset.x>0 ? FLIP_RIGHT : FLIP_LEFT;
        }else{
            //Vertical flip
            return offset.y>0 ? FLIP_DOWN : FLIP_UP;
        }
        
    }else if (self.enableHorizontalFlip){
        //Horizontal flip
        return offset.x>0 ? FLIP_RIGHT : FLIP_LEFT;
        
    }else if (self.enableVerticalFlip){
        //Vertical flip
        return offset.y>0 ? FLIP_DOWN : FLIP_UP;
        
    }

    return FLIP_NONE;
}

//Overide set current view
-(void)setCurrentView:(UIView *)currentView{
    if (![_currentView isEqual:currentView]) {
        //Remove old one
        [_currentView removeFromSuperview];
        
        //
        [_currentView release];
        _currentView = [currentView retain];
        _currentView.frame = self.bounds;
        
        //Add the new one
        [self addSubview:_currentView];
    }
}

#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return !self.isInAnimation;
}

@end
