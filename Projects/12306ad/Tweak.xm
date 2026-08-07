#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (避免 Clang 编译器 Forward Declaration 报错)
// ============================================================================

@interface BonSplashAD : NSObject
@property (nonatomic) BOOL isADShowing;
@property (nonatomic) BOOL isSplashShowing;
- (void)btnSkipClick;
- (void)dismiss;
- (void)removeSpad;
@end

@interface MTBookTicketHomeTopADView : UIView
@property (nonatomic, retain) NSArray *materialsList;
@end


// ============================================================================
// 2. 12306 开屏广告拦截 (BonSplashAD)
// ============================================================================

%hook BonSplashAD

- (BOOL)isADShowing {
    return NO;
}

- (BOOL)isSplashShowing {
    return NO;
}

- (void)addAdView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self respondsToSelector:@selector(btnSkipClick)]) {
            [self btnSkipClick];
        } else if ([self respondsToSelector:@selector(dismiss)]) {
            [self dismiss];
        } else if ([self respondsToSelector:@selector(removeSpad)]) {
            [self removeSpad];
        }
    });
}

- (void)BeiZi_splashDidPresentScreen:(id)a0 {
    if ([self respondsToSelector:@selector(btnSkipClick)]) {
        [self btnSkipClick];
    }
}

%end


// ============================================================================
// 3. 12306 预订首页顶部 Banner 广告拦截 (MTBookTicketHomeTopADView)
// ============================================================================

%hook MTBookTicketHomeTopADView

// 阻断素材加载：清空广告数据源
- (void)loadMaterialsList:(id)a0 withArriveStationCode:(id)a1 voiceOverStatus:(BOOL)a2 {
    %orig(nil, a1, a2);
}

// 阻断 UI 构建：传空数据
- (void)creatADViewWithData:(id)a0 {
    %orig(nil);
}

// 阻断定时器滚动，节省性能
- (void)initAnimationScrollTimerWithDuration:(double)a0 {
    return;
}

// 隐藏 View 实体，防止占位卡块
- (void)didMoveToWindow {
    %orig;
    self.hidden = YES;
    [self removeFromSuperview];
}

%end


// ============================================================================
// 4. UI 弹窗辅助函数 (仅首次提示一次)
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
    NSString *const kHasShownKey = @"HasShown12306AdBlockAlert_Key";

    if ([defaults boolForKey:kHasShownKey]) {
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"12306 去开屏及首页 Banner 广告插件已生效！"
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
// 5. Tweak 入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
