#import <UIKit/UIKit.h>

// ==========================================
// 1. 穿山甲（CSJ）开屏广告安全去广告 Hook
// ==========================================

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

%hook CSJSplashViewController

- (void)viewDidLoad {
    %orig;
    NSLog(@"[AdBlocker] CSJSplashViewController loaded, hiding and closing immediately.");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    });
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


// ==========================================
// 2. 注入成功弹窗提示（绝对安全，无编译错误）
// ==========================================

%ctor {
    NSLog(@"[AdBlocker] Ad-blocking tweak loaded successfully!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                }
                if (keyWindow) break;
            }
        }
        
        if (!keyWindow) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
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