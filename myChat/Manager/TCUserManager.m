//
//  TCUserManager.m
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCUserManager.h"
#import "KeychainItemWrapper.h"

@implementation TCUserManager

//单例实现
single_implementation(TCUserManager)

//初始化
- (instancetype)init
{
    if (self = [super init]) {
        _user = [[TCUser alloc] init];
        
        KeychainItemWrapper *itemWrapper = [self keychainItemWrapper];
        _user.username = [itemWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
        _user.password = [itemWrapper objectForKey:(__bridge id)(kSecValueData)];
        NSString *path1=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/chatlistDictionary"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path1]) {
            NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
            NSMutableArray *array=[NSMutableArray array];
            [self saveChatlistWitharray:array andDictionary:dictionary];
        }
    }
    
    return self;
}

//拦截设置用户方法, 存储用户
- (void)setUser:(TCUser *)user
{
    _user = user;
    KeychainItemWrapper *itemWrapper = [self keychainItemWrapper];
    [itemWrapper setObject:user.username forKey:(__bridge id)(kSecAttrAccount)];
    [itemWrapper setObject:user.password forKey:(__bridge id)(kSecValueData)];
}

//重置用户
- (void)resetUser
{
    _user = nil;
    KeychainItemWrapper *itemWrapper = [self keychainItemWrapper];
    [itemWrapper resetKeychainItem];
}

//获取存储对象
- (KeychainItemWrapper *)keychainItemWrapper
{
    return [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainIdentifier accessGroup:nil];
}

//判断是否能自动登录
- (BOOL)isLogin
{
    if (_user.username.length && _user.password.length) {
        return YES;
    }
    
    return NO;
}

//存储消息列表
- (void)saveChatlistWitharray:(NSMutableArray *)array andDictionary:(NSMutableDictionary*)dictionary
{
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/chatlistArray"];
    [array writeToFile:path atomically:YES];
    NSString *path1=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/chatlistDictionary"];
    [dictionary writeToFile:path1 atomically:YES];
    
}

//获取消息列表
- (NSMutableDictionary *)getChatlistDictionary
{
    NSString *path1=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/chatlistDictionary"];
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionaryWithContentsOfFile:path1];
    return dictionary;
}

- (NSMutableArray *)getChatlistArray
{
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/chatlistArray"];
    NSMutableArray *array=[NSMutableArray arrayWithContentsOfFile:path];
    return array;
}

@end
