//
//  FriendCell.h
//  营内聊
//
//  Created by apple on 14-11-19.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"

@interface TCFriendCell : UITableViewCell

@property (strong, nonatomic) XMPPUserCoreDataStorageObject *friendInfo;

@end
