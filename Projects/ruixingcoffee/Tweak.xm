#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"LuckinAdBlock"

// ============================================================================
// 1. 接口与类声明
// ============================================================================

@interface LKAAdvertView : UIView
- (void)jumpClick;
- (void)endAction;
@end

// ============================================================================
// 2. 逻辑层 0 毫秒击杀 (LKAAdvertView)
// ============================================================================

%hook LKAAdvertView

// 阻断 1：拦截视图初始化，强行将视图宽高归零并隐藏
- (instancetype)initWithFrame:(CGRect)frame EndAdBlock:(id)block {
    self = %orig(CGRectZero, block);
    if (self) {
        self.hidden = YES;
        self.alpha = 0;
    }
    return self;
}

// 阻断 2：拦截广告网络请求源头，并在 0 毫秒瞬间主动调用“跳过”和“结束”逻辑
- (void)requestAdData {
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 requestAdData 广告请求！");
    
    // 模拟用户在 0 毫秒时疯狂点击了“跳过”按钮
    if ([self respondsToSelector:@selector(jumpClick)]) {
        TweakLog(LOG_TAG, @"[Action] 主动触发 jumpClick 跳过操作");
        [self jumpClick];
    }
    
    // 直接通知底层逻辑：广告已经播放结束，赶紧给我切主界面
    if ([self respondsToSelector:@selector(endAction)]) {
        TweakLog(LOG_TAG, @"[Action] 主动触发 endAction 结束操作");
        [self endAction];
    }
}

// 阻断 3：彻底废掉后台的倒计时器，杜绝任何延迟
- (void)startTimer {
    TweakLog(LOG_TAG, @"[Hook] 成功拦截并废弃了 startTimer 倒计时器！");
}

%end

// ============================================================================
// 3. 插件入口与日志初始化
// ============================================================================

%ctor {
    // 每次 App 冷启动，清空之前的沙盒日志
    ResetDebugLog(LOG_TAG);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸秒进去广告插件加载完毕！0 毫秒无损耗版已就绪！");
    }];
}
