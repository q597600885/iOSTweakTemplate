#import <UIKit/UIKit.h>

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
// 3. 12306 首页 Banner 广告终极完美切割 (修复 keyWindow 编译报错)
// ============================================================================

%hook MTBookTicketHomeTopADView

- (void)layoutSubviews {
    %orig;
    
    // 防止循环触发布局重绘
    if (self.tag == 888) return;
    
    // 隐藏内部的广告容器
    if (self.scrollView) {
        self.scrollView.hidden = YES;
    }
    self.backgroundColor = [UIColor clearColor];
    
    // 动态计算目标高度：只保留顶部搜索栏的安全距离
    CGFloat targetHeight = 0;
    
    // 方案 A：如果内部广告视图(scrollView)有 Y 轴偏移，以此为准
    if (self.scrollView && self.scrollView.frame.origin.y > 40.0) {
        targetHeight = self.scrollView.frame.origin.y;
    } 
    // 方案 B：直接读取自身 window 属性，完美避开 UIApplication keyWindow 废弃警告
    else {
        CGFloat statusBarHeight = 20.0;
        if (self.window && self.window.safeAreaInsets.top > 0) {
            statusBarHeight = self.window.safeAreaInsets.top;
        }
        // 状态栏 + 搜索导航栏(44) + 恰到好处的阴影间距(约8)
        targetHeight = statusBarHeight + 44.0 + 8.0; 
    }
    
    // 如果当前高度包含广告，则执行精准切割
    if (self.frame.size.height > targetHeight + 10.0) {
        self.tag = 888; // 标记为已处理
        
        CGRect frame = self.frame;
        frame.size.height = targetHeight;
        self.frame = frame;
        
        for (NSLayoutConstraint *constraint in self.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                constraint.constant = targetHeight;
            }
        }
        
        UIView *parent = self.superview;
        if (parent) {
            [parent setNeedsLayout];
            [parent layoutIfNeeded];
        }
    }
}

// 彻底拦截数据网络请求，节省流量和内存
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
// 4. UI 弹窗辅助函数 (已包含严格的 pragma 压制，不影响编译)
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
                                                                       message:@"12306 终极版去广告已生效，首页排版已完美修复！"
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
