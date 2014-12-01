//
//  TCChatViewController.h
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface TCChatViewController : BaseViewController

// 对话方JID
@property (strong, nonatomic) NSString *bareJidStr;
// 对话方头像
@property (strong, nonatomic) UIImage *bareImage;
// 我的头像
@property (strong, nonatomic) UIImage *myImage;

@end
