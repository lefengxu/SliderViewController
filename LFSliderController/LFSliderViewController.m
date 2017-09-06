 //
//  LFSliderViewController.m
//  LFSliderViewController
//
//  Created by lefengxu on 2017/5/8.
//  Copyright © 2017年 lefengxu. All rights reserved.
//

#import "LFSliderViewController.h"

#define kLFDeviceWidth [UIScreen mainScreen].bounds.size.width

#pragma mark ----------- 左边菜单栏配置 ---------------
static CGFloat leftShowWidth;                           // 左侧菜单栏的宽度
static CGFloat shadowWidth;                             // 阴影面积
static CGFloat const leftDragbleWith = 80.f;            // 菜单栏可拖拽区域大小
static CGFloat const leftMinDragLength = 100.f;         // 触发所需要拖动的最短距离

static CGFloat const showDuration = 0.2f;               // 动画时间

typedef NS_ENUM(NSInteger, LFSliderDragDirection) {
    LFSliderDragDirectionNone = 0,      // 无
    LFSliderDragDirectionLeft           // 左边
};

@interface LFSliderViewController () <UIGestureRecognizerDelegate> {
    
    BOOL _isCanLeftShow;               // 左边视图是否能显示
    BOOL _isLeftShow;               // 左边视图是否显示
    BOOL _isCanDrag;                // 是否能拖拽
}
@property (nonatomic, strong) UIView * mainContainerView;   // 主视图容器
@property (nonatomic, strong) UIView * leftContainerView;   // 左视图容器
@property (nonatomic, strong) UIView * maskView;            // 遮挡视图

@property (nonatomic, assign) CGPoint startDragPoint;       // 开始时的拖拽点
@property (nonatomic, assign) CGPoint lastDragPoint;        // 最后的拖拽点
@property (nonatomic, assign) LFSliderDragDirection sliderDragDirection;   // 菜单栏侧滑方向

@property (nonatomic, strong, readwrite) UIViewController *mainViewController;
@property (nonatomic, strong, readwrite) UIViewController *leftViewController;

@end

@implementation LFSliderViewController

- (instancetype)init {
    return nil;
}

- (instancetype)initWithMainViewController:(UIViewController *)mainViewController leftViewController:(UIViewController *)leftViewController {
    self = [super init];
    if (!self) return nil;

    [self initData];
    
    self.mainViewController = mainViewController;
    self.leftViewController = leftViewController;
    
    return self;
}

- (void)initData {
    leftShowWidth = 260*RATIO_STAND_WIDTH;
    shadowWidth = 20*RATIO_STAND_WIDTH;
    
    CGRect viewBounds = self.view.bounds;
    self.mainContainerView = [[UIView alloc]init];
    self.leftContainerView = [[UIView alloc]init];
    self.maskView = [[UIView alloc]init];
    self.maskView.hidden = YES;
    self.maskView.backgroundColor = [UIColor clearColor];
    UIView * backgroundView = [[UIView alloc]initWithFrame:CGRectMake(10, 10, 40, 50)];
    backgroundView.backgroundColor = [UIColor whiteColor];
    [self.maskView addSubview:backgroundView];
    
    UIImageView * backgroundImageView = [[UIImageView alloc]initWithFrame:CGRectMake(20, 20, 28, 28)];
    backgroundImageView.image = [UIImage imageNamed:@"icon_back"];
    [self.maskView addSubview:backgroundImageView];
    
    self.mainContainerView.frame = viewBounds;
    self.leftContainerView.frame = CGRectMake(viewBounds.origin.x, viewBounds.origin.y, leftShowWidth, viewBounds.size.height);
    self.maskView.frame = viewBounds;
    
    [self.view addSubview:self.leftContainerView];
    [self.view addSubview:self.mainContainerView];
    [self.mainContainerView addSubview:self.maskView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    // 添加手势
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureHandler:)];
    panGesture.delegate = self;
    [self.mainContainerView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureHandler:)];
    tapGesture.delegate = self;
    [self.maskView addGestureRecognizer:tapGesture];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.leftContainerView.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.leftContainerView.hidden = NO;
}


#pragma mark --------------- setter & getter -----------------------
- (void)setMainViewController:(UIViewController *)mainViewController{
    NSAssert(mainViewController!=nil, @"主控制器不可为空");
    
    _mainViewController = mainViewController;
    [self addChildViewController:mainViewController];
    [self.mainContainerView addSubview:mainViewController.view];
}

- (void)setLeftViewController:(UIViewController *)leftViewController {
    NSAssert(leftViewController!=nil, @"侧面控制器制器不可为空");
    
    _leftViewController = leftViewController;
    _isCanLeftShow = YES;
    self.leftViewController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.leftViewController.view.frame = self.leftContainerView.frame;
    [self addChildViewController:leftViewController];
    [self.leftContainerView addSubview:leftViewController.view];
    self.leftContainerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -leftShowWidth, 0);
    
    [self setShadow];
}

/**
 控件左右菜单界面push所需要的navigationController,默认为mainVC的navigationController
 
 @return mainVC的navigationController
 */
- (UINavigationController *)sliderNavigationController
{
    if (self.mainViewController) {
        if ([self.mainViewController isKindOfClass:[UINavigationController class]]) {
            return (UINavigationController *)self.mainViewController;
        }
    }else if (self.mainViewController.navigationController){
        return self.mainViewController.navigationController;
    }
    return nil;
}

#pragma mark ------------------- gesture handler ---------------------
- (void)panGestureHandler:(UIPanGestureRecognizer *)panGesture {
    CGPoint point = [panGesture locationInView:self.view];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            // 当左边视图没有展示时，判断是否在手势响应范围内
            if (!_isLeftShow) {
                if (point.x < leftDragbleWith) {
                    _isCanDrag = YES;
                } else {
                    _isCanDrag = NO;
                }
            } else {
                // 当左边视图已展示，判断主视图中是否在手势响应范围内
                CGPoint currentPoint = [panGesture locationInView:self.mainContainerView];
                if (currentPoint.x>0&&currentPoint.y>0) {
                    _isCanDrag = YES;
                } else {
                    _isCanDrag = NO;
                }
            }
            
            self.startDragPoint = point;
            self.lastDragPoint = point;
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            if (!_isCanDrag) break;
            
            CGFloat mainViewX = self.mainContainerView.frame.origin.x;
            CGFloat moveLength = point.x - self.lastDragPoint.x;
            self.lastDragPoint = point;
            
            // 侧滑菜单未显示时
            if (!_isLeftShow) {   // 显示左边侧滑菜单
                if (self.sliderDragDirection == LFSliderDragDirectionNone) {
                    if (moveLength > 0) {
                        self.sliderDragDirection = LFSliderDragDirectionLeft;
                        self.leftContainerView.hidden = NO;
                    }
                }
                
                switch (self.sliderDragDirection) {
                    case LFSliderDragDirectionLeft: {
                        // 当左边无界面时退出
                        if (!_isCanLeftShow) break;
                        
                        // 当从右边边拽时，失效
                        if (mainViewX+moveLength<0) break;
                        
                        CGFloat leftX = self.leftContainerView.frame.origin.x;
                        
                        if (moveLength>leftShowWidth || leftX>0 || leftX+moveLength>0) break;
                        
                        self.mainContainerView.transform = CGAffineTransformTranslate(self.mainContainerView.transform, moveLength, 0);
                        self.leftContainerView.transform = CGAffineTransformTranslate(self.leftContainerView.transform, moveLength, 0);
                    }
                        break;
                        default:
                        break;
                }
            } else if (_isLeftShow) {
                if (self.sliderDragDirection == LFSliderDragDirectionNone) {
                    self.sliderDragDirection = LFSliderDragDirectionLeft;
                }
                
                CGFloat leftX = self.leftContainerView.frame.origin.x;
                CGFloat mainViewX = self.mainContainerView.frame.origin.x;
                CGFloat leftMaxX = CGRectGetMaxX(self.leftContainerView.frame);
                
                if (leftMaxX<0 || fabs(moveLength)>leftShowWidth || leftX>0 || leftX+moveLength>0 || point.x>self.startDragPoint.x || mainViewX<0) {
                    break;
                }
                
                
                self.mainContainerView.transform = CGAffineTransformTranslate(self.mainContainerView.transform, moveLength, 0);
                self.leftContainerView.transform = CGAffineTransformTranslate(self.leftContainerView.transform, moveLength, 0);
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            
            if (!_isCanDrag) break;
            
            CGFloat moveLength = fabs(point.x - self.startDragPoint.x);
            switch (self.sliderDragDirection) {
                case LFSliderDragDirectionLeft: {
                    CGFloat leftX = self.leftContainerView.frame.origin.x;
                    
                    if (!_isCanLeftShow) break;
                    
                    // 往左滑到底了
                    if (_isLeftShow&&point.x-_startDragPoint.x>0&&leftX==0) break;
                    
                    // 判断拖拽距离是否足够显示或者隐藏界面
                    if (moveLength > leftMinDragLength) {
                        if (_isLeftShow) {
                            [self hideLeft];
                        } else {
                            [self showLeft];
                        }
                    } else {
                        if (_isLeftShow) {
                            [self showLeft];
                        } else {
                            [self hideLeft];
                        }
                    }
                }
                    break;
                    
                default:
                    [self hideLeft];
                    break;
            }
            
            self.sliderDragDirection = LFSliderDragDirectionNone;
            _lastDragPoint = CGPointZero;
            _startDragPoint = CGPointZero;
            _isCanDrag = NO;
        }

            break;
            
        default:
            break;
    }
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)tapGesture {
    if (_isLeftShow) {
        [self hideLeft];
    }
}

#pragma mark ---------------------------- method ------------------------------------
- (void)hideLeft {
    __weak typeof(self)weakSelf = self;
    
    [UIView animateWithDuration:showDuration
                     animations:^{
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         
                         strongSelf.mainContainerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
                         
                         strongSelf.leftContainerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -leftShowWidth, 0);
                         
                     }
                     completion:^(BOOL finished) {
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         _isLeftShow = NO;
                         strongSelf.maskView.hidden = YES;
                         strongSelf.leftContainerView.hidden = YES;
//                         strongSelf.mainContainerView.layer.shadowOpacity = 0;
                     }];
    
}

- (void)showLeft {
    _leftContainerView.hidden = NO;
    
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:showDuration
                     animations:^{
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         
                         strongSelf.mainContainerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, leftShowWidth, 0);
                         strongSelf.leftContainerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
                         
                         
                         
                     }
                     completion:^(BOOL finished) {
                         __strong typeof(weakSelf)strongSelf = weakSelf;
                         
                         _isLeftShow = YES;
                         strongSelf.maskView.hidden = NO;
                         [strongSelf.mainContainerView bringSubviewToFront:_maskView];
//                         strongSelf.mainContainerView.layer.shadowOpacity = 0.1;
                         
                     }];
}

#pragma mark -------------- gesture delegate -----------------------
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // 防止进入多级界面后依然可以呼出侧滑菜单栏
    if ([_mainViewController isKindOfClass:[UINavigationController class]]) {
        if (_mainViewController.childViewControllers.count>1) {
            return NO;
        }
    }else{
        for (UIViewController *controller in _mainViewController.childViewControllers) {
            if ([controller isKindOfClass:[UINavigationController class]]) {
                if (controller.childViewControllers.count>1) {
                    return NO;
                }
            }
        }
    }
    
    // 判断点击拖动手势是否在允许拖动范围内
    if ([gestureRecognizer locationInView:_mainContainerView].x < leftDragbleWith) {
        return YES;
    }
    return NO;
}


#pragma mark --------------------- config Shadow --------------------------

/**
 返回渐变阴影
 */
- (CAGradientLayer *)getShdowGradientWithFrame:(CGRect)frame {
    
    CAGradientLayer * gradientLayer = [CAGradientLayer layer];
    
    gradientLayer.startPoint = CGPointMake(0, 0.5);
    gradientLayer.endPoint = CGPointMake(1, 0.5);
    
    UIColor * colorOne = [UIColor colorWithWhite:0 alpha:0];
    UIColor * colorTwo = [UIColor colorWithWhite:0 alpha:0.05];
    NSArray * colors =  [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor,nil];
    
    gradientLayer.colors = colors;
    gradientLayer.frame = frame;
    
    return gradientLayer;
}


/**
 设置阴影
 */
- (void)setShadow {
    CGFloat gradViewX = leftShowWidth - shadowWidth;
    CGFloat gradViewH = [UIScreen mainScreen].bounds.size.height;
    UIView * gradView = [[UIView alloc]initWithFrame:CGRectMake(gradViewX, 0, shadowWidth, gradViewH)];
    CAGradientLayer * gradientLayer = [self getShdowGradientWithFrame:gradView.bounds];
    [gradView.layer addSublayer:gradientLayer];
    [self.leftContainerView addSubview:gradView];
}

@end
