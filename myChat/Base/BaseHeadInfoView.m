//
//  TCFriendHeadView.m
//  vChat
//
//  Created by apple on 14-11-24.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "BaseHeadInfoView.h"

@implementation BaseHeadInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        UIImageView *head = [[UIImageView alloc] init];
        [self addSubview:head];
        _headImg = head;
        
        UILabel *name = [[UILabel alloc] init];
        name.textColor = [UIColor blackColor];
        name.font = [UIFont systemFontOfSize:20];
        _nameLabel = name;
        [self addSubview:name];
        
        UILabel *jidStr = [[UILabel alloc] init];
        jidStr.textColor = [UIColor darkTextColor];
        jidStr.font = [UIFont systemFontOfSize:17];
        [self addSubview:jidStr];
        _jidStrLabel = jidStr;
    }
    return self;
}

#pragma mark - 布局子视图
- (void)layoutSubviews
{
    CGRect rect = self.bounds;
    
    _headImg.frame = CGRectMake(kHeadCellMagin, kHeadCellMagin, kDefaultHeadWidth, kDefaultHeadHeight);
    
    CGFloat x = CGRectGetMaxX(_headImg.frame) + kHeadCellMagin;
    CGFloat width = rect.size.width - x;
    CGFloat height = _headImg.frame.size.height / (self.subviews.count - 1);
    
    _nameLabel.frame = CGRectMake(x, kHeadCellMagin, width, height);
    
    _jidStrLabel.frame = CGRectMake(x, CGRectGetMaxY(_nameLabel.frame), width, height);
}

@end
