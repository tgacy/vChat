//
//  FriendCell.m
//  营内聊
//
//  Created by apple on 14-11-19.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCFriendCell.h"
#import "TCServerManager.h"

@interface TCFriendCell ()

@property (weak, nonatomic) IBOutlet UIImageView *headImage;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *namelabel;

@end

@implementation TCFriendCell

- (void)awakeFromNib
{
    _namelabel.text = @"张三";
    _descLabel.text = @"hahahaha";
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

//设置选中时的行为
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if(selected){
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Friends_cell_sel"]];
    }
}

#pragma mark - 设置好友信息
- (void)setFriendInfo:(XMPPUserCoreDataStorageObject *)friendInfo
{
    _friendInfo = friendInfo;
    //设置昵称
    _namelabel.text = friendInfo.jid.user;
    //设置状态信息
    _descLabel.text = [friendInfo.subscription isEqualToString:@"both"] ? @"" : @"等待对方验证";
    
    //设置头像
    if (friendInfo.photo != nil)
    {
        _headImage.image = friendInfo.photo;
    }
    else
    {
        //获取头像数据
        NSData *photoData = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:friendInfo.jid];
        
        if (photoData != nil)
            _headImage.image = [UIImage imageWithData:photoData];
        else
            _headImage.image = [UIImage imageNamed:kDefaultHeadImage];
    }
}

@end
