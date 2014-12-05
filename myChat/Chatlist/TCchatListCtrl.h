//
//  TCchatListCtrl.h
//  vChat
//
//  Created by apple on 14/11/27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

#import "XMPPFramework.h"

@interface TCchatListCtrl : BaseViewController

@property (nonatomic, strong) XMPPJID *jid;
@property (nonatomic, strong) UIImage *bareImage;
@property (nonatomic, strong) UIImage *myImage;

@end
