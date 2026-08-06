#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <objc/runtime.h>

@interface AtourAdFreePatch : NSObject
@end

@implementation AtourAdFreePatch

+ (void)load {
    NSLog(@"[AtourAdFree] Loaded successfully. Hooking startup / splash components...");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Hook 亚朵开屏专属视图 / 动画类：YDLaunchAnimationImageView
        Class launchAnimClass = NSClassFromString(@"YDLaunchAnimationImageView");
        if (launchAnimClass) {
            NSLog(@"[AtourAdFree] Found YDLaunchAnimationImageView! Hooking removeFromSuperview / init...");
            
            // 劫持 removeFromSuperview 让其直接移除
            Method removeFromSuperviewMethod = class_getInstanceMethod(launchAnimClass, @selector(removeFromSuperview));
            if (removeFromSuperviewMethod) {
                IMP originalImp = method_getImplementation(removeFromSuperviewMethod);
                void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
                
                IMP newImp = imp_implementationWithBlock(^void(id self) {
                    NSLog(@"[AtourAdFree] YDLaunchAnimationImageView removeFromSuperview intercepted.");
                    originalTyped(self, @selector(removeFromSuperview));
                });
                method_setImplementation(removeFromSuperviewMethod, newImp);
            }
            
            // 直接让这类在初始化时就自我销毁或隐藏
            Method initMethod = class_getInstanceMethod(launchAnimClass, @selector(initWithFrame:));
            if (initMethod) {
                IMP originalImp = method_getImplementation(initMethod);
                id (*originalTyped)(id, SEL, CGRect) = (id (*)(id, SEL, CGRect))originalImp;
                
                IMP newImp = imp_implementationWithBlock(^id(id self, CGRect frame) {
                    self = originalTyped(self, @selector(initWithFrame:), frame);
                    if (self) {
                        NSLog(@"[AtourAdFree] YDLaunchAnimationImageView initialized. Hiding immediately!");
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIView *view = (UIView *)self;
                            view.hidden = YES;
                            [view removeFromSuperview];
                        });
                    }
                    return self;
                });
                method_setImplementation(initMethod, newImp);
            }
        } else {
            NSLog(@"[AtourAdFree] YDLaunchAnimationImageView not found.");
        }

        // 2. Hook LaunchImageVC
        Class launchVCClass = NSClassFromString(@"LaunchImageVC");
        if (launchVCClass) {
            NSLog(@"[AtourAdFree] Found LaunchImageVC! Hooking viewDidLoad...");
            Method method = class_getInstanceMethod(launchVCClass, @selector(viewDidLoad));
            if (method) {
                IMP originalImp = method_getImplementation(method);
                void (*originalTyped)(id, SEL) = (void (*)(id, SEL))originalImp;
                
                IMP newImp = imp_implementationWithBlock(^void(id self) {
                    originalTyped(self, @selector(viewDidLoad));
                    NSLog(@"[AtourAdFree] LaunchImageVC loaded. Dismissing instantly...");
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        UIViewController *vc = (UIViewController *)self;
                        [vc.view removeFromSuperview];
                        if (vc.presentingViewController) {
                            [vc dismissViewControllerAnimated:NO completion:nil];
                        }
                    });
                });
                method_setImplementation(method, newImp);
            }
        }

        // 3. 通用全局 UIWindow 拦截开屏广告或闪屏覆盖层
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
                        if ([className containsString: @"Launch"] || [className containsString: @"Splash"] || [className containsString: @"Ad"]) {
                            NSLog(@"[AtourAdFree] Found suspicious window subview: %@. Hiding...", className);
                            subview.hidden = YES;
  
