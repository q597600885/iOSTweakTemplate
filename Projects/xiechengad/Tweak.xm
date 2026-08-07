#import <UIKit/UIKit.h>

// ============================================================================
// 前置接口声明：解决 Clang 编译器 Forward Declaration 编译报错
// ============================================================================

@interface TripMobSplashView : UIView
@property (nonatomic) unsigned long long duration;
- (void)skipViewTap:(id)sender;
@end


// ============================================================================
// TripMobSplashView Hook 逻辑
// ============================================================================

%hook TripMobSplashView

// 1. 强制把开屏广告时长设置为 0 秒
- (void)setDuration:(unsigned long long)duration {
    %orig(0);
}

// 2. 当开屏视图挂载到窗口时，在主线程下一帧立即自动触发“跳过”按钮点击
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
