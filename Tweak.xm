#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/runtime.h>

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[TiebaAdFree] ctor loaded.");
        
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
                        if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || [className containsString:@"Advert"]) {
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
