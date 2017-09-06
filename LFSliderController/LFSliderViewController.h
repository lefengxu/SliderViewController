//
//  LFSliderViewController.h
//  LFSliderViewController
//
//  Created by lefengxu on 2017/5/8.
//  Copyright © 2017年 xulefeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFSliderViewController : UIViewController
@property (nonatomic, strong, readonly) UIViewController *mainViewController;
@property (nonatomic, strong, readonly) UIViewController *leftViewController;

@property (nonatomic, strong, readonly) UINavigationController *sliderNavigationController; // push所需要的navigationController 只能由mainVC 提供


- (instancetype)initWithMainViewController:(UIViewController *)mainViewController
                        leftViewController:(UIViewController *)leftViewController;

- (void)hideLeft;   // 显示左边视图
- (void)showLeft;   // 隐藏左边视图

@end
