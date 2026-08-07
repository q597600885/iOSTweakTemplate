#import <UIKit/UIKit.h>

// ============================================================================
// 💡 顶栏安全高度参数 (单位: pt)
// 175.0 可以把购票卡片整体往下拉，刚好避开悬浮搜索框。
// 如果编译后发现偏下，可稍微调小至 170.0；若还微卡搜索框，可调大至 180.0
// ============================================================================
#define kCustomTopHeight 175.0


// ============================================================================
// 1. 前置接口声明
// ============================================================================

@interface BonSplashAD : NSObject
@property (nonatomic) BOOL isADShowing;
@property (nonatomic) BOOL isSplashShowing;
- (void)btnSkipClick;
- (void)dismiss;
- (void)removeSpad;
@end

@interface MTBookTicketHomeTopADView : UIView
@property (nonatomic, retain) UIScrollView *scrollView;
@end


// ============================================================================
// 2. 12306 开屏广告拦截 (保持不变)
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
// 3. 12306 首页 Banner 广告精细化裁剪 (调大高度，彻底解决卡片上浮遮挡)
// ============================================================================

%hook MTBookTicketHomeTopADView

- (void)layoutSubviews {
    %orig;
    
    // 隐藏内部真正的广告容器，抽掉背景底色
    if (self.scrollView) {
        self.scrollView.hidden = YES;
    }
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat targetHeight = kCustomTopHeight;
    
    // 强制重置 Frame 与 AutoLayout 约束
    if (fabs(self.frame.size.height - targetHeight) > 1.0) {
        
        // 1. 修改 Frame 高度
        CGRect frame = self.frame;
        frame.size.height = targetHeight;
        self.frame = frame;
        
        // 2. 修改 AutoLayout 约束
        for (NSLayoutConstraint *constraint in self.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                constraint.constant = targetHeight;
            }
        }
        
        // 3. 驱动父视图重新计算布局
        UIView *parent = self.superview;
        if (parent) {
            [parent setNeedsLayout];
            [parent layoutIfNeeded];
        }
    }
}

// 彻底拦截广告数据网络请求
- (void)loadMaterialsList:(id)a0 withArriveStationCode:(id)a1 voiceOverStatus:(BOOL)a2 {
    %orig(nil, a1, a2);
}

- (void)creatADViewWithData:(id)a0 {
    %orig(nil);
}

- (void)initAnimationScrollTimerWithDuration:(double)a0 {
    return;
}

%end


// ============================================================================
// 4. UI 弹窗辅助函数
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
                                                                       message:@"12306 去广告插件已更新生效！"
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
