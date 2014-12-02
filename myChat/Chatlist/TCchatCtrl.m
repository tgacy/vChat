//
//  TCchatCtrl.m
//  vChat
//
//  Created by apple on 14/11/26.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCchatCtrl.h"
#import "TCchatCell.h"

#import "TCServerManager.h"
#import "TCUserManager.h"

#import "XMPPFramework.h"
#import "NSDate+Utilities.h"

#import "TCchatListCtrl.h"

@interface TCchatCtrl ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_resultsCtrl;
    XMPPMessageArchiving_Message_CoreDataObject *_currentUser;
    NSMutableDictionary *_chatlist;
    NSMutableArray *_chatarray;
}
@property (weak, nonatomic) IBOutlet UITableView *chatTableview;

@end

@implementation TCchatCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    _chatlist=[[TCUserManager sharedTCUserManager] getChatlistDictionary];
    _chatarray=[[TCUserManager sharedTCUserManager] getChatlistArray];
    if (_resultsCtrl == nil)
    {
        NSManagedObjectContext *moc = [[TCServerManager sharedTCServerManager] messageContext];
        
        //数据存储实体（表）
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                  inManagedObjectContext:moc];
        
        //设置结果的排序规则
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        //数据请求
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        _resultsCtrl = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:nil];
        [_resultsCtrl setDelegate:self];
        
        NSError *error = nil;
        //开始请求数据
        if (![_resultsCtrl performFetch:&error])
        {
            MyLog(@"Error performing fetch: %@", error);
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    MyLog(@"%s",__func__);

    [[TCUserManager sharedTCUserManager]saveChatlistWitharray:_chatarray andDictionary:_chatlist];
}

- (void)dealloc
{
    MyLog(@"%s",__func__);
    [[TCUserManager sharedTCUserManager]saveChatlistWitharray:_chatarray andDictionary:_chatlist];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    MyLog(@"++++%@---%@---%lu---%@",anObject,indexPath,type,newIndexPath);
    if (type==NSFetchedResultsChangeInsert) {
        [_chatlist setObject:anObject forKey:[anObject bareJidStr]];
        NSInteger index=[_chatarray indexOfObject:[anObject bareJidStr]];
        if (index!=NSNotFound) {
            [_chatarray removeObjectAtIndex:index];
            [_chatarray insertObject:[anObject bareJidStr] atIndex:0];
        }
        else
        {
            [_chatarray insertObject:[anObject bareJidStr] atIndex:0];
        }
    }
    [_chatTableview reloadData];
}

#pragma mark - UITableviewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _chatlist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *jid=[_chatarray objectAtIndex:indexPath.row];
    XMPPMessageArchiving_Message_CoreDataObject *message=(XMPPMessageArchiving_Message_CoreDataObject *)[_chatlist objectForKey:jid];
    TCchatCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.time.text=message.timestamp.shortTimeString;
    cell.username.text=message.bareJidStr;
    MyLog(@"%@",cell.username.text);
    cell.messager.text=message.body;
    
    NSData *photo = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:message.bareJid];
    if(photo != nil){
        cell.headView.image = [UIImage imageWithData:photo];
    }else{
        cell.headView.image = [UIImage imageNamed:kDefaultHeadImage];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //获取用户信息
    NSString *jid=[_chatarray objectAtIndex:indexPath.row];
    XMPPMessageArchiving_Message_CoreDataObject *message=(XMPPMessageArchiving_Message_CoreDataObject *)[_chatlist objectForKey:jid];
    _currentUser = message;
    
    MyLog(@"~~~\n barejid:%@   streamBarejid:%@", _currentUser.bareJidStr, _currentUser.streamBareJidStr);
    
    return indexPath;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TCchatListCtrl"]) {
        TCchatListCtrl *chatCtrl = segue.destinationViewController;
        chatCtrl.bareJidStr = _currentUser.bareJidStr;
        NSData *photo = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:_currentUser.bareJid];
        if(photo != nil){
            chatCtrl.bareImage = [UIImage imageWithData:photo];
        }
        //取出我的照片
        NSString *myStr = [TCUserManager sharedTCUserManager].user.username;
        XMPPJID *myJID = [XMPPJID jidWithString:myStr];
        NSData *myPhoto = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:myJID];
        chatCtrl.myImage = [UIImage imageWithData:myPhoto];
    }
}
@end
