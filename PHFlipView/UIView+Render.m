//
//  UIView+Render.m
//  PHFlipView
//
//  Created by luyuanshuo on 13-5-15.
//  Copyright (c) 2013年 luyuanshuo. All rights reserved.
//

#import "UIView+Render.h"

@implementation UIView (Render)

//-(UIImage *)imageByRenderingView{
//    UIGraphicsBeginImageContext(self.bounds.size);
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    [self.layer renderInContext:context];
//    
//    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    
//    return image;
//}

- (UIImage *) imageByRenderingView {
    CGFloat oldAlpha = self.alpha;
    self.alpha = 1;
    UIGraphicsBeginImageContext(self.bounds.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    self.alpha = oldAlpha;
	return resultingImage;
}

@end
