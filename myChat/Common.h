//
//  Common.h
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - 状态信息和状态码
typedef NS_ENUM(NSUInteger, TCServerState) {
    kDefaultServerState = 0,    //默认状态
    kLoginServerState,          //登录状态
    kRegisterServerState,       //注册状态
    kMessageServerState,        //消息状态
};

typedef NS_ENUM(NSUInteger, TCRequestErrorCode) {
    kRequestOK = 0,
    kRequestTimeout,
    kRequestError,
};

#pragma mark - 连接超时时间
#define kTimeoutLength 60

#pragma mark - 存储标识符
#define kKeyChainIdentifier @"userInfo"

//@"vpn.wuqiong.tk"
#define kHostName  @"luojiahui-2.lan"   //主机名
#define kOnlineType  @"available"       //上线
#define kOfflineType  @"unavailable"    //下线


#pragma mark - 单例类的定义

// .h
#define single_interface(class)  + (class *)shared##class;

// .m
// \ 代表下一行也属于宏
// ## 是分隔符
#define single_implementation(class) \
static class *_instance; \
\
+ (class *)shared##class \
{ \
if (_instance == nil) { \
_instance = [[self alloc] init]; \
} \
return _instance; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
}


// 2.日志输出宏定义
#ifdef DEBUG
// 调试状态
#define MyLog(...) NSLog(__VA_ARGS__)
#else
// 发布状态
#define MyLog(...)
#endif

//颜色
#define UIColor(r, g, b, a) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];

//默认头像, 高度
#define kDefaultHeadImage @"head"
#define kDefaultHeadWidth 66
#define kDefaultHeadHeight 66
