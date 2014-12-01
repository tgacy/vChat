//
//  BaseFooterView.h
//  vChat
//
//  Created by apple on 14-11-28.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kFooterCellMagin 20.0

@interface BaseFooterView : UIButton

+ (instancetype)footerViewWithImage:(NSString *)image highlightImage:(NSString *)hightlightImage title:(NSString *)title target:(id)target action:(SEL)action height:(CGFloat)height;

@end
