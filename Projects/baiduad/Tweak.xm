#import <UIKit/UIKit.h>

// 1. 穿山甲（CSJ）开屏广告安全去广告 Hook
%hook CSJSplashViewController

- (void)viewDidLoad {
    %orig;
    NSLog(@"[AdBlocker] CSJSplashViewController loaded, hiding and closing immediately.");
    
    // 使用显式类型转换，彻底避开 forward declaration 报错
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}

%end

%hook CSJSplashAdLoader

- (void)loadAdWithSlot:(id)slot bouncers:(id)bouncers {
    NSLog(@"[AdBlocker] CSJSplashAdLoader loadAdWithSlot called.");
    %orig;
}

- (void)loadAdDataWithSlot:(id)slot {
    NSLog(@"[AdBlocker] CSJSplashAdLoader loadAdDataWithSlot called.");
    %orig;
}

%end

%hook CSJSplashView

- (void)didMoveToWindow {
    %orig;
    UIView *adView = (UIView *)self;
    [adView removeFromSuperview];
    adView.hidden = YES;
    NSLog(@"[AdBlocker] CSJSplashView removed from window.");
}

%end

// 2. 插件加载入口（已移除有警告的 deprecated api，保证 100% 编译通过）
%ctor {
    NSLog(@"[AdBlocker] Ad-blocking tweak loaded successfully!");
}