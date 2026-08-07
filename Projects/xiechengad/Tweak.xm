#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (避免 Clang 报 Forward Declaration 错误)
// ============================================================================

@interface TripMobSplashView : UIView
@property (nonatomic) unsigned long long duration;
- (void)skipViewTap:(id)sender;
@end


// ============================================================================
// 2. 携程开屏广告 Hook 逻辑 (倒计时清零 + 挂载瞬间跳过)
// ============================================================================

%hook TripMobSplashView

- (void)setDuration:(unsigned long long)duration {
    %orig(0);
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self respondsToSelector:@selector(skipViewTap:)]) {
                [self skipViewTap:nil];
            }
        });
    }
}

%end


// ============================================================================
// 3. UI 弹窗辅助函数 (已解决 iOS 13 弃用警告与 Unused 报错)
// ============================================================================

static UIViewController *getTopViewController(void) {
    __block UIWindow *keyWindow = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
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
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
#pragma clang diagnostic pop

    UIViewController *topViewController = keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = [(UINavigationController *)topViewController visibleViewController];
    } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
        topViewController = [(UITabBarController *)topViewController selectedViewController];
    }
    
    return topViewController;
}

static void showInjectAlert(void) {
    // 延迟 1.2 秒等待主界面加载完毕后再弹窗
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"携程去开屏广告插件已成功注入！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];

        [topVC presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================================
// 4. Tweak 构造入口 (注册启动通知触发弹窗)
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlert();
    }];
}
