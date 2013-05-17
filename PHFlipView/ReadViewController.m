//
//  ReadViewController.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "ReadViewController.h"
#import "PHFlipView.h"
#import "PDFRendererView.h"

@interface ReadViewController()<PHFlipViewDataSource, PHFlipViewDelegate>
@property (nonatomic, retain) PHFlipView* containerView;
@property (nonatomic) NSInteger currentPage;
@end

@implementation ReadViewController

-(void)dealloc{
    self.containerView = nil;
    
    [super dealloc];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    //
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    //Add flip container view
    self.containerView = [[PHFlipView alloc] initWithFrame:self.view.bounds andInitialView:[self pdfViewForPage:0]];
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
    UIView* viewToShow = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    UIToolbar* toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewToShow.bounds), 30)] autorelease];
    
    switch (direction) {
        case FLIP_DOWN:
        case FLIP_RIGHT:
            [viewToShow addSubview:[self pdfViewForPage:self.currentPage-1]];
            break;
            
        case FLIP_UP:
        case FLIP_LEFT:
            [viewToShow addSubview:[self pdfViewForPage:self.currentPage+1]];
            break;
            
        default:
            break;
    }
    
    [viewToShow addSubview:toolbar];

    return viewToShow;
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

//
-(UIView*)pdfViewForPage:(NSInteger)page{
    NSURL* urlForResource = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ccrf" ofType:@"pdf"]];
    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef) CFBridgingRetain(urlForResource));
    
    PDFRendererView *result = [[PDFRendererView alloc] initWithFrame:self.view.bounds];
	result.pdfDocument = pdfDocument;
	result.pageNumber = page+1;
    
    CGPDFDocumentRelease(pdfDocument);
    CFBridgingRelease(urlForResource);
    
	return result;
}

@end
