//
//  TCchatListCell.m
//  vChat
//
//  Created by apple on 14/11/27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCchatListCell.h"

@interface TCchatListCell ()
{
    UIImage *_receiveImage;
    UIImage *_receiveImageHL;
    UIImage *_senderImage;
    UIImage *_senderImageHL;
}

@end

@implementation TCchatListCell

- (UIImage *)stretcheImage:(UIImage *)img
{
    return [img stretchableImageWithLeftCapWidth:img.size.width * 0.5 topCapHeight:img.size.height * 0.6];
}

- (void)awakeFromNib {
    // 实例化表格行背景使用的图像
    _receiveImage = [UIImage imageNamed:@"ReceiverTextNodeBkg"];
    _receiveImageHL = [UIImage imageNamed:@"ReceiverTextNodeBkgHL"];
    _senderImage = [UIImage imageNamed:@"SenderTextNodeBkg"];
    _senderImageHL = [UIImage imageNamed:@"SenderTextNodeBkgHL"];
    
    // 处理图像拉伸（因为iOS 6不支持图像切片）
    //    _receiveImage = [_receiveImage stretchableImageWithLeftCapWidth:_receiveImage.size.width * 0.5 topCapHeight:_receiveImage.size.height * 0.6];
    _receiveImage = [self stretcheImage:_receiveImage];
    _receiveImageHL = [self stretcheImage:_receiveImageHL];
    _senderImage = [self stretcheImage:_senderImage];
    _senderImageHL = [self stretcheImage:_senderImageHL];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(NSString *)message isOutgoing:(BOOL)isOutgoing
{
    // 1. 根据isOutgoing判断消息是发送还是接受，依次来设置按钮的背景图片
    if (isOutgoing) {
        [_message setBackgroundImage:_senderImage forState:UIControlStateNormal];
        [_message setBackgroundImage:_senderImageHL forState:UIControlStateHighlighted];
    } else {
        [_message setBackgroundImage:_receiveImage forState:UIControlStateNormal];
        [_message setBackgroundImage:_receiveImageHL forState:UIControlStateHighlighted];
    }
    
    
    NSString *str = message;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentLeft;
    
    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSParagraphStyleAttributeName:style};
//    CGSize size = [str sizeWithAttributes:dict];
    
    CGSize vSize = self.bounds.size;
//    // 2. 设置按钮文字
//    // 2.1 计算文字占用的区间
    CGRect rect= [str boundingRectWithSize:CGSizeMake(vSize.width - 120, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:NULL];
    
    
    // 2.2 使用文本占用空间设置按钮的约束
    // 提示：需要考虑到在Stroyboard中设置的间距
    _messageHeightConstraint.constant = rect.size.height + 20.0;
    _messageWeightConstraint.constant = rect.size.width + 40.0;
    
    // 2.3 设置按钮文字
    [_message setTitle:message forState:UIControlStateNormal];
    
    // 2.4 重新调整布局
    [self layoutIfNeeded];
}

@end
