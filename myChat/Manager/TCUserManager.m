//
//  TCUserManager.m
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCUserManager.h"
#import "KeychainItemWrapper.h"

@interface TCUserManager()

@end

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
    [[NSUserDefaults standardUserDefaults]setObject:array forKey:@"listArry"];
    [[NSUserDefaults standardUserDefaults]setObject:dictionary forKey:@"listDictionary"];
}

//获取消息列表
- (NSMutableDictionary *)getChatlistDictionary
{
    NSMutableDictionary *dictionary=[[NSUserDefaults standardUserDefaults]objectForKey:@"listDictionary"];
    if (dictionary==nil) {
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [[NSUserDefaults standardUserDefaults]setObject:dict forKey:@"listDictionary"];
        return dict;
    }
    return dictionary;
}
- (NSMutableArray *)getChatlistArray
{
    NSMutableArray *array=[[NSUserDefaults standardUserDefaults]objectForKey:@"listArry"];
    if (array==nil) {
        NSMutableArray *arr=[NSMutableArray array];
        [[NSUserDefaults standardUserDefaults]setObject:arr forKey:@"listArry"];
        return arr;
    }
    return array;
}

@end
