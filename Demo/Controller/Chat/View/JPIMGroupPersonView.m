//
//  GroupPersonView.m
//  JPush IM
//
//  Created by Apple on 15/3/6.
//  Copyright (c) 2015年 Apple. All rights reserved.
//

#import "JPIMGroupPersonView.h"

@implementation JPIMGroupPersonView

- (void)awakeFromNib {
    [self bringSubviewToFront:self.deletePersonBtn];
    self.deletePersonBtn.layer.cornerRadius = 10;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)headViewBtnClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(groupPersonBtnClick:)]) {
        [self.delegate groupPersonBtnClick:self];
    }
}

@end
