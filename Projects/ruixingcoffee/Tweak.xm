#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"LuckinAdBlock"

// ============================================================================
// 1. 辅助分析工具：提取运行时的所有内部方法
// ============================================================================

static void PrintClassMethods(NSString *className) {
    TweakLog(LOG_TAG, @"========== 提取 [%@] 的所有内部方法 ==========", className);
    Class cls = NSClassFromString(className);
    if (!cls) {
        TweakLog(LOG_TAG, @"未找到类: %@", className);
        return;
    }
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned int i = 0; i < count; i++) {
        SEL sel = method_getName(methods[i]);
        TweakLog(LOG_TAG, @"[Method] %@", NSStringFromSelector(sel));
    }
    free(methods);
}

// ============================================================================
// 2. 接口与类声明
// ============================================================================

@interface LKAAdvertView : UIView
@end

@interface LCLaunchScreenViewController : UIViewController
@end

// ============================================================================
// 3. 临时物理隐藏 (保证测试时眼前清爽)
// ============================================================================

%hook LKAAdvertView
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

// ============================================================================
// 4. 插件入口与探针执行
// ============================================================================

%ctor {
    // 每次冷启动清空旧日志
    ResetDebugLog(LOG_TAG);
    
    // ⭐️ 核心探针 1：打印控制器和视图的所有方法，寻找"跳过(skip)"、"关闭(close/dismiss)"函数的真名
    PrintClassMethods(@"LCLaunchScreenViewController");
    PrintClassMethods(@"LKAAdvertView");
    
    // ⭐️ 核心探针 2：上次只搜了 Advert，这次补搜一下 Splash (开屏) 相关的隐藏类
    ScanRuntimeClasses(LOG_TAG, @"Splash");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 瑞幸跳过方法探针已启动，正在疯狂提取数据...");
    }];
}
