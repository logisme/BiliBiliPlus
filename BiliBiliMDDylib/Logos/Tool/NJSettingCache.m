//
//  NJSettingCache.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/17.
//

#import "NJSettingCache.h"

/// 默认播放速度
#define NJ_SETTING_DEFAULT_PLAYBACK_RATE_KEY @"SETTING_DEFAULT_PLAYBACK_RATE"
#define NJ_SETTING_DEFAULT_PLAYBACK_RATE_VALUE @"1.0"
/// 关注的默认版块
#define NJ_SETTING_FOLLOW_DEFAULT_TAB_KEY @"SETTING_FOLLOW_DEFAULT_TAB"
#define NJ_SETTING_FOLLOW_DEFAULT_TAB_VALUE @"all"
/// 大会员福利（卡券）领取类型
#define NJ_SETTING_COUPON_TYPE_KEY @"NJ_COUPON_TYPE_KEY"

@implementation NJSettingCache

#pragma mark - Life Cycle Methods

+ (instancetype)sharedInstance {
    static NJSettingCache *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NJSettingCache alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Override Methods

#pragma mark - Public Methods

#pragma mark 开关设置

/// 读取开关设置
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (![value isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return [value boolValue];
}

/// 保存开关设置
- (void)saveBool:(BOOL)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
}

#pragma mark 大会员福利（卡券）领取类型

/// 大会员福利（卡券）领取类型
- (NSInteger)couponType {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:NJ_SETTING_COUPON_TYPE_KEY];
    if (![value isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    return [value integerValue];
}

/// 保存大会员福利（卡券）领取类型
- (void)saveCouponType:(NSInteger)type {
    [[NSUserDefaults standardUserDefaults] setInteger:type
                                               forKey:NJ_SETTING_COUPON_TYPE_KEY];
}

#pragma mark 默认播放速度

/// 获取默认播放速度
- (NSString *)defaultPlaybackRate {
    NSString *rate = [[NSUserDefaults standardUserDefaults] stringForKey:NJ_SETTING_DEFAULT_PLAYBACK_RATE_KEY];
    // 使用默认值
    if (rate.length == 0) {
        rate = NJ_SETTING_DEFAULT_PLAYBACK_RATE_VALUE;
        // 保存
        [[NSUserDefaults standardUserDefaults] setObject:rate
                                                  forKey:NJ_SETTING_DEFAULT_PLAYBACK_RATE_KEY];
    }
    return rate;
}

/// 获取默认播放速度
- (double)defaultPlaybackRateValue {
    return [[self defaultPlaybackRate] doubleValue];
}

/// 保存默认播放速度
- (void)saveDefaultPlaybackRate:(NSString *)rate {
    [[NSUserDefaults standardUserDefaults] setObject:rate
                                              forKey:NJ_SETTING_DEFAULT_PLAYBACK_RATE_KEY];
}

#pragma mark 关注的默认版块

/// 关注的默认版块
- (NSString *)followDefaultTab {
    NSString *tab = [[NSUserDefaults standardUserDefaults] stringForKey:NJ_SETTING_FOLLOW_DEFAULT_TAB_KEY];
    // 使用默认值
    if (tab.length == 0) {
        tab = NJ_SETTING_FOLLOW_DEFAULT_TAB_VALUE;
        // 保存
        [[NSUserDefaults standardUserDefaults] setObject:tab
                                                  forKey:NJ_SETTING_FOLLOW_DEFAULT_TAB_KEY];
    }
    return tab;
}

/// 保存关注的默认版块
- (void)saveFollowDefaultTab:(NSString *)tab {
    [[NSUserDefaults standardUserDefaults] setObject:tab
                                              forKey:NJ_SETTING_FOLLOW_DEFAULT_TAB_KEY];
}

#pragma mark - Private Methods

#pragma mark - Property Methods
@end
