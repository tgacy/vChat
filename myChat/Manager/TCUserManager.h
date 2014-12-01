//
//  TCUserManager.h
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCUser.h"
#import "Common.h"

@interface TCUserManager : NSObject

//工厂方法
single_interface(TCUserManager)

//当前用户
@property (strong, nonatomic) TCUser *user;

//重置用户
- (void)resetUser;
//判断是否能登录
- (BOOL)isLogin;


//存储消息列表
- (void)saveChatlistWitharray:(NSMutableArray *)array andDictionary:(NSMutableDictionary*)dictionary;

//获取消息列表
- (NSMutableDictionary *)getChatlistDictionary;
- (NSMutableArray *)getChatlistArray;

@end
