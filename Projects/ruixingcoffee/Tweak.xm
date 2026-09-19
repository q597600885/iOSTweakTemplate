#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

// 🌟 核心魔法：直接让编译器忽略“未使用函数”的警告，坚决不运行耗时扫描！
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

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
// 2. 开屏广告：逻辑层 0 毫秒击杀
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
// 3. H5 与原生营销弹窗拦截
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
- (void)show { TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinExclusiveCouponPopView show！"); }
- (void)showInView:(id)view { TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinExclusiveCouponPopView showInView！"); }
- (void)layoutSubviews { %orig; self.hidden = YES; }
%end

%hook LuckinMenuRewardPopView
- (void)show { TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinMenuRewardPopView show！"); }
- (void)showInView:(id)view { TweakLog(LOG_TAG, @"[Hook] 拦截 LuckinMenuRewardPopView showInView！"); }
- (void)layoutSubviews { %orig; self.hidden = YES; }
%end

// ============================================================================
// 4. 模块就绪日志 (去除了所有耗时的盲搜代码)
// ============================================================================

%ctor {
    // 仅保留极其轻量级的文本清空操作
    ResetDebugLog(LOG_TAG);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸【开屏秒进 + 弹窗全杀】极致性能版已就绪！");
    }];
}

// 恢复编译器的警告设置
#pragma clang diagnostic pop
