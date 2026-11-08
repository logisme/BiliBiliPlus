//
//  NJMineDataHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/5.
//

#import "NJMineDataHandler.h"
#import "NJSettingCache.h"

/// 大积分签到入口 id（自定义，不与官方 id 冲突）
#define NJ_BIG_POINT_SIGN_ITEM_ID 9998
/// 大积分中心入口 id（自定义，不与官方 id 冲突）
#define NJ_BIG_POINT_CENTER_ITEM_ID 9999

@interface NJMineDataHandler ()

/// 业务id白名单（这些是核心服务，始终显示）
@property (nonatomic, strong) NSSet<NSNumber *> *bizIdWhiteList;


@end

@implementation NJMineDataHandler

#pragma mark - Life Cycle Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        [self doInit];
    }
    return self;
}



#pragma mark - Do Init

- (void)doInit {
    self.bizIdWhiteList = [[NSSet alloc] initWithObjects:@(396),     // 离线缓存
                                                         @(397),     // 历史记录
                                                         @(3072),    // 我的收藏
                                                         @(2830),    // 稍后再看
                                                         @(407),     // 联系客服
                                                         @(410),     // 设置
                                                         nil
    ];
}

#pragma mark - Override Methods

#pragma mark - Public Methods

/// 处理数据
/// - Parameter tabData: 要处理的数据
/// @return 处理后的数据
- (NSArray *)handleData:(NSArray *)mineData {
    // 收集接口返回的全部可配置服务，供设置页多选使用
    [self collectServicesFromData:mineData];

    NSSet<NSString *> *selectedIds = [[NJSettingCache sharedInstance] selectedMineServiceIds];
    NSMutableArray *newMineData = [NSMutableArray array];
    for (NSDictionary *bizData in mineData) {
        NSDictionary *dataHandled = [self handleSectionData:bizData selectedIds:selectedIds];
        if (dataHandled) {
            [newMineData addObject:dataHandled];
        }
    }

    // 大积分入口：合并进已有的「更多服务」分组，避免出现两个同名分组
    NSArray<NSDictionary *> *bigPointItems = [self selectedBigPointItems:selectedIds];
    if (bigPointItems.count > 0) {
        [self mergeBigPointItems:bigPointItems intoSections:newMineData];
    }
    return [newMineData copy];
}

#pragma mark - Private Methods

/// 收集接口中的服务项（id + title），持久化到设置缓存
- (void)collectServicesFromData:(NSArray *)mineData {
    NSMutableArray<NSDictionary *> *services = [NSMutableArray array];
    NSMutableSet<NSString *> *seenIds = [NSMutableSet set];
    for (NSDictionary *sectionData in mineData) {
        id items = sectionData[@"items"];
        if (![items isKindOfClass:[NSArray class]]) {
            continue;
        }
        for (NSDictionary *item in items) {
            id itemId = item[@"id"];
            NSString *title = item[@"title"];
            if (![itemId isKindOfClass:[NSNumber class]] || title.length == 0) {
                continue;
            }
            NSString *itemIdStr = [itemId stringValue];
            // 核心服务无需出现在选择列表里
            if ([self.bizIdWhiteList containsObject:itemId] ||
                [seenIds containsObject:itemIdStr]) {
                continue;
            }
            [seenIds addObject:itemIdStr];
            [services addObject:@{@"id": itemIdStr, @"title": title}];
        }
    }
    // 追加大积分入口
    [services addObject:@{@"id": [@(NJ_BIG_POINT_SIGN_ITEM_ID) stringValue],
                          @"title": @"大积分签到"}];
    [services addObject:@{@"id": [@(NJ_BIG_POINT_CENTER_ITEM_ID) stringValue],
                          @"title": @"大积分中心"}];
    [[NJSettingCache sharedInstance] saveMineServices:[services copy]];
}

/// 处理分组数据
/// @param sectionData 分组数据
/// @return 处理后的分组数据
- (NSDictionary *)handleSectionData:(NSDictionary *)sectionData selectedIds:(NSSet<NSString *> *)selectedIds {
    if (!sectionData[@"items"] ||
        ![sectionData[@"items"] isKindOfClass:[NSArray class]]) {
        return sectionData;
    }
    NSArray *items = sectionData[@"items"];
    NSMutableArray *newItems = [NSMutableArray array];
    for (NSDictionary *item in items) {
        NSDictionary *itemHandled = [self handleItemData:item selectedIds:selectedIds];
        if (itemHandled) {
            [newItems addObject:itemHandled];
        }
    }
    if (newItems.count == 0) {
        return nil;
    }
    NSMutableDictionary *newSectionData = [NSMutableDictionary dictionaryWithDictionary:sectionData];
    newSectionData[@"items"] = [newItems copy];
    return [newSectionData copy];
}


/// 处理项目数据
/// @param itemData 项目数据
/// @return 处理后的项目数据
- (NSDictionary *)handleItemData:(NSDictionary *)itemData selectedIds:(NSSet<NSString *> *)selectedIds {
    if (!itemData[@"id"] ||
        ![itemData[@"id"] isKindOfClass:[NSNumber class]]) {
        return itemData;
    }
    NSNumber *bizId = itemData[@"id"];
    // 核心服务始终显示
    if ([self.bizIdWhiteList containsObject:bizId]) {
        return itemData;
    }
    // 其余服务：默认全部隐藏，只有用户勾选后才显示
    if ([selectedIds containsObject:[bizId stringValue]]) {
        return itemData;
    }
    return nil;
}

/// 已勾选的大积分入口
- (NSArray<NSDictionary *> *)selectedBigPointItems:(NSSet<NSString *> *)selectedIds {
    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    if ([selectedIds containsObject:[@(NJ_BIG_POINT_SIGN_ITEM_ID) stringValue]]) {
        [items addObject:@{
            @"id": @(NJ_BIG_POINT_SIGN_ITEM_ID),
            @"title": @"大积分签到",
            @"uri": @"njbigpoint://sign",
            // 图标在 Cell 层替换为本地绘制的签到图标
            @"icon": @"",
            @"common_op_item": @{},
            @"corner_pixel": @(0),
            @"biz_type": @(0),
        }];
    }
    if ([selectedIds containsObject:[@(NJ_BIG_POINT_CENTER_ITEM_ID) stringValue]]) {
        [items addObject:@{
            @"id": @(NJ_BIG_POINT_CENTER_ITEM_ID),
            @"title": @"大积分中心",
            @"uri": @"https://big.bilibili.com/mobile/bigPoint?closable=1&msource=0",
            // 图标在 Cell 层替换为本地绘制的大积分图标
            @"icon": @"",
            @"common_op_item": @{},
            @"corner_pixel": @(0),
            @"biz_type": @(0),
        }];
    }
    return [items copy];
}

/// 把大积分入口固定合并进「我的服务」分组，不影响「更多服务」分组
- (void)mergeBigPointItems:(NSArray<NSDictionary *> *)items intoSections:(NSMutableArray *)sections {
    // 合并重复的同名分组（只合并同名分组，不跨分组合并）
    [self mergeDuplicateSectionsTitled:@"我的服务" inSections:sections];
    [self mergeDuplicateSectionsTitled:@"更多服务" inSections:sections];

    NSInteger targetIndex = NSNotFound;
    for (NSInteger i = 0; i < sections.count; i++) {
        NSString *sectionTitle = sections[i][@"title"];
        if ([sectionTitle isKindOfClass:[NSString class]] &&
            [sectionTitle isEqualToString:@"我的服务"]) {
            targetIndex = i;
            break;
        }
    }

    if (targetIndex == NSNotFound) {
        // 「我的服务」分组可能因为服务全部隐藏而被过滤掉，需要重新创建
        NSMutableDictionary *newSection = [@{
            @"title": @"我的服务",
            @"items": items,
            @"style": @(2),
            @"button": @{},
        } mutableCopy];
        // 保持在「更多服务」之前，符合「我的」页面的原有顺序
        NSInteger insertIndex = sections.count;
        for (NSInteger i = 0; i < sections.count; i++) {
            NSString *sectionTitle = sections[i][@"title"];
            if ([sectionTitle isKindOfClass:[NSString class]] &&
                [sectionTitle isEqualToString:@"更多服务"]) {
                insertIndex = i;
                break;
            }
        }
        [sections insertObject:newSection atIndex:insertIndex];
        return;
    }

    NSMutableArray *targetItems = [NSMutableArray array];
    NSArray *sectionItems = sections[targetIndex][@"items"];
    if ([sectionItems isKindOfClass:[NSArray class]]) {
        [targetItems addObjectsFromArray:sectionItems];
    }
    [targetItems addObjectsFromArray:items];

    // 按 id 去重，避免重复出现「设置」等条目
    NSMutableArray *uniqueItems = [NSMutableArray array];
    NSMutableSet *seenIds = [NSMutableSet set];
    for (NSDictionary *item in targetItems) {
        id itemId = item[@"id"];
        NSString *idKey = [itemId isKindOfClass:[NSNumber class]] ? [itemId stringValue] : nil;
        if (idKey.length > 0) {
            if ([seenIds containsObject:idKey]) {
                continue;
            }
            [seenIds addObject:idKey];
        }
        [uniqueItems addObject:item];
    }
    NSMutableDictionary *newSection = [sections[targetIndex] mutableCopy];
    newSection[@"items"] = [uniqueItems copy];
    sections[targetIndex] = newSection;
}

/// 合并同名分组（把后续同名分组的条目合并到第一个同名分组）
- (void)mergeDuplicateSectionsTitled:(NSString *)title inSections:(NSMutableArray *)sections {
    NSInteger targetIndex = NSNotFound;
    for (NSInteger i = 0; i < sections.count; i++) {
        NSString *sectionTitle = sections[i][@"title"];
        if ([sectionTitle isKindOfClass:[NSString class]] &&
            [sectionTitle isEqualToString:title]) {
            targetIndex = i;
            break;
        }
    }
    if (targetIndex == NSNotFound) {
        return;
    }
    NSMutableArray *targetItems = [NSMutableArray array];
    NSArray *sectionItems = sections[targetIndex][@"items"];
    if ([sectionItems isKindOfClass:[NSArray class]]) {
        [targetItems addObjectsFromArray:sectionItems];
    }

    NSMutableIndexSet *removeIndexes = [NSMutableIndexSet indexSet];
    for (NSInteger i = targetIndex + 1; i < sections.count; i++) {
        NSString *sectionTitle = sections[i][@"title"];
        if (![sectionTitle isKindOfClass:[NSString class]] ||
            ![sectionTitle isEqualToString:title]) {
            continue;
        }
        NSArray *duplicateItems = sections[i][@"items"];
        if ([duplicateItems isKindOfClass:[NSArray class]]) {
            [targetItems addObjectsFromArray:duplicateItems];
        }
        [removeIndexes addIndex:i];
    }
    if (removeIndexes.count == 0) {
        return;
    }
    NSMutableDictionary *newSection = [sections[targetIndex] mutableCopy];
    newSection[@"items"] = [targetItems copy];
    sections[targetIndex] = newSection;
    [sections removeObjectsAtIndexes:removeIndexes];
}

#pragma mark - Property Methods



@end
