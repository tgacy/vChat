//
//  BaseHeadInfoView.h
//  vChat
//
//  Created by apple on 14-11-26.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kHeadCellMagin 20.0

@interface BaseHeadInfoView : UIView

@property (weak, nonatomic) UIImageView *headImg;
@property (weak, nonatomic) UILabel *nameLabel;
@property (weak, nonatomic) UILabel *jidStrLabel;

@end
