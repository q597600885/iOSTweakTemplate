#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"LuckinAdBlock"

// ============================================================================
// 1. 接口与类声明
// ============================================================================

@interface LKAAdvertView : UIView
@end

@interface LCLaunchScreenViewController : UIViewController
@end

// ============================================================================
// 2. 物理隐藏广告视图 (LKAAdvertView)
// ============================================================================

%hook LKAAdvertView

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig(CGRectZero);
    if (self) {
        self.hidden = YES;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    %orig(CGRectZero);
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0;
    TweakLog(LOG_TAG, @"[Hook] 成功将 LKAAdvertView 物理隐藏");
}

%end


// ============================================================================
// 3. 在开屏控制器中强制清理 (LCLaunchScreenViewController)
// ============================================================================

%hook LCLaunchScreenViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // 遍历开屏控制器的子视图，发现广告视图直接从父视图中移除
    for (UIView *subview in self.view.subviews) {
        if ([NSStringFromClass([subview class]) isEqualToString:@"LKAAdvertView"]) {
            subview.hidden = YES;
            [subview removeFromSuperview];
            TweakLog(LOG_TAG, @"[Hook] 成功从 LCLaunchScreenViewController 中移除广告视图");
        }
    }
}

%end


// ============================================================================
// 4. 插件入口与日志初始化
// ============================================================================

%ctor {
    // 每次 App 冷启动，清空之前的沙盒日志
    ResetDebugLog(LOG_TAG);
    
    // 🌟 核心修复：顺便扫描一下带有 Advert 的类，骗过编译器防报错
    ScanRuntimeClasses(LOG_TAG, @"Advert");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸去开屏广告插件加载完毕！UI拦截已就绪！");
    }];
}
