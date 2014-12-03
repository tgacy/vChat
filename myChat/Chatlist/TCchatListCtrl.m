//
//  TCchatListCtrl.m
//  vChat
//
//  Created by apple on 14/11/27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCchatListCtrl.h"

#import "TCchatListCell.h"
#import "TCServerManager.h"

#import "TCUser.h"
#import "TCMessage.h"

#import "NSDate+Utilities.h"

@interface TCchatListCtrl ()<UITableViewDelegate,UITableViewDataSource, NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultController;
    NSInteger _numberOfRows;
}
@property (weak, nonatomic) IBOutlet UITableView *chatListTableview;
@property (weak, nonatomic) IBOutlet UITextField *messager;

@end

@implementation TCchatListCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden=YES;
    
    if(_myImage == nil){
        _myImage = [UIImage imageNamed:kDefaultHeadImage];
    }
    
    if (_fetchedResultController == nil)
    {
        NSManagedObjectContext *moc = [[TCServerManager sharedTCServerManager] messageContext];
        
        //数据存储实体（表）
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                  inManagedObjectContext:moc];
        
        //设置结果的排序规则
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr=%@", _bareJidStr];
        
        //数据请求
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:nil];
        [_fetchedResultController setDelegate:self];
        
        
        NSError *error = nil;
        //开始请求数据
        if (![_fetchedResultController performFetch:&error])
        {
            MyLog(@"Error performing fetch: %@", error);
        }
    }
    [self controllerDidChangeContent:nil];
}

#pragma mark - 数据集改变
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_chatListTableview reloadData];
    
    //尝试滚动到最底下
    [self scrollToBottom];
}

#pragma - mark 滚动到底部
- (void)scrollToBottom
{
    if (_numberOfRows) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_numberOfRows - 1 inSection:0];
        [_chatListTableview scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (IBAction)sendeMessager:(UIButton *)sender
{
    TCMessage *message = [[TCMessage alloc] init];
    message.body = _messager.text;
    TCUser *user = [[TCUser alloc] init];
    user.username = _bareJidStr;
    [[TCServerManager sharedTCServerManager] sendMessage:message toUser:user];
    
    _messager.text = nil;
}

#pragma mark - UITableviewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [_fetchedResultController sections];
    
    if (section < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        _numberOfRows = sectionInfo.numberOfObjects;
        return sectionInfo.numberOfObjects;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchedResultController objectAtIndexPath:indexPath];
    
    TCchatListCell *cell = nil;
    if (message.isOutgoing) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"to" forIndexPath:indexPath];
        [cell.headView setBackgroundImage:_myImage forState:UIControlStateNormal];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"from" forIndexPath:indexPath];
        [cell.headView setBackgroundImage:_bareImage forState:UIControlStateNormal];
    }
    
    cell.body.text = message.body;
    cell.time.text = message.timestamp.shortTimeString;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchedResultController objectAtIndexPath:indexPath];
    
    NSString *str = message.body;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentLeft;
    
    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSParagraphStyleAttributeName:style};
    CGSize size = [str sizeWithAttributes:dict];
    
    CGSize vSize = self.view.bounds.size;
    //只有一行
    if (vSize.width - 120 >= size.width) {
        return 56 + size.height + 14;
    }
    else {
        CGRect rect = [str boundingRectWithSize:CGSizeMake(vSize.width - 120, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:NULL];
        
        return 56 + rect.size.height + 14;
    }
}

@end
