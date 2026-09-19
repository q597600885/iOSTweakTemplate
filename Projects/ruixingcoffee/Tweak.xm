#import <UIKit/UIKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#import "Includes/Debug.h"
#pragma clang diagnostic pop

#define LOG_TAG @"LuckinAdBlock"

// ============================================================================
// 1. 接口与类声明
// ============================================================================

@interface LKAAdvertView : UIView
- (void)jumpClick;
- (void)endAction;
@end

@interface LCWebPopupContainerViewController : UIViewController
@end

@interface LuckinExclusiveCouponPopView : UIView
- (void)show;
- (void)showInView:(id)view;
@end

@interface LuckinMenuRewardPopView : UIView
- (void)show;
- (void)showInView:(id)view;
@end

// ============================================================================
// 2. 开屏广告拦截 (0 毫秒跳过)
// ============================================================================

%hook LKAAdvertView

- (instancetype)initWithFrame:(CGRect)frame EndAdBlock:(id)block {
    self = %orig(CGRectZero, block);
    if (self) {
        self.hidden = YES;
        self.alpha = 0;
    }
    return self;
}

- (void)requestAdData {
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 requestAdData 开屏广告请求！");
    if ([self respondsToSelector:@selector(jumpClick)]) {
        TweakLog(LOG_TAG, @"[Action] 主动触发 jumpClick 跳过开屏");
        [self jumpClick];
    }
    if ([self respondsToSelector:@selector(endAction)]) {
        TweakLog(LOG_TAG, @"[Action] 主动触发 endAction 结束开屏");
        [self endAction];
    }
}

- (void)startTimer {
    TweakLog(LOG_TAG, @"[Hook] 成功废弃 startTimer 开屏倒计时器！");
}

%end

// ============================================================================
// 3. H5 与原生营销弹窗拦截 (标准分行书写，消除语法解析错误)
// ============================================================================

%hook LCWebPopupContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 LCWebPopupContainerViewController (H5活动弹窗)！");
    
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:NO completion:nil];
        TweakLog(LOG_TAG, @"[Action] 主动销毁 H5 弹窗控制器");
    }
}

%end

%hook LuckinExclusiveCouponPopView

- (void)show {
    TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinExclusiveCouponPopView show！");
}

- (void)showInView:(id)view {
    TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinExclusiveCouponPopView showInView！");
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}

%end

%hook LuckinMenuRewardPopView

- (void)show {
    TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinMenuRewardPopView show！");
}

- (void)showInView:(id)view {
    TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinMenuRewardPopView showInView！");
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}

%end

// ============================================================================
// 4. 插件入口与轻量初始化
// ============================================================================

%ctor {
    ResetDebugLog(LOG_TAG);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸【开屏秒进 + 弹窗全杀】极速稳定版加载完成！");
    }];
}
