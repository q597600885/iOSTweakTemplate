#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"LuckinAdBlock"

// ============================================================================
// 1. 接口与类声明 (核心修复：补齐类的继承关系，消除编译报错)
// ============================================================================

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
// 2. 核心拦截：H5 营销网页弹窗容器
// ============================================================================

%hook LCWebPopupContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    // 0 毫秒物理防漏：直接切断渲染，防止白屏闪烁
    self.view.hidden = YES;
    self.view.alpha = 0;
    
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 LCWebPopupContainerViewController (H5活动弹窗)！");
    
    // 0 毫秒逻辑击杀：模拟点击关闭，立刻销毁控制器，把焦点还给主界面
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:NO completion:nil];
        TweakLog(LOG_TAG, @"[Action] 主动触发 dismissViewController 销毁 H5 弹窗");
    }
}

%end

// ============================================================================
// 3. 备选拦截：原生专属新人礼/奖励弹窗 (防漏网之鱼)
// ============================================================================

%hook LuckinExclusiveCouponPopView

// 逻辑层：拦截自定义 View 的弹出方法，让它从根源无法触发
- (void)show {
    TweakLog(LOG_TAG, @"[Hook] 逻辑层拦截 LuckinExclusiveCouponPopView show 动作！");
}
- (void)showInView:(id)view {
    TweakLog(LOG_TAG, @"[Hook] 逻辑层拦截 LuckinExclusiveCouponPopView showInView 动作！");
}

// 物理层：兜底防漏，一旦尝试绘制直接隐藏
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

%hook LuckinMenuRewardPopView

- (void)show { TweakLog(LOG_TAG, @"[Hook] 逻辑层拦截 LuckinMenuRewardPopView show！"); }
- (void)showInView:(id)view { TweakLog(LOG_TAG, @"[Hook] 逻辑层拦截 LuckinMenuRewardPopView showInView！"); }

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

// ============================================================================
// 4. 模块就绪日志
// ============================================================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸网页活动弹窗/新人礼拦截模块已就绪！");
    }];
}
