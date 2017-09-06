# SliderViewController
仿QQ侧滑菜单

## 用法:  
    ①导入头文件 #import "LFSliderViewController.h"<br><br>
    ②初始化并传入主控制器和副控制器<br>
    - (instancetype)initWithMainViewController:(UIViewController *)mainViewController<br>
                        &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;leftViewController:(UIViewController *)leftViewController;<br>
    ③通过分类 UIViewController+LFSliderController.h 在内部控制器中可以访问到该侧滑菜单控制器。<br><br>
