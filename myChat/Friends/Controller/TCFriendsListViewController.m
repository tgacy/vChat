//
//  TCFriendsListViewController.m
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCFriendsListViewController.h"
#import "TCServerManager.h"
#import "TCFriendInfoViewController.h"
#import "TCFriendCell.h"
#import "TCAddFriendViewController.h"
#import "SVProgressHUD.h"

#define kFriendCellHeight 71.0f

@interface TCFriendsListViewController () <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
    NSIndexPath *_removedIndexPath;
}

@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;

@end

@implementation TCFriendsListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupFetchedController];
}

#pragma mark - 实例化NSFetchedResultsController
- (void)setupFetchedController
{
    // 1. 如果要针对CoreData做数据访问，无论怎么包装，都离不开NSManagedObjectContext
    // 实例化NSManagedObjectContext
    NSManagedObjectContext *context = [[TCServerManager sharedTCServerManager] rosterContext];
    
    // 2. 实例化NSFetchRequest
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    // 3. 实例化一个排序
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sectionNum" ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    
    [request setSortDescriptors:@[sort1, sort2]];
    
    // 4. 实例化_fetchedResultsController
    _fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"sectionNum" cacheName:nil];
    
    // 5. 设置FetchedResultsController的代理
    [_fetchedResultsController setDelegate:self];
    
    // 6. 查询数据
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        MyLog(@"%@", error.localizedDescription);
        [SVProgressHUD showErrorWithStatus:@"请求好友列表失败"];
    };
}

#pragma mark - NSFetchedResultsController代理方法
#pragma mark 控制器数据发生改变（因为Roster是添加了代理的）
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //删除用户名为空的好友
    if(_didConfirmAddFriend){
        _didConfirmAddFriend(controller);
        _didConfirmAddFriend = nil;
    }
    
    // 当数据发生变化时，重新刷新表格
    [_friendsTableView reloadData];
}

#pragma mark 准备Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)indexPath
{
    // 判断是否跳往聊天界面
    if ([segue.identifier isEqualToString:@"friendInfoSegue"]) {
        TCFriendInfoViewController *controller = segue.destinationViewController;
        
        // 获取当前选中的用户
        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
        controller.jid = user.jid;
    }
}

#pragma mark - UITableView数据源方法
#pragma mark 表格分组数量
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // 返回查询结果的分组数量
    return _fetchedResultsController.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // 1. 取出控制器中的所有分组
    NSArray *array = [_fetchedResultsController sections];
    // 2. 根据section值取出对应的分组信息对象
    id <NSFetchedResultsSectionInfo> info = array[section];
    
    NSString *stateName = nil;
    NSInteger state = [[info name] integerValue];
    
    switch (state) {
        case 0:
            stateName = @"在线";
            break;
        case 1:
            stateName = @"离开";
            break;
        case 2:
            stateName = @"下线";
            break;
        default:
            stateName = @"未知";
            break;
    }
    
    return stateName;
}

#pragma mark 对应分组中表格的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [_fetchedResultsController sections];
    
    if (sectionData.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = sectionData[section];
        
        return [sectionInfo numberOfObjects];
    }
    
    return 0;
}

#pragma mark 表格行内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    
    //获取用户信息
    XMPPUserCoreDataStorageObject *friendInfo = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.friendInfo = friendInfo;
    
    return cell;
}

//行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kFriendCellHeight;
}

#pragma mark - 表格代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"friendInfoSegue" sender:indexPath];
}

/**
 *  要允许表格支持滑动删除，需要做两件事情
 *  1. 实现tableView:canEditRowAtIndexPath:方法，允许表格边界
 *  2. 实现tableView:commitEditingStyle:forRowAtIndexPath:，提交表格编辑
 */
#pragma mark 允许表格编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark 提交表格编辑
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 提示，如果没有另行执行，editingStyle就是删除
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        /*
         在OC开发中，是MVC架构的，数据绑定到表格，如果要删除表格中的数据，应该：
         1. 删除数据
         2. 刷新表格
         
         注意不要直接删除表格行，而不删除数据。
         */
        // 删除数据
        // 1. 取出当前的用户数据
        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:indexPath];
        
        // 发现问题，删除太快，没有任何提示，不允许用户后悔
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"是否删除好友" message:user.jidStr delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        // 记录住要删除的表格行索引
        _removedIndexPath = indexPath;
        
        [alert show];
    }
}

#pragma mark - UIAlertView代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 2. 将用户数据删除
    if (1 == buttonIndex) {
        // 用indexPathForSelectedRow是获取不到被删除的行的
        XMPPUserCoreDataStorageObject *user = [_fetchedResultsController objectAtIndexPath:_removedIndexPath];
        
        [[[TCServerManager sharedTCServerManager] xmppRoster] removeUser:user.jid];
    }
}

@end
