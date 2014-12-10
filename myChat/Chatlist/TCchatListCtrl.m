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
#import "SVProgressHUD.h"

#import "NSDate+Utilities.h"

#define kSendImgWidth 100
#define kSendingImageStr @"正在发送图片@"
#define kSendedImageStr @"图片发送完成@"

@interface TCchatListCtrl ()<UITableViewDelegate,UITableViewDataSource, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>
{
    NSFetchedResultsController *_fetchedResultController;
    NSFetchedResultsController *_userResultController;
    NSInteger _numberOfRows;
    UIImage *_sendImage;
}
@property (weak, nonatomic) IBOutlet UITableView *chatListTableview;
@property (weak, nonatomic) IBOutlet UITextField *messager;

@property (strong, nonatomic) XMPPOutgoingFileTransfer *outgoingFile;

@end

@implementation TCchatListCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden=YES;
    
    if(_myImage == nil){
        _myImage = [UIImage imageNamed:kDefaultHeadImage];
    }
    
    //获取用户完整jid
    [self getUserCompleteJid:_jid];
    
    //获取消息结果集
    if (_fetchedResultController == nil)
    {
        NSManagedObjectContext *moc = [[TCServerManager sharedTCServerManager] messageContext];
        
        //数据存储实体（表）
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                  inManagedObjectContext:moc];
        
        //设置结果的排序规则
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr=%@", [_jid bare]];
        
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
    
    _outgoingFile = [[XMPPOutgoingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    [_outgoingFile activate:[TCServerManager sharedTCServerManager].xmppStream];
    [_outgoingFile addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)getUserCompleteJid:(XMPPJID *)jid
{
    // 1. 如果要针对CoreData做数据访问，无论怎么包装，都离不开NSManagedObjectContext
    // 实例化NSManagedObjectContext
    NSManagedObjectContext *context = [[TCServerManager sharedTCServerManager] rosterContext];
    
    // 2. 实例化NSFetchRequest
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    //3. 设置请求谓词 实例化一个排序
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sectionNum" ascending:YES];
    
    [request setSortDescriptors:@[sort1]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr=%@", [_jid bare]];
    
    //4. 数据请求
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:predicate];
    
    // 5. 实例化_fetchedResultsController
    _userResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"sectionNum" cacheName:nil];
    
    // 6. 设置代理
    _userResultController.delegate = self;
    
    // 7. 查询数据
    NSError *error = nil;
    if (![_userResultController performFetch:&error]) {
        MyLog(@"%@", error.localizedDescription);
    }else{
        XMPPUserCoreDataStorageObject *user = [_userResultController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        XMPPJID *jid = user.primaryResource.jid;
        if(jid.resource != nil)
            _jid = jid;
    }
}

#pragma mark - 数据集改变
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if(controller == _userResultController){
        XMPPUserCoreDataStorageObject *user = [_userResultController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        XMPPJID *jid = user.primaryResource.jid;
        if(jid.resource != nil)
            _jid = jid;
        else
            _jid = user.jid;
        return;
    }
    
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
    user.username = [_jid bare];
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
    
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.time.text = message.timestamp.shortTimeString;
    
    if([message.body hasPrefix:kSendedImageStr]){
        [self drawImageAtCell:&cell withMessageBody:message.body];
        
        return cell;
    }
    [cell setMessage:message.body isOutgoing:message.isOutgoing];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchedResultController objectAtIndexPath:indexPath];
    
    NSString *str = message.body;
    if([str hasPrefix:kSendedImageStr]){
        return [self drawImageAtCell:NULL withMessageBody:str];
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentLeft;
    
    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSParagraphStyleAttributeName:style};
    CGSize size = [str sizeWithAttributes:dict];
    
    CGSize vSize = self.view.bounds.size;
    //只有一行
    if (vSize.width - 120 >= size.width) {
        return 50.0 + size.height + 20;
    }
    else {
        CGRect rect = [str boundingRectWithSize:CGSizeMake(vSize.width - 120, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:NULL];
        
        return 50.0 + rect.size.height + 20;
    }
}

#pragma mark - 求消息中图片的高度
- (CGFloat)drawImageAtCell:(TCchatListCell **)ListCell withMessageBody:(NSString *)body
{
    NSString *imageName = [[body componentsSeparatedByString:@"@"] lastObject];
    NSString *imagePath = [kDocumentDirectory stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if(image == nil){
        image = [UIImage imageNamed:@"Fav_nopic"];
    }
    image = [self compressImage:image];
    CGSize size = [image size];
    if(ListCell != NULL){
        TCchatListCell *cell = *ListCell;
        [cell.message setBackgroundImage:image forState:UIControlStateNormal];
        [cell.message setTitle:@"" forState:UIControlStateNormal];
        cell.messageWeightConstraint.constant = size.width;
        cell.messageHeightConstraint.constant = size.height;
    }
    return size.height + 35.0 + 20.0;
}

#pragma mark 点击添加按钮
- (IBAction)didAddButtonClicked:(id)sender
{
    if(!_jid.resource){
        [SVProgressHUD showErrorWithStatus:@"对方不在线或者jid缺少resource部分"];
        return ;
    }
    
    // 如何判断摄像头可用
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        
        [self presentViewController:picker animated:YES completion:nil];
        
    } else {
        NSLog(@"摄像头不可用");
    }
}

#pragma mark - UIImagePicker代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1. 获取选择的图像
    _sendImage = info[UIImagePickerControllerEditedImage];
    
    // 2. 关闭照片选择器
    __weak typeof(self) mySelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"是否发送原图" delegate:mySelf cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [alert show];
    }];
}

#pragma mark - 发送文件代理
- (void)xmppOutgoingFileTransfer:(XMPPOutgoingFileTransfer *)sender didFailWithError:(NSError *)error
{
    MyLog(@"发送文件失败: %@", error);
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
}

- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender
{
    MyLog(@"发送文件成功");
    [SVProgressHUD showSuccessWithStatus:@"发送文件成功"];
    
    //发送消息
    NSString *imagePath = sender.outgoingFileName;
    TCMessage *message = [[TCMessage alloc] init];
    message.body = [kSendedImageStr stringByAppendingString:imagePath];
    TCUser *user = [[TCUser alloc] init];
    user.username = [_jid bare];
    [[TCServerManager sharedTCServerManager] sendMessage:message toUser:user];
}

#pragma mark - UIAlertView代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //发送压缩图
    if (0 == buttonIndex) {
        _sendImage = [self compressImage:_sendImage];
    }
    
    //存储图片
    NSString *imageName = [[TCServerManager sharedTCServerManager].xmppStream generateUUID];
    NSString *imagePath = [kDocumentDirectory stringByAppendingPathComponent:imageName];
    
    NSData *imageData = UIImagePNGRepresentation(_sendImage);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [imageData writeToFile:imagePath atomically:YES];
    });
    
    NSError *error;
    if(![_outgoingFile sendData:imageData named:imageName toRecipient:_jid
                    description:@"image" error:&error]){
        MyLog(@"%@", error);
    };
}

#pragma mark - 压缩图片
- (UIImage *)compressImage:(UIImage *)image
{
    CGSize imageSize = image.size;
    if(imageSize.width > kSendImgWidth){
        imageSize.height = kSendImgWidth * imageSize.height / imageSize.width;
        imageSize.width = kSendImgWidth;
        UIGraphicsBeginImageContext(imageSize);
        [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

#pragma mark - 销毁
- (void)dealloc
{
    [_outgoingFile deactivate];
    [_outgoingFile removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    _outgoingFile = nil;
}

@end
