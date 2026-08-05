#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <objc/runtime.h>

@interface TiebaAdFreePatch : NSObject
@end

@implementation TiebaAdFreePatch

+ (void)load {
    NSLog(@"[TiebaAdFree] Loaded successfully. Hooking splash and advertisement components...");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. 尝试拦截贴吧常见的开屏广告及闪屏视图类
        NSArray *splashClassNames = @[@"TBSplashViewController", @"TBOriginalSplashView", @"TBCSplashView", @"AdSplashViewController", @"TBAdSplashManager"];
        for (NSString *className in splashClassNames) {
            Class cls = NSClassFromString(className);
            if (cls) {
                NSLog(@"[TiebaAdFree] Found splash class: %@. Hooking viewDidLoad...", className);
                Method method = class_getInstanceMethod(cls, @selector(viewDidLoad));
                if (method) {
                    IMP originalImp = method_getImplementation(method);
                    void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
                    
                    IMP newImp = imp_implementationWithBlock(^void(id self) {
                        originalTyped(self, @selector(viewDidLoad));
                        NSLog(@"[TiebaAdFree] %@ viewDidLoad called. Dismissing instantly...", className);
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            UIViewController *vc = (UIViewController *)self;
                            [vc.view removeFromSuperview];
                            if ([vc respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                                [vc dismissViewControllerAnimated:NO completion:nil];
                            }
                        });
                    });
                    method_setImplementation(method, newImp);
                }
            }
        }

        // 2. 全局 Window 巡查并抹除任何带有 Ad / Splash 的子视图
        Class windowClass = NSClassFromString(@"UIWindow");
        if (windowClass) {
            Method makeKeyMethod = class_getInstanceMethod(windowClass, @selector(makeKeyAndVisible));
            if (makeKeyMethod) {
                IMP originalImp = method_getImplementation(makeKeyMethod);
                void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
                
                IMP newImp = imp_implementationWithBlock(^void(id self) {
                    originalTyped(self, @selector(makeKeyAndVisible));
                    UIWindow *window = (UIWindow *)self;
                    for (UIView *subview in window.subviews) {
                        NSString *className = NSStringFromClass([subview class]);
                        if ([className containsString:@"Splash"] || [className containsString:@"AdSplash"] || ([className containsString:@"Ad"] && [className containsString:@"View"])) {
                            NSLog(@"[TiebaAdFree] Found suspicious window subview: %@. Hiding...", className);
                            subview.hidden = YES;
                            [subview removeFromSuperview];
                        }
                    }
                });
                method_setImplementation(makeKeyMethod, newImp);
            }
        }

    });
}

@end
