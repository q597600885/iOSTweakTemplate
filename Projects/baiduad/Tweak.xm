#import <UIKit/UIKit.h>

// ==========================================
// 1. 穿山甲（CSJ）开屏广告安全去广告 Hook
// ==========================================

%hook CSJSplashAdLoader

- (void)loadAdWithSlot:(id)slot bouncers:(id)bouncers {
    NSLog(@"[AdBlocker] CSJSplashAdLoader loadAdWithSlot called.");
    %orig; // 保持正常加载，防止 App 发生超时卡死
}

- (void)loadAdDataWithSlot:(id)slot {
    NSLog(@"[AdBlocker] CSJSplashAdLoader loadAdDataWithSlot called.");
    %orig;
}

%end

%hook CSJSplashViewController

- (void)viewDidLoad {
    %orig;
    NSLog(@"[AdBlocker] CSJSplashViewController loaded, hiding and closing immediately.");
    
    // 视图加载后立即关闭开屏控制器，防止广告弹出
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else if (self.view) {
            [self.view removeFromSuperview];
        }
    });
}

%end

%hook CSJSplashView

- (void)didMoveToWindow {
    %orig;
    // 如果有漏网之鱼，当广告视图被加到窗口时直接移除并隐藏
    [self removeFromSuperview];
    self.hidden = YES;
    NSLog(@"[AdBlocker] CSJSplashView removed from window.");
}

%end


// ==========================================
// 2. 注入成功弹窗提示（仅弹一次，验证是否生效）
// ==========================================

%ctor {
    NSLog(@"[AdBlocker] Ad-blocking tweak loaded successfully!");
    
    // 延迟 1.5 秒弹出提示，确保 App 已经完全启动、有可用的 UIWindow
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 获取当前主窗口或最顶层的 ViewController
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        UIViewController *rootVC = keyWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎉 越狱插件提示"
                                                                            message:@"AdBlocker 注入成功，穿山甲开屏广告已拦截！"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}