//
//  JPIMAlreadyLoginViewController.m
//  JPush IM
//
//  Created by Apple on 15/2/2.
//  Copyright (c) 2015年 Apple. All rights reserved.
//

#import "JPIMAlreadyLoginViewController.h"
#import "JPIMCommon.h"
#import "MBProgressHUD+Add.h"
#import "AppDelegate.h"
#import "JPIMLoginViewController.h"
#import <JMessage/JMessage.h>
@interface JPIMAlreadyLoginViewController ()

@end

@implementation JPIMAlreadyLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    JPIMLog(@"Action ");
    // Do any additional setup after loading the view from its nib.
    self.loginBtn.layer.cornerRadius=4;
    [self.loginBtn.layer setMasksToBounds:YES];
    NSString *userName =[[NSUserDefaults standardUserDefaults] objectForKey:kuserName];
    [self.userName setTitle:userName forState:UIControlStateNormal];
    self.navigationController.navigationBar.barTintColor =UIColorFromRGB(0x3f80dd);
    self.navigationController.navigationBar.alpha=0.8;
    self.title=@"极光IM";
    [self.passwordField setSecureTextEntry:YES];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor whiteColor], UITextAttributeTextColor,
                                                                     [UIColor colorWithRed:0 green:0.7 blue:0.8 alpha:1], UITextAttributeTextShadowColor,
                                                                     [NSValue valueWithUIOffset:UIOffsetMake(0, 0)], UITextAttributeTextShadowOffset,
                                                                     [UIFont boldSystemFontOfSize:18], UITextAttributeFont,
                                                                     nil]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:NO];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [self.navigationController.navigationBar setHidden:YES];
}
- (IBAction)userSwitching:(id)sender {
    JPIMLoginViewController *loginCtl = [[JPIMLoginViewController alloc] initWithNibName:@"JPIMLoginViewController" bundle:nil];
    [self.navigationController pushViewController:loginCtl animated:YES];
}
- (IBAction)loginBtn:(id)sender {
    
    [MBProgressHUD showMessage:@"正在登陆" toView:self.view];
    if (![self.passwordField.text isEqualToString:@""] && ![self.passwordField.text isEqualToString:@""]) {
        [JMSGUserManager loginWithUsername:[[NSUserDefaults standardUserDefaults] objectForKey:kuserName] password:self.passwordField.text completionHandler:^(id resultObject, NSError *error) {
            if (error != nil) {
                NSLog(@"login success");
                AppDelegate *appdelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
                [self.navigationController pushViewController:appdelegate.tabBarCtl animated:YES];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            } else {
                if (error.code == 100) {
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    [MBProgressHUD showMessage:@"用户不存在!" view:self.view];
                } else {
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    [MBProgressHUD showMessage:@"登录失败!" view:self.view];
                }
            }
        }];
    }else{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [MBProgressHUD showMessage:@"密码不能为空!" view:self.view];
    }

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark --触摸屏幕
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.passwordField resignFirstResponder];
}

@end
