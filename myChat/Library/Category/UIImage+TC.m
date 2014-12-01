//
//  UIImage+TC.m
//  vChat
//
//  Created by apple on 14-11-24.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "UIImage+TC.h"

@implementation UIImage (TC)

#pragma mark 可以自由拉伸的图片
+ (UIImage *)resizedImage:(NSString *)imgName
{
    return [self resizedImage:imgName xPos:0.5 yPos:0.5];
}

+ (UIImage *)resizedImage:(NSString *)imgName xPos:(CGFloat)xPos yPos:(CGFloat)yPos
{
    UIImage *image = [UIImage imageNamed:imgName];
    return [image stretchableImageWithLeftCapWidth:image.size.width * xPos topCapHeight:image.size.height * yPos];
}

@end
