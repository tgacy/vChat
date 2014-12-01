//
//  TCFriendHeadView.m
//  vChat
//
//  Created by apple on 14-11-24.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCFriendHeadView.h"

@implementation TCFriendHeadView

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        UILabel *nickName = [[UILabel alloc] init];
        nickName.textColor = [UIColor darkTextColor];
        nickName.font = [UIFont systemFontOfSize:17];
        [self addSubview:nickName];
        _nickNameLabel = nickName;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _nickNameLabel.frame = CGRectMake(kHeadCellMagin + CGRectGetMaxX(self.headImg.frame), CGRectGetMaxY(self.jidStrLabel.frame), self.jidStrLabel.frame.size.width, self.jidStrLabel.frame.size.height);
}

@end
