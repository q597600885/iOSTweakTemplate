#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (避免 Clang 编译器 Forward Declaration 报错)
// ============================================================================

@interface CMAdvertModel : NSObject
@property (nonatomic, retain) NSString *imageUrl;
@property (nonatomic, retain) NSString *smallImageUrl;
@property (nonatomic, retain) NSString *actionUrl;
@property (nonatomic, retain) NSString *linkUrl;
@end


// ============================================================================
// 2. 中国移动 CMAdvertModel 广告数据模型拦截
// ============================================================================

%hook CMAdvertModel

// 拦截并清空广告图片 URL，UI 拿不到图片资源会自动取消渲染
- (NSString *)imageUrl {
    return nil;
}

- (NSString *)smallImageUrl {
    return nil;
}

// 清空各类变体广告图片字段 (vImage3 ~ vImage8)
- (NSString *)vImage3 { return nil; }
- (NSString *)vImage4 { return nil; }
- (NSString *)vImage5 { return nil; }
- (NSString *)vImage6 { return nil; }
- (NSString *)vImage7 { return nil; }
- (NSString *)vImage8 { return nil; }

// 清空广告跳转链接，防止用户误触
- (NSString *)actionUrl {
    return nil;
}

- (NSString *)linkUrl {
    return nil;
}

%end


// ============================================================================
// 3. UI 弹窗辅助函数 (仅首次注入成功后提示一次)
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

    // 读取本地持久化标志：若已弹过窗则静默跳过
    if ([defaults boolForKey:kHasShownKey]) {
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"中国移动去广告插件已成功注入！"
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
// 4. Tweak 构造入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
