#import <UIKit/UIKit.h>
#import <substrate.h>

// ==========================================
// 1. C 函数定义 (用于替换 Swift 广告加载器回调)
// ==========================================

// TopOn 广告加载拦截
static void (*orig_Topon_didFinish)(id self, SEL _cmd, id placementID);
static void new_Topon_didFinish(id self, SEL _cmd, id placementID) {
    id slf = self;
    if ([slf respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        [slf didFailToLoadADWithPlacementID:placementID error:nil];
    }
}

// 穿山甲 / GMSelfDraw 广告加载拦截
static void (*orig_GM_success)(id self, SEL _cmd, id manager, id ads);
static void new_GM_success(id self, SEL _cmd, id manager, id ads) {
    id slf = self;
    if ([slf respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
        [slf nativeAdsManager:manager didFailWithError:nil];
    }
}

// 广告 Cell 尺寸强制归零 (防止 CollectionView 留空)
static CGSize (*orig_Cell_sizeThatFits)(id self, SEL _cmd, CGSize size);
static CGSize new_Cell_sizeThatFits(id self, SEL _cmd, CGSize size) {
    return CGSizeZero;
}

// Admin Info 广告 Cell 尺寸强制归零
static CGSize (*orig_AdminCell_sizeThatFits)(id self, SEL _cmd, CGSize size);
static CGSize new_AdminCell_sizeThatFits(id self, SEL _cmd, CGSize size) {
    return CGSizeZero;
}


// ==========================================
// 2. 运行时入口：%ctor 动态抓取 Swift 类并进行 Hook
// ==========================================

%ctor {
    @autoreleasepool {
        // 1. Hook TopOn 广告加载器
        Class toponCls = objc_getClass("CoolMarket.GeneralEntityListFeedAdvertisementLoader_Topon");
        if (toponCls) {
            MSHookMessageEx(
                toponCls, 
                @selector(didFinishLoadingADWithPlacementID:), 
                (IMP)&new_Topon_didFinish, 
                (IMP*)&orig_Topon_didFinish
            );
        }

        // 2. Hook GMSelfDraw 广告加载器
        Class gmCls = objc_getClass("CoolMarket.GeneralEntityListFeedAdvertisementLoader_GMSelfDraw");
        if (gmCls) {
            MSHookMessageEx(
                gmCls, 
                @selector(nativeAdsManagerSuccessToLoad:nativeAds:), 
                (IMP)&new_GM_success, 
                (IMP*)&orig_GM_success
            );
        }

        // 3. Hook 广告 Cell 尺寸
        Class cellCls = objc_getClass("CoolMarket.GeneralEntityListFeedAdvertisementCellBaseV4");
        if (cellCls) {
            MSHookMessageEx(
                cellCls, 
                @selector(sizeThatFits:), 
                (IMP)&new_Cell_sizeThatFits, 
                (IMP*)&orig_Cell_sizeThatFits
            );
        }

        // 4. Hook Admin Cell 尺寸
        Class adminCellCls = objc_getClass("CoolMarket.GeneralEntityListFeedAdvertisementAdminInfoCell");
        if (adminCellCls) {
            MSHookMessageEx(
                adminCellCls, 
                @selector(sizeThatFits:), 
                (IMP)&new_AdminCell_sizeThatFits, 
                (IMP*)&orig_AdminCell_sizeThatFits
            );
        }
    }
}


// ==========================================
// 3. 标准 ObjC 开屏跳过逻辑
// ==========================================

%hook CoolMarketSplashViewController

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    
    id slf = self;
    if ([slf respondsToSelector:@selector(skipAd)]) {
        [slf performSelector:@selector(skipAd)];
    } else if ([slf respondsToSelector:@selector(dismissSplash)]) {
        [slf performSelector:@selector(dismissSplash)];
    }
}

%end
