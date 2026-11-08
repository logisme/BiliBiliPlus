//
//  NJSettingCache.h
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NJSettingCache : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 读取开关设置
/// - Parameters:
///   - key: 设置的key
///   - defaultValue: 没有保存过时的默认值
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;

/// 保存开关设置
- (void)saveBool:(BOOL)value forKey:(NSString *)key;

/// 大会员福利（卡券）领取类型
/// 0：不领取；1：B币券；14：观影券
- (NSInteger)couponType;

/// 保存大会员福利（卡券）领取类型
- (void)saveCouponType:(NSInteger)type;

/// 获取默认播放速度
- (NSString *)defaultPlaybackRate;

/// 获取默认播放速度
- (double)defaultPlaybackRateValue;

/// 保存默认播放速度
- (void)saveDefaultPlaybackRate:(NSString *)rate;

/// 关注的默认版块
- (NSString *)followDefaultTab;

/// 保存关注的默认版块
- (void)saveFollowDefaultTab:(NSString *)tab;

@end

NS_ASSUME_NONNULL_END
