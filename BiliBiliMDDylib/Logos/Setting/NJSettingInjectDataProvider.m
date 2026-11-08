//
//  NJSettingInjectDataProvider.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/8/13.
//

#import "NJSettingInjectDataProvider.h"
#import "NJSettingSkullViewModel.h"
#import "NJSettingDefine.h"
#import "NJPluginInfo.h"
#import "NJSettingSwitchViewModel.h"
#import "NJCommonDefine.h"
#import "NJSettingCache.h"
#import "NJInlineSettingModel.h"
#import "UIColor+NJColor.h"

@implementation NJSettingInjectDataProvider


/// 要注入的数据
- (NSArray<NJSettingSkullViewModel *> *)injectDatas {
    NSMutableArray *datas = [NSMutableArray array];
    [datas addObject:[[NJSettingSwitchViewModel alloc] initWithBizId:NJ_MASTER_SWITCH_BIZ_ID
                                                           cellId:NJ_SWITCH_CELL_ID
                                                            title:@"总开关"
                                                                  on:NJ_MASTER_SWITCH_VALUE
                                                             saveKey:NJ_MASTER_SWITCH_KEY]];
    [datas addObject:[[NJSettingSwitchViewModel alloc] initWithBizId:NJ_PUBLISH_BIZ_ID
                                                           cellId:NJ_SWITCH_CELL_ID
                                                            title:@"底部栏-发布(+)"
                                                                  on:NJ_PUBLISH_VALUE saveKey:NJ_PUBLISH_KEY]];
    [datas addObject:[[NJSettingSwitchViewModel alloc] initWithBizId:NJ_MALL_BIZ_ID
                                                           cellId:NJ_SWITCH_CELL_ID
                                                            title:@"底部栏-会员购"
                                                                  on:NJ_MALL_VALUE saveKey:NJ_MALL_KEY]];
    [datas addObject:[self mineServices]];
    [datas addObject:[self defaultPlaybackRate]];
    [datas addObject:[self followDefaultTab]];
    [datas addObject:[self couponType]];
    [datas addObject:[[NJSettingSwitchViewModel alloc] initWithBizId:NJ_VERTICAL_SCREEN_MODE_BIZ_ID
                                                           cellId:NJ_SWITCH_CELL_ID
                                                            title:@"竖屏模式"
                                                                  on:NJ_VERTICAL_SCREEN_MODE_VALUE saveKey:NJ_VERTICAL_SCREEN_MODE_KEY]];
    [datas addObject:[[NJSettingSkullViewModel alloc] initWithBizId:NJ_SHARE_DATA_BIZ_ID
                                                             cellId:NJ_COMMON_CELL_ID
                                                              title:@"分享数据"]];
    [datas addObject:[self version]];
    [datas addObject:[self checkUpdate]];
    [datas addObject:[self bigPointSign]];
    [datas addObject:[self bigPointCenter]];
    [datas addObject:[[NJSettingSkullViewModel alloc] initWithBizId:NJ_OFFICIAL_WEBSITE_BIZ_ID
                                                             cellId:NJ_COMMON_CELL_ID
                                                              title:@"官网"]];
    [datas addObject:[[NJSettingSkullViewModel alloc] initWithBizId:NJ_UPSTREAM_WEBSITE_BIZ_ID
                                                             cellId:NJ_COMMON_CELL_ID
                                                              title:@"项目地址"]];
    // 按功能标题设置图标
    for (NJSettingSkullViewModel *model in datas) {
        model.iconName = [self iconNameForBizId:model.bizId];
    }
    return [datas copy];
}

/// 功能对应的图标（SF Symbols）
- (NSString *)iconNameForBizId:(NSString *)bizId {
    if ([bizId isEqualToString:NJ_MASTER_SWITCH_BIZ_ID]) {
        return @"power";
    }
    if ([bizId isEqualToString:NJ_PUBLISH_BIZ_ID]) {
        return @"plus.circle";
    }
    if ([bizId isEqualToString:NJ_MALL_BIZ_ID]) {
        return @"cart";
    }
    if ([bizId isEqualToString:NJ_UNUSED_SERVICE_BIZ_ID] ||
        [bizId isEqualToString:NJ_MINE_SERVICES_BIZ_ID]) {
        return @"square.grid.2x2";
    }
    if ([bizId isEqualToString:NJ_CHECK_UPDATE_BIZ_ID]) {
        return @"arrow.triangle.2.circlepath";
    }
    if ([bizId isEqualToString:NJ_BIG_POINT_SIGN_BIZ_ID]) {
        return @"star.circle";
    }
    if ([bizId isEqualToString:NJ_BIG_POINT_CENTER_BIZ_ID]) {
        return @"star.circle.fill";
    }
    if ([bizId isEqualToString:NJ_DEFAULT_PLAYBACK_RATE]) {
        return @"speedometer";
    }
    if ([bizId isEqualToString:NJ_FOLLOW_DEFAULT_TAB]) {
        return @"rectangle.stack";
    }
    if ([bizId isEqualToString:NJ_COUPON_TYPE_BIZ_ID]) {
        return @"tag";
    }
    if ([bizId isEqualToString:NJ_VERTICAL_SCREEN_MODE_BIZ_ID]) {
        return @"rectangle.portrait";
    }
    if ([bizId isEqualToString:NJ_SHARE_DATA_BIZ_ID]) {
        return @"square.and.arrow.up";
    }
    if ([bizId isEqualToString:NJ_APP_VERSION_BIZ_ID]) {
        return @"info.circle";
    }
    if ([bizId isEqualToString:NJ_OFFICIAL_WEBSITE_BIZ_ID]) {
        return @"globe";
    }
    if ([bizId isEqualToString:NJ_UPSTREAM_WEBSITE_BIZ_ID]) {
        return @"link";
    }
    return nil;
}

/// 默认播放速度
- (NJSettingSkullViewModel *)defaultPlaybackRate {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_DEFAULT_PLAYBACK_RATE
                                                                             cellId:NJ_ARROW_CELL_ID
                                                                              title:@"默认播放速度"];
    model.subTitle = [[NJSettingCache sharedInstance] defaultPlaybackRate];
    return model;
}

/// 关注页的默认版块
- (NJSettingSkullViewModel *)followDefaultTab {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_FOLLOW_DEFAULT_TAB
                                                                             cellId:NJ_ARROW_CELL_ID
                                                                              title:@"关注页的默认版块"];
    model.subTitle = [self followDefaultTabSubTitle];
    return model;
}

- (NSString *)followDefaultTabSubTitle {
    NSString *followDefaultTab = [[NJSettingCache sharedInstance] followDefaultTab];
    NSArray<NJInlineSettingModel *> *tabs = [self followTabs];
    for (NJInlineSettingModel *model in tabs) {
        if ([model.bizId isEqualToString:followDefaultTab]) {
            return model.title;
        }
    }
    return @"";
}

/// 关注的版块数据
- (NSArray<NJInlineSettingModel *> *)followTabs {
    NSMutableArray<NJInlineSettingModel *> *tabs = [NSMutableArray array];
    [tabs addObject:[[NJInlineSettingModel alloc] initWithTitle:@"全部" bizId:@"all" selected:NO]];
    [tabs addObject:[[NJInlineSettingModel alloc] initWithTitle:@"视频" bizId:@"video" selected:NO]];
    return [tabs copy];
}

/// 大会员福利领取类型
- (NJSettingSkullViewModel *)couponType {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_COUPON_TYPE_BIZ_ID
                                                                             cellId:NJ_ARROW_CELL_ID
                                                                              title:@"大会员福利"];
    model.subTitle = [self couponTypeSubTitle];
    return model;
}

- (NSString *)couponTypeSubTitle {
    switch (NJ_COUPON_TYPE_VALUE) {
        case NJ_COUPON_TYPE_B_COIN:
            return @"B币券";
        case NJ_COUPON_TYPE_MOVIE:
            return @"观影券";
        default:
            return @"不领取";
    }
}

/// 大会员福利可领取类型
- (NSArray<NJInlineSettingModel *> *)couponTypes {
    NSInteger couponType = NJ_COUPON_TYPE_VALUE;
    NSMutableArray<NJInlineSettingModel *> *types = [NSMutableArray array];
    [types addObject:[[NJInlineSettingModel alloc] initWithTitle:@"不领取"
                                                          bizId:[@(NJ_COUPON_TYPE_NONE) stringValue]
                                                       selected:couponType == NJ_COUPON_TYPE_NONE]];
    [types addObject:[[NJInlineSettingModel alloc] initWithTitle:@"B币券"
                                                          bizId:[@(NJ_COUPON_TYPE_B_COIN) stringValue]
                                                       selected:couponType == NJ_COUPON_TYPE_B_COIN]];
    [types addObject:[[NJInlineSettingModel alloc] initWithTitle:@"观影券"
                                                          bizId:[@(NJ_COUPON_TYPE_MOVIE) stringValue]
                                                       selected:couponType == NJ_COUPON_TYPE_MOVIE]];
    return [types copy];
}

/// 版本
- (NJSettingSkullViewModel *)version {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_APP_VERSION_BIZ_ID
                                                                             cellId:NJ_COMMON_CELL_ID
                                                                              title:@"版本"];
    model.subTitle = [NJPluginInfo versionInfo];
    return model;
}

/// 「我的」页面显示的服务
- (NJSettingSkullViewModel *)mineServices {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_MINE_SERVICES_BIZ_ID
                                                                             cellId:NJ_ARROW_CELL_ID
                                                                              title:@"我的-显示的服务"];
    NSUInteger selectedCount = [[[NJSettingCache sharedInstance] selectedMineServiceIds] count];
    model.subTitle = selectedCount == 0 ? @"全部隐藏" : [NSString stringWithFormat:@"已选 %lu 项", (unsigned long)selectedCount];
    return model;
}

/// 检查更新
- (NJSettingSkullViewModel *)checkUpdate {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_CHECK_UPDATE_BIZ_ID
                                                                             cellId:NJ_COMMON_CELL_ID
                                                                              title:@"检查更新"];
    model.subTitle = @"点击查询插件更新";
    model.subTitleColor = [UIColor nj_colorWithLight:[UIColor nj_colorWithHexString:@"#00A86B"]
                                                dark:[UIColor nj_colorWithHexString:@"#3DDC84"]];
    return model;
}

/// 大积分签到
- (NJSettingSkullViewModel *)bigPointSign {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_BIG_POINT_SIGN_BIZ_ID
                                                                             cellId:NJ_COMMON_CELL_ID
                                                                              title:@"大积分签到"];
    model.subTitle = @"点击领取今日大积分";
    return model;
}

/// 大积分中心
- (NJSettingSkullViewModel *)bigPointCenter {
    NJSettingSkullViewModel *model = [[NJSettingSkullViewModel alloc] initWithBizId:NJ_BIG_POINT_CENTER_BIZ_ID
                                                                             cellId:NJ_COMMON_CELL_ID
                                                                              title:@"大积分中心"];
    model.subTitle = @"打开网页";
    return model;
}



@end
