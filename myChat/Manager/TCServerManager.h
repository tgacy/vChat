//
//  TCServerManager.h
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPFramework.h"

#import "Common.h"
#import "TCUserManager.h"
#import "TCMessage.h"
#import "TCGroup.h"

@interface TCServerManager : NSObject

//开始连接和完成连接的动作
@property (nonatomic, copy) void (^willStartRequest)(TCServerState state);
@property (nonatomic, copy) void (^didFinishedRequest)(TCServerState state, TCRequestErrorCode code);

@property (strong, nonatomic) XMPPStream *xmppStream;
@property (strong, nonatomic, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;             //后面查找好友时判断好友是否已存在需要用到;
@property (nonatomic, strong)XMPPRoster  *xmppRoster;       //通讯录

//传输文件socket数组
@property (strong, nonatomic) NSMutableArray *socketList;

//接收文件
@property (strong, nonatomic) XMPPIncomingFileTransfer *incomeingFile;
//发送文件
@property (strong, nonatomic) XMPPOutgoingFileTransfer *outgoingFile;

//工厂方法
single_interface(TCServerManager)

- (void)connect;    //连接服务器
- (void)disconnect; //断开服务器连接

- (void)login:(TCUser *)user; //登录服务器
- (void)logout;             //退出登录

- (void)online;             //上线
- (void)offline;            //下线

- (void)registerUser:(TCUser *)user;      //用户注册

- (void)fetchFriendsList;           //获取好友列表
- (void)addFriend:(TCUser *)user;     //添加好友
- (void)removeFriend:(TCUser *)user;  //移除好友
- (void)acceptFriend:(TCUser *)user;  //接受好友邀请

- (void)sendMessage:(TCMessage *)message toUser:(TCUser *)user;     //给用户发送消息
- (void)sendMessage:(TCMessage *)message toGroup:(TCGroup *)group;  //给组发送消息

- (XMPPvCardAvatarModule *)avatarModule;    //头像模块;
- (XMPPvCardTempModule *)vCardModule;       //电子名片模块
- (NSManagedObjectContext *)rosterContext;  //好友存储
- (NSManagedObjectContext *)vCardContext;   //名片存储
- (NSManagedObjectContext *)messageContext; //消息存储

@end






