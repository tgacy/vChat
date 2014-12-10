//
//  TCServerManager.m
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCServerManager.h"

@interface TCServerManager () <XMPPStreamDelegate, XMPPIncomingFileTransferDelegate>
{
    XMPPStream *_xmppStream;
    
    XMPPReconnect *_xmppReconnect;                //重连模块
    XMPPRoster  *_xmppRoster;                     //通讯录
    XMPPvCardAvatarModule *_xmppAvatarModule;     //头像模块
    XMPPvCardTempModule *_xmppvCardModule;        //电子身份模块
    XMPPMessageArchiving *_xmppMessageArchiving;  //消息
    XMPPRoom *_xmppRoom;                          //多人聊天
    
    TCUser *_user;                                //当前操作用户
    TCServerState _serverState;                   //当前状态
    
    XMPPPresence *_presence;       //到场消息
}

@end

@implementation TCServerManager

//单例实现
single_implementation(TCServerManager)

#pragma mark - 初始化
- (instancetype)init
{
    if(self = [super init]){
        //创建XMPP Stream
        _xmppStream = [[XMPPStream alloc] init];
        //设置服务器地址，如果没有设置，则通过JID获取服务器地址
        _xmppStream.hostName = kHostName;
        //设置代理，多播代理（可以设置多个代理对象）
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        //实例化socket数组
        _socketList = [NSMutableArray array];
        
        [self loadModules];
    }
    return self;
}

//加载模块
- (void)loadModules
{
    //重连模块
    _xmppReconnect = [[XMPPReconnect alloc] init];
    [_xmppReconnect activate:_xmppStream];
    
    //多人聊天，暂不添加
//    _xmppRoom = [[XMPPRoom alloc] init];
//    [_xmppRoom activate:_xmppStream];
    
    //使用CoreData管理通讯录（花名册）
    _xmppRosterStorage = [XMPPRosterCoreDataStorage sharedInstance];
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    
    _xmppRoster.autoFetchRoster = YES;  //自动获取通讯录
    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    [_xmppRoster activate:_xmppStream];
    
    //使用电子名片
    XMPPvCardCoreDataStorage *vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _xmppvCardModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardStorage];
    [_xmppvCardModule activate:_xmppStream];
    
    //头像
    _xmppAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardModule];
    [_xmppAvatarModule activate:_xmppStream];
    
    //消息
    XMPPMessageArchivingCoreDataStorage *messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:messageStorage];
    [_xmppMessageArchiving activate:_xmppStream];
    
    //接收文件
    _incomeingFile = [[XMPPIncomingFileTransfer alloc] init];
    [_incomeingFile activate:_xmppStream];
    [_incomeingFile addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

//卸载模块
- (void)unloadModules
{
    [_xmppReconnect deactivate];
    _xmppReconnect = nil;
    
    //[_xmppRoom deactivate];
    //_xmppRoom = nil;
    
    [_xmppRoster deactivate];
    _xmppRoster = nil;
    
    [_xmppvCardModule deactivate];
    _xmppvCardModule = nil;
    
    [_xmppAvatarModule deactivate];
    _xmppAvatarModule = nil;
    
    [_xmppMessageArchiving deactivate];
    _xmppMessageArchiving = nil;
    
    [_incomeingFile deactivate];
    [_incomeingFile removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    _incomeingFile = nil;
}

#pragma mark - 开始和结束请求动作
- (void)startRequest:(TCServerState)state
{
    if (_willStartRequest) {
        _willStartRequest(state);
    }
}

- (void)finishedRequest:(TCServerState)state errorCode:(TCRequestErrorCode)code
{
    if (_didFinishedRequest) {
        _didFinishedRequest(state, code);
    }
}

#pragma mark - 连接动作
//连接服务器
- (void)connectWithState:(TCServerState)state
{
    NSError *error;
    if(![_xmppStream connectWithTimeout:kTimeoutLength error:&error]) {
        MyLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        return;
    }
    
    //连接服务器，并设置为注册状态
    _serverState = state;
}

- (void)connect    //连接服务器
{
    _xmppStream.myJID = [XMPPJID jidWithString:[TCUserManager sharedTCUserManager].user.username resource:[TCUserManager sharedTCUserManager].user.myJidResource];
    [_xmppStream connectWithTimeout:kTimeoutLength error:nil];
}

- (void)disconnect //断开服务器连接
{
    [_xmppStream disconnect];
}

#pragma mark - 登录和注册
//用户登录
- (void)loginWithPassword:(NSString *)password
{
    NSError *error;
    if (![_xmppStream authenticateWithPassword:password error:&error]) {
        MyLog(@"认证调用失败: %@", error);
    }
}

- (void)login:(TCUser *)user //登录服务器
{
    [self startRequest:kLoginServerState];
    
    _user = user;
    _xmppStream.myJID = [XMPPJID jidWithString:user.username resource:user.myJidResource];
    
    if ([_xmppStream isConnected]) {
        [self loginWithPassword:user.password];
    }
    else {
        [self connectWithState:kLoginServerState];
    }
}

- (void)logout             //退出登录
{
    [self offline];
    
    //断开服务器连接
    [self disconnect];
    
    //清理用户数据
    [[TCUserManager sharedTCUserManager] resetUser];
}

- (void)registerWithPassword:(NSString *)password
{
    //服务器不支持带内注册
    if (!_xmppStream.supportsInBandRegistration) {
        MyLog(@"In Band Registration Not Supported");
        return;
    }
    
    NSError *error;
    //使用密码注册用户
    if (![_xmppStream registerWithPassword:password error:&error]) {
        MyLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    }
}

//如果服务器不支持注册、没有连接或者缺少信息，返回NO
- (void)registerUser:(TCUser *)user   //用户注册
{
    [self startRequest:kRegisterServerState];
    
    _user = user;
    _xmppStream.myJID = [XMPPJID jidWithString:user.username];
    
    //必须先连接才能注册
    if ([_xmppStream isConnected]) {
        //注册用户
        [self registerWithPassword:user.password];
    }
    else {
        [self connectWithState:kRegisterServerState];
    }
}

//发送到场状态(上线／下线)
- (void)online             //上线
{
    [self sendPresence:kOnlineType];
}

- (void)offline            //下线
{
    [self sendPresence:kOfflineType];
}

- (void)sendPresence:(NSString *)type
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:type];
    [_xmppStream sendElement:presence];
}

#pragma mark - 好友管理
- (void)fetchFriendsList;           //获取好友列表
{
    [_xmppRoster fetchRoster];
}

- (void)addFriend:(TCUser *)user     //添加好友
{
    XMPPJID *jid = [XMPPJID jidWithString:user.username];
    [_xmppRoster addUser:jid withNickname:nil];
}

- (void)removeFriend:(TCUser *)user  //移除好友
{
    XMPPJID *jid = [XMPPJID jidWithString:user.username];
    [_xmppRoster removeUser:jid];
}

#warning 接受好友方法还没有实现
- (void)acceptFriend:(TCUser *)user  //接受好友邀请
{
    
}

#pragma mark - 发送消息
- (void)sendMessage:(TCMessage *)message toUser:(TCUser *)user     //给用户发送消息
{
    XMPPJID *jid = [XMPPJID jidWithString:user.username];
    XMPPMessage *e = [XMPPMessage messageWithType:@"chat" to:jid];
    [e addBody:message.body];
    
    [_xmppStream sendElement:e];
}

- (void)sendMessage:(TCMessage *)message toGroup:(TCGroup *)group  //给组发送消息
{
    
}

#pragma mark - 获取模块管理对象
- (XMPPvCardAvatarModule *)avatarModule    //头像模块
{
    return _xmppAvatarModule;
}

- (XMPPvCardTempModule *)vCardModule
{
    return _xmppvCardModule;
}

- (NSManagedObjectContext *)rosterContext  //花名册模块
{
    XMPPRosterCoreDataStorage *storage = [XMPPRosterCoreDataStorage sharedInstance];
    return [storage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)vCardContext   //电子名片模块
{
    XMPPvCardCoreDataStorage *storage = [XMPPvCardCoreDataStorage sharedInstance];
    return [storage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)messageContext  //消息模块
{
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    return [storage mainThreadManagedObjectContext];
}

#pragma mark - XMPP代理方法
//服务器连接建立成功
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    switch (_serverState) {
        case kLoginServerState:
            [self loginWithPassword:_user.password];
            break;
        case kRegisterServerState:
            [self registerWithPassword:_user.password];
            break;
        default:
            break;
    }
    
    MyLog(@"服务器连接成功");
}

//连接超时
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    [self finishedRequest:_serverState errorCode:kRequestTimeout];
    _serverState = kDefaultServerState;
    
    MyLog(@"连接超时");
}

//断开连接
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    [self finishedRequest:_serverState errorCode:kRequestTimeout];
    _serverState = kDefaultServerState;
    MyLog(@"连接断开");
}

#pragma mark - Account
//注册成功
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    //完成注册请求
    [self finishedRequest:_serverState errorCode:kRequestOK];
    _serverState = kDefaultServerState;
    
    MyLog(@"用户注册成功");
}

//注册失败
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    _serverState = kDefaultServerState;
    [self finishedRequest:_serverState errorCode:kRequestError];
    
    MyLog(@"用户注册失败：%@", error);
}

//登录成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self finishedRequest:_serverState errorCode:kRequestOK];
    _serverState = kDefaultServerState;
    
    [self online];  //上线
    [TCUserManager sharedTCUserManager].user = _user;
    
    MyLog(@"用户登录成功");
}

//登录失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    [self finishedRequest:_serverState errorCode:kRequestError];
    _serverState = kDefaultServerState;
    
    MyLog(@"用户登录失败: %@", error);
}

#pragma mark - Receive Message

//接收到上线信息
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"%@", presence);
    if([[presence type] isEqualToString:@"subscribe"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"好友验证请求" message:[NSString stringWithFormat:@"%@请求添加你为好友", presence.fromStr] delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"同意", nil];
        [alert show];
        _presence = presence;
    }
    if([[presence type] isEqualToString:@"unsubscribe"]){
        [_xmppRoster removeUser:presence.from];
        _presence = nil;
    }
}

//接收错误
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error
{
    MyLog(@"Receive Error: %@", error);
}

#pragma mark - Send
//发送信息请求成功
- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    MyLog(@"Send IQ: %@", iq);
}

//发送消息成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    MyLog(@"Send Message: %@", message);
}

//发送在线信息成功
- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence
{
    MyLog(@"Send Presence: %@", presence);
}

#pragma mark - Failure
//发送信息请求失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    MyLog(@"Fail To Send IQ: %@\nError: %@", iq, error);
}

//发送消息失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    MyLog(@"Fail To Send Message: %@\nError: %@", message, error);
}

//发送在线信息失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    MyLog(@"Fail To Send Presence: %@\nError: %@", presence, error);
}

#pragma mark - 接收文件传输代理
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didFailWithError:(NSError *)error
{
    MyLog(@"接收文件失败: %@", error);
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didReceiveSIOffer:(XMPPIQ *)offer
{
    [sender acceptSIOffer:offer];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender didSucceedWithData:(NSData *)data named:(NSString *)name
{
    MyLog(@"~ ~接收文件成功~ ~");
    NSString *path = [kDocumentDirectory stringByAppendingPathComponent:name];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [data writeToFile:path atomically:YES];
    });
}

#pragma mark - UIAlertView代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        //接受好友
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:_presence.from andAddToRoster:YES];
    }else{
        //拒绝好友
        [_xmppRoster rejectPresenceSubscriptionRequestFrom:_presence.from];
    }
    _presence = nil;
}

#pragma mark - 销毁
- (void)dealloc
{
    [self unloadModules];
}

@end
