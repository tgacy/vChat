//
//  UIView+firstResponder.m
//  营内聊
//
//  Created by apple on 14-11-18.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "UIView+firstResponder.h"

@implementation UIView (firstResponder)

- (UIView *)firstResponder
{
    for(UIView *v in self.subviews){
        if([v isFirstResponder]){
            return v;
        }else{
            UIView *vf = [v firstResponder];
            if(vf){
                return vf;
            }
        }
    }
    return nil;
}

@end
