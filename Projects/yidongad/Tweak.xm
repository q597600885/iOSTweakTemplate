#import <UIKit/UIKit.h>

// ============================================================================
// 1. 动态拦截控制器层开屏 (针对 UIViewController)
// ============================================================================

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    
    // 匹配中国移动自研开屏控制器的常见命名特征
    if ([className containsString:@"Splash"] || 
        [className containsString:@"LaunchAd"] || 
        [className containsString:@"CMStartAd"] || 
        [className containsString:@"CMAdvertView"]) {
        
        // 过滤系统原生类 (如苹果账号登录页 PSAppleIDSplashViewController)
        if (![className hasPrefix:@"PS"] && ![className hasPrefix:@"AK"] && ![className hasPrefix:@"UI"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 强制关闭开屏控制器
                [self dismissViewControllerAnimated:NO completion:nil];
            });
        }
    }
}

%end


// ============================================================================
// 2. 动态拦截视图层开屏 (针对直接挂载到 Window 上的 UIView)
// ============================================================================

%hook UIView

- (void)didMoveToWindow {
    %orig;
    
    if (self.window) {
        NSString *className = NSStringFromClass([self class]);
        
        // 匹配挂载在窗口上的开屏广告 View
        if ([className containsString:@"CMSplash"] || 
            [className containsString:@"CMLaunchAd"] || 
            [className containsString:@"CMStartAd"] || 
            [className containsString:@"CMAdvertView"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 1. 尝试触发跳过方法
                if ([self respondsToSelector:@selector(skipAction:)]) {
                    [self performSelector:@selector(skipAction:) withObject:nil];
                } else if ([self respondsToSelector:@selector(skipButtonTapped:)]) {
                    [self performSelector:@selector(skipButtonTapped:) withObject:nil];
                } else if ([self respondsToSelector:@selector(closeSplash)]) {
                    [self performSelector:@selector(closeSplash)];
                } else {
                    // 2. 兜底方案：直接从父视图移除
                    [self removeFromSuperview];
                }
            });
        }
    }
}

%end


// ============================================================================
// 3. 首次注入成功提示框 (仅首次提示一次)
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

static void showInjectAlertIfNeeded(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *const kHasShownKey = @"HasShownChinaMobileAdBlockAlert_Key";

    if ([defaults boolForKey:kHasShownKey]) {
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"中国移动内部开屏去广告插件已成功注入！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:^(UIAlertAction * _Nonnull action) {
            [defaults setBool:YES forKey:kHasShownKey];
            [defaults synchronize];
        }];

        [alert addAction:okAction];
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================================
// 4. Tweak 入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
