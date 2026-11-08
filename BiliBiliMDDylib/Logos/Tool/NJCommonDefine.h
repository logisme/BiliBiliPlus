//
//  NJCommonDefine.h
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/6/13.
//

#import <UIKit/UIKit.h>
#import "NJAsset.h"
#import "NJCommonDefineForSwift.h"
#import "NJSettingCache.h"
#import "BFCAccountUserModel.h"

NS_ASSUME_NONNULL_BEGIN


/// 图片资源路径
#define NJ_IMAGE_ASSET_PATH(path) [NJAsset pathForImageAsset:path]
/// 资源路径
#define NJ_ASSET_PATH(path) [NJAsset pathForAsset:path]

/// --------------------- 用户信息 ---------------------
/// BFCUserModel
/// BFCAccountUserModel

@interface BBMallAccountManager : NSObject

@property (readonly, nonatomic) BFCAccountUserModel *userModel;
@property (readonly, copy, nonatomic) NSString *userId;

+ (id)defaultManager;

@end

#define NJ_MID [[[NSClassFromString(@"BBMallAccountManager") defaultManager] userModel] mid]
#define NJ_MID_STR [NSString stringWithFormat:@"%lld", NJ_MID]

#define NJ_UID NJ_MID
#define NJ_UID_STR NJ_MID_STR

/// --------------------- 用户信息 ---------------------



/// --------------------- 设置页面 ---------------------
/// 总开关
#define NJ_MASTER_SWITCH_KEY @"NJ_MASTER_SWITCH_KEY"
/// 总开关的值（默认开启）
#define NJ_MASTER_SWITCH_VALUE ([[NJSettingCache sharedInstance] boolForKey:NJ_MASTER_SWITCH_KEY \
                                                                defaultValue:YES])

/// 底部栏-发布(+)
#define NJ_PUBLISH_KEY @"NJ_PUBLISH_KEY"
/// 底部栏-发布(+)的值（默认关闭）
#define NJ_PUBLISH_VALUE ([[NJSettingCache sharedInstance] boolForKey:NJ_PUBLISH_KEY \
                                                              defaultValue:NO])

/// 底部栏-会员购
#define NJ_MALL_KEY @"NJ_MALL_KEY"
/// 底部栏-会员购的值（默认关闭）
#define NJ_MALL_VALUE ([[NJSettingCache sharedInstance] boolForKey:NJ_MALL_KEY \
                                                          defaultValue:NO])

/// 我的-不常用服务
#define NJ_UNUSED_SERVICE_KEY @"NJ_UNUSED_SERVICE_KEY"
/// 我的-不常用服务的值（默认关闭）
#define NJ_UNUSED_SERVICE_VALUE ([[NJSettingCache sharedInstance] boolForKey:NJ_UNUSED_SERVICE_KEY \
                                                                      defaultValue:NO])

/// 大会员福利（卡券）领取类型，0=不领取
#define NJ_COUPON_TYPE_VALUE ([[NJSettingCache sharedInstance] couponType])

/// 大会员福利类型
/// 0：不领取
/// 1：B币券
/// 14：观影券
#define NJ_COUPON_TYPE_NONE 0
#define NJ_COUPON_TYPE_B_COIN 1
#define NJ_COUPON_TYPE_MOVIE 14

/// 竖屏模式
#define NJ_VERTICAL_SCREEN_MODE_KEY @"NJ_VERTICAL_SCREEN_MODE_KEY"
/// 竖屏模式的值（默认关闭）
#define NJ_VERTICAL_SCREEN_MODE_VALUE ([[NJSettingCache sharedInstance] boolForKey:NJ_VERTICAL_SCREEN_MODE_KEY \
                                                                          defaultValue:NO])

/// --------------------- 设置页面 ---------------------

/// --------------------- 单例 ---------------------

// .h头文件中的单例宏
#define NJ_SINGLETON_H(name) \
+ (instancetype)shared##name;

// .m文件中的单例宏
#define NJ_SINGLETON_M(name) \
static id _instance; \
+ (instancetype)allocWithZone:(struct _NSZone *)zone { \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        _instance = [super allocWithZone:zone]; \
    }); \
    return _instance; \
} \
+ (instancetype)shared##name { \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        _instance = [[self alloc] init]; \
    }); \
    return _instance; \
} \
- (id)copyWithZone:(NSZone *)zone { \
    return _instance; \
} \
- (id)mutableCopyWithZone:(nullable NSZone *)zone { \
    return _instance; \
} \

/// --------------------- 单例 ---------------------

NS_ASSUME_NONNULL_END
