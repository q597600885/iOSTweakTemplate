#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>


%ctor {

    NSLog(@"[AtourAdFree] Inject Success");


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{


        Class launchVCClass = NSClassFromString(@"你的启动广告类名");


        if (launchVCClass) {


            NSLog(@"[AtourAdFree] Found Launch VC");


            Method originalMethod =
            class_getInstanceMethod(
                launchVCClass,
                @selector(viewDidLoad)
            );


            if(originalMethod){


                IMP originalImp =
                method_getImplementation(originalMethod);


                void (*originalTyped)(id,SEL)
                =
                (void (*)(id,SEL))
                originalImp;



                IMP newImp =
                imp_implementationWithBlock(
                ^void(id self){


                    originalTyped(self,@selector(viewDidLoad));


                    NSLog(@"[AtourAdFree] Skip Splash");


                    UIViewController *vc=(UIViewController *)self;


                    dispatch_after(
                    dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(0.1*NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{


                        [vc dismissViewControllerAnimated:NO completion:nil];


                    });


                });



                method_setImplementation(
                    originalMethod,
                    newImp
                );


            }

        }


    });


}
