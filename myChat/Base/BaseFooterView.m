//
//  BaseFooterView.m
//  vChat
//
//  Created by apple on 14-11-28.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "BaseFooterView.h"

#import "UIImage+TC.h"

@implementation BaseFooterView

+ (instancetype)footerViewWithImage:(NSString *)image highlightImage:(NSString *)hightlightImage title:(NSString *)title target:(id)target action:(SEL)action height:(CGFloat)height
{
    BaseFooterView *button = [[self class] buttonWithType:UIButtonTypeCustom];
    
    [button setImage:[UIImage resizedImage:image] forState:UIControlStateNormal];
    [button setImage:[UIImage resizedImage:hightlightImage] forState:UIControlStateHighlighted];
    
    // tableFooterView的宽度是不需要设置。默认就是整个tableView的宽度
    button.bounds = CGRectMake(0, 0, 0, height);
    
    // 4.设置按钮文字
    [button setTitle:title forState:UIControlStateNormal];
    
    // 5.添加点击事件
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

//设置图片位置
- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGFloat x = kFooterCellMagin;
    CGFloat y = 0;
    CGFloat width = contentRect.size.width - 2 * x;
    CGFloat height = contentRect.size.height;
    return CGRectMake(x, y, width, height);
}

@end
