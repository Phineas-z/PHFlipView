//
//  ContentView.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-17.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "ContentView.h"
#import <QuartzCore/QuartzCore.h>
#import "PDFRendererView.h"

@implementation ContentView

- (id)initWithFrame:(CGRect)frame andPage:(NSInteger)page
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //Add pdf view
        UIView* pdfView = [self pdfViewForPage:page];
        pdfView.frame = self.bounds;
        [self addSubview:pdfView];
        
        //Add top bar
        UILabel* toolBar = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 44)] autorelease];
        toolBar.backgroundColor = [UIColor colorWithRed:139./255. green:131./255. blue:120./255. alpha:.5];
        toolBar.layer.borderWidth = 1.;
        toolBar.layer.borderColor = [UIColor blackColor].CGColor;
        toolBar.text = @"名侦探柯南";
        toolBar.userInteractionEnabled = YES;
        toolBar.textAlignment = NSTextAlignmentCenter;
        
        //
        UIButton* button = [UIButton buttonWithType:UIButtonTypeInfoDark];
        button.frame = CGRectMake(280, 10, 30, 20);
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        button.userInteractionEnabled = YES;
        [toolBar addSubview:button];
        
        [self addSubview:toolBar];
    }
    return self;
}

+(ContentView *)contentViewForPage:(NSInteger)page withFrame:(CGRect)frame{
    ContentView* contentView = [[[ContentView alloc] initWithFrame:frame andPage:page] autorelease];
    
    return contentView;
}

-(void)buttonClicked:(UIButton*)sender{
    UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"赞" message:@"您已赞了一个" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
    [alertView show];
}

//
-(UIView*)pdfViewForPage:(NSInteger)page{
    NSURL* urlForResource = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"conan" ofType:@"pdf"]];
    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef) CFBridgingRetain(urlForResource));
    
    PDFRendererView *result = [[PDFRendererView alloc] initWithFrame:self.bounds];
	result.pdfDocument = pdfDocument;
	result.pageNumber = page+1;
    
    CGPDFDocumentRelease(pdfDocument);
    CFBridgingRelease(urlForResource);
    
	return result;
}

@end
