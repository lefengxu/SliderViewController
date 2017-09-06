//
//  UIViewController+LFSliderController.m
//  LFSliderViewController
//
//  Created by lefengxu on 2017/5/10.
//  Copyright © 2017年 lefengxu. All rights reserved.
//

#import "UIViewController+LFSliderController.h"
#import "LFSliderViewController.h"

@implementation UIViewController (LFSliderController)
-  (LFSliderViewController *)sliderViewController {
    UIViewController * vc = (UIViewController *)self.parentViewController;
    while (vc)  {
        if ([vc isKindOfClass:[LFSliderViewController class]]) {
            return (LFSliderViewController *)vc;
        } else if (vc.parentViewController && vc.parentViewController!=vc) {  // 再往上找父控制器
            vc = vc.parentViewController;
        } else {
            return nil;
        }
    }
    
    return nil;
}

@end
