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
// 3. 12306 首页 Banner 广告终极完美切割 (动态保留垫片，剔除广告)
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
    // 抽掉底色，防止留下色块
    self.backgroundColor = [UIColor clearColor];
    
    // 动态计算目标高度：只保留顶部搜索栏的安全距离
    CGFloat targetHeight = 0;
    
    // 方案 A：如果内部广告视图(scrollView)有 Y 轴偏移，这个偏移量通常就是精准的顶部防遮挡垫片高度
    if (self.scrollView && self.scrollView.frame.origin.y > 40.0) {
        targetHeight = self.scrollView.frame.origin.y;
    } 
    // 方案 B：如果拿不到，我们自动读取当前手机的刘海屏/状态栏高度 + 搜索栏标准高度进行智能兜底计算
    else {
        CGFloat statusBarHeight = 20.0;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (window.safeAreaInsets.top > 0) {
                statusBarHeight = window.safeAreaInsets.top;
            }
        }
        // 状态栏 + 搜索导航栏(44) + 恰到好处的阴影间距(约8)
        targetHeight = statusBarHeight + 44.0 + 8.0; 
    }
    
    // 如果当前高度包含广告（比纯垫片高度大），则执行精准切割
    if (self.frame.size.height > targetHeight + 10.0) {
        self.tag = 888; // 标记为已处理
        
        // 1. 修改实际 Frame
        CGRect frame = self.frame;
        frame.size.height = targetHeight;
        self.frame = frame;
        
        // 2. 修改 AutoLayout 约束（这一步最关键，防止滑动时乱跳）
        for (NSLayoutConstraint *constraint in self.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                constraint.constant = targetHeight;
            }
        }
        
        // 3. 通知父容器重新平滑排版
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
