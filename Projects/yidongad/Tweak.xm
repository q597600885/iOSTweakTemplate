#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (告知编译器 CMStartViewController 的方法，防止报错)
// ============================================================================

@interface CMStartViewController : UIViewController
@property (nonatomic) BOOL isOpenScreenAdvertising;
- (BOOL)isNeedSkipStartAd;
- (void)skipStartViewAndEnterMainPage;
- (void)skipPressed:(id)sender;
@end


// ============================================================================
// 2. 中国移动 CMStartViewController 精准开屏拦截 (秒过 + 防闪退)
// ============================================================================

%hook CMStartViewController

// 强制标识需要跳过开屏广告
- (BOOL)isNeedSkipStartAd {
    return YES;
}

// 强制关闭开屏广告开关
- (BOOL)isOpenScreenAdvertising {
    return NO;
}

// 控制器加载完毕后，在下一帧直接触发原生“跳过并进入主页”
- (void)viewDidLoad {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self respondsToSelector:@selector(skipStartViewAndEnterMainPage)]) {
            [self skipStartViewAndEnterMainPage];
        } else if ([self respondsToSelector:@selector(skipPressed:)]) {
            [self skipPressed:nil];
        }
    });
}

%end


// ============================================================================
// 3. 首次注入成功提示框 (仅首次安装提示一次，确定后永不再弹)
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

    // 读取本地持久化标志：若已弹过窗则直接返回
    if ([defaults boolForKey:kHasShownKey]) {
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"中国移动去开屏广告插件已成功生效！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:^(UIAlertAction * _Nonnull action) {
            // 点击确定后写入标记并同步保存
            [defaults setBool:YES forKey:kHasShownKey];
            [defaults synchronize];
        }];

        [alert addAction:okAction];
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================================
// 4. Tweak 启动入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
