#import <UIKit/UIKit.h>

// 1. 深度拦截贴吧底层的开屏控制器与广告服务
%hook TBSplashViewController
- (void)viewDidLoad {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        [vc.view removeFromSuperview];
        if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}
%end

%hook TBAdSplashViewController
- (void)viewDidLoad {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        [vc.view removeFromSuperview];
        if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}
%end

// 2. 全局 UIWindow 监视并强力抹除任何广告、开屏视图
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    UIWindow *window = (UIWindow *)self;
    for (UIView *subview in window.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || [className containsString:@"Advert"] || [className containsString:@"Launch"]) {
            subview.hidden = YES;
            [subview removeFromSuperview];
        }
    }
}
%end

// 3. 拦截广告模型或广告曝光上报 (阻断广告请求逻辑)
%hook TBBaseAdModel
- (void)loadAdData {
    // 拦截广告数据加载
}
%end

%hook TBAdService
- (void)requestAd {
    // 拦截广告请求
}
%end
