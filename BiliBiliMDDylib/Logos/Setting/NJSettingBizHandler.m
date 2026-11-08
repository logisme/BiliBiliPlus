//
//  NJSettingBizHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/12/28.
//

#import "NJSettingBizHandler.h"
#import "NJSettingDefine.h"
#import "NJSettingInjectDataProvider.h"
#import "NJCommonDefine.h"
#import "UIApplication+NJCategory.h"
#import "NJInlineSettingViewController.h"
#import "NJChangePlaybackRateTool.h"
#import "NJSettingCache.h"
#import "NJPluginInfo.h"
#import "NJApiRequest.h"

// 本项目地址
#define NJ_OFFICIAL_WEBSITE_URL_STR @"https://github.com/logisme/BiliBiliPlus"
// 项目地址（原开源项目入口）
#define NJ_UPSTREAM_WEBSITE_URL_STR @"https://github.com/logisme/BiliBiliPlus"
/// 大积分中心
#define NJ_BIG_POINT_CENTER_URL_STR @"https://big.bilibili.com/mobile/bigPoint?closable=1&msource=0"
/// GitHub Releases API
#define NJ_RELEASES_LATEST_URL_STR @"https://api.github.com/repos/logisme/BiliBiliPlus/releases/latest"

@interface NJSettingBizHandler ()

/// 数据提供者
@property (nonatomic, strong) NJSettingInjectDataProvider *dataProvider;
/// 是否提示过重启
@property (nonatomic, assign) BOOL isRebootTip;


@end

@implementation NJSettingBizHandler

#pragma mark - Life Cycle Methods

- (instancetype)initWithSettingViewController:(UIViewController *)settingViewController tableView:(UITableView *)tableView {
    self = [super init];
    if (self) {
        self.settingViewController = settingViewController;
        self.tableView = tableView;
        [self doInit];
    }
    return self;
}

#pragma mark - Do Init

- (void)doInit {
    self.shareManager = [[NJShareManager alloc] init];
    [self initEventManager];
    self.dataProvider = [[NJSettingInjectDataProvider alloc] init];
    self.injectDatas = self.dataProvider.injectDatas;
    self.isRebootTip = NO;
}

- (void)initEventManager {
    self.eventManager = [[NJSettingEventManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.eventManager.aSwitchChange = ^(UISwitch * _Nonnull aSwitch, NJSettingSwitchViewModel * _Nonnull viewModel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf aSwitchChange:aSwitch
                        viewModel:viewModel];
    };
}

#pragma mark - Override Methods

#pragma mark - Public Methods

- (void)handleBizWithViewModel:(NJSettingSkullViewModel *)viewModel {
    NSString *bizId = viewModel.bizId;
    // 分享数据
    if ([bizId isEqualToString:NJ_SHARE_DATA_BIZ_ID]) {
        [self.shareManager shareCacheFolder];
        return;
    }
    // 官网 / 原开源项目
    if ([bizId isEqualToString:NJ_OFFICIAL_WEBSITE_BIZ_ID] ||
        [bizId isEqualToString:NJ_UPSTREAM_WEBSITE_BIZ_ID]) {
        NSString *urlString = [bizId isEqualToString:NJ_OFFICIAL_WEBSITE_BIZ_ID]
            ? NJ_OFFICIAL_WEBSITE_URL_STR
            : NJ_UPSTREAM_WEBSITE_URL_STR;
        NSURL *url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:nil];
        return;
    }
    // 默认播放速度
    if ([bizId isEqualToString:NJ_DEFAULT_PLAYBACK_RATE]) {
        [self handleDefaultPlaybackRateWithViewModel:viewModel];
        return;
    }
    // 关注的默认版块
    if ([bizId isEqualToString:NJ_FOLLOW_DEFAULT_TAB]) {
        [self handleFollowDefaultTabWithViewModel:viewModel];
        return;
    }
    // 大会员福利领取类型
    if ([bizId isEqualToString:NJ_COUPON_TYPE_BIZ_ID]) {
        [self handleCouponTypeWithViewModel:viewModel];
        return;
    }
    // 「我的」页面显示的服务
    if ([bizId isEqualToString:NJ_MINE_SERVICES_BIZ_ID]) {
        [self handleMineServicesWithViewModel:viewModel];
        return;
    }
    // 检查更新
    if ([bizId isEqualToString:NJ_CHECK_UPDATE_BIZ_ID]) {
        [self handleCheckUpdate];
        return;
    }
    // 大积分签到
    if ([bizId isEqualToString:NJ_BIG_POINT_SIGN_BIZ_ID]) {
        [self handleBigPointSignWithViewModel:viewModel];
        return;
    }
    // 大积分中心
    if ([bizId isEqualToString:NJ_BIG_POINT_CENTER_BIZ_ID]) {
        NSURL *url = [NSURL URLWithString:NJ_BIG_POINT_CENTER_URL_STR];
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:nil];
        return;
    }
}

#pragma mark - Private Methods

/// 点击默认播放速度
/// - Parameter viewModel: 数据
- (void)handleDefaultPlaybackRateWithViewModel:(NJSettingSkullViewModel *)viewModel {
    NSString *selectedValue = viewModel.subTitle;
    NSMutableArray<NJInlineSettingModel *> *dataSource = [NSMutableArray array];
    NSArray<NSString *> *oldPlaybackRates = [NJChangePlaybackRateTool currentPlaybackRates];
    for (NSString *rate in oldPlaybackRates) {
        BOOL selected = rate.doubleValue == selectedValue.doubleValue;
        NJInlineSettingModel *model = [[NJInlineSettingModel alloc] initWithTitle:rate bizId:rate selected:selected];
        [dataSource addObject:model];
    }
    
    NJInlineSettingViewController *inlineVC = [[NJInlineSettingViewController alloc] initWithStyle:UITableViewStylePlain title:@"默认播放速度" dataSource:[dataSource copy]];
    __weak typeof(self) weakSelf = self;
    inlineVC.selectedHandler = ^(NJInlineSettingModel * _Nonnull model) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf handleChangeDefaultPlaybackRate:model viewModel:viewModel];
    };
    [self.settingViewController.navigationController pushViewController:inlineVC animated:YES];
}

- (void)handleChangeDefaultPlaybackRate:(NJInlineSettingModel *)model viewModel:(NJSettingSkullViewModel *)viewModel {
    NSString *rate = model.title;
    viewModel.subTitle = rate;
    // 保存
    [[NJSettingCache sharedInstance] saveDefaultPlaybackRate:rate];
    [self.tableView reloadData];
}

/// 点击关注的默认版块
/// - Parameter viewModel: 数据
- (void)handleFollowDefaultTabWithViewModel:(NJSettingSkullViewModel *)viewModel {
    NSString *subTitle = viewModel.subTitle;
    NSArray<NJInlineSettingModel *> *followTabs = [self.dataProvider followTabs];
    for (NJInlineSettingModel *model in followTabs) {
        model.selected = [model.title isEqualToString:subTitle];
    }
    
    NJInlineSettingViewController *inlineVC = [[NJInlineSettingViewController alloc] initWithStyle:UITableViewStylePlain title:@"关注页的默认版块" dataSource:followTabs];
    __weak typeof(self) weakSelf = self;
    inlineVC.selectedHandler = ^(NJInlineSettingModel * _Nonnull model) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf handleChangeFollowDefaultTab:model viewModel:viewModel];
    };
    [self.settingViewController.navigationController pushViewController:inlineVC animated:YES];
}

- (void)handleChangeFollowDefaultTab:(NJInlineSettingModel *)model viewModel:(NJSettingSkullViewModel *)viewModel {
    [self rebootTip];
    viewModel.subTitle = model.title;
    // 保存
    [[NJSettingCache sharedInstance] saveFollowDefaultTab:model.bizId];
    [self.tableView reloadData];
}

- (void)aSwitchChange:(UISwitch *)aSwitch
            viewModel:(NJSettingSwitchViewModel *)viewModel {
    NSString *saveKey = viewModel.saveKey;
    [[NJSettingCache sharedInstance] saveBool:viewModel.on forKey:saveKey];
    [self rebootTip];
}

/// 点击大会员福利领取类型
/// - Parameter viewModel: 数据
- (void)handleCouponTypeWithViewModel:(NJSettingSkullViewModel *)viewModel {
    NSArray<NJInlineSettingModel *> *couponTypes = [self.dataProvider couponTypes];
    NJInlineSettingViewController *inlineVC = [[NJInlineSettingViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                              title:@"大会员福利"
                                                                                         dataSource:couponTypes];
    __weak typeof(self) weakSelf = self;
    inlineVC.selectedHandler = ^(NJInlineSettingModel * _Nonnull model) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf handleChangeCouponType:model viewModel:viewModel];
    };
    [self.settingViewController.navigationController pushViewController:inlineVC animated:YES];
}

- (void)handleChangeCouponType:(NJInlineSettingModel *)model viewModel:(NJSettingSkullViewModel *)viewModel {
    NSInteger couponType = model.bizId.integerValue;
    [[NJSettingCache sharedInstance] saveCouponType:couponType];
    viewModel.subTitle = model.title;
    [self rebootTip];
    [self.tableView reloadData];
}

#pragma mark 「我的」页面显示的服务

- (void)handleMineServicesWithViewModel:(NJSettingSkullViewModel *)viewModel {
    NSArray<NSDictionary *> *services = [[NJSettingCache sharedInstance] mineServices];
    if (services.count == 0) {
        [self showAlertWithTitle:@"暂无可选服务"
                         message:@"请先进入「我的」页面刷新一次数据后再试"];
        return;
    }
    NSSet<NSString *> *selectedIds = [[NJSettingCache sharedInstance] selectedMineServiceIds];
    NSMutableArray<NJInlineSettingModel *> *models = [NSMutableArray array];
    for (NSDictionary *service in services) {
        NSString *serviceId = [service[@"id"] isKindOfClass:[NSString class]] ? service[@"id"] : nil;
        NSString *title = [service[@"title"] isKindOfClass:[NSString class]] ? service[@"title"] : nil;
        if (serviceId.length == 0 || title.length == 0) {
            continue;
        }
        BOOL selected = [selectedIds containsObject:serviceId];
        [models addObject:[[NJInlineSettingModel alloc] initWithTitle:title
                                                               bizId:serviceId
                                                            selected:selected]];
    }
    NJInlineSettingViewController *inlineVC = [[NJInlineSettingViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                             title:@"我的-显示的服务"
                                                                                        dataSource:[models copy]];
    inlineVC.allowsMultipleSelection = YES;
    inlineVC.selectAllTitle = @"显示全部";
    __weak typeof(self) weakSelf = self;
    inlineVC.multiSelectedHandler = ^(NSArray<NJInlineSettingModel *> * _Nonnull selectedModels) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableSet<NSString *> *ids = [NSMutableSet set];
        for (NJInlineSettingModel *model in selectedModels) {
            [ids addObject:model.bizId];
        }
        [[NJSettingCache sharedInstance] saveSelectedMineServiceIds:ids];
        NSUInteger count = ids.count;
        viewModel.subTitle = count == 0 ? @"全部隐藏" : [NSString stringWithFormat:@"已选 %lu 项", (unsigned long)count];
        [strongSelf.tableView reloadData];
    };
    [self.settingViewController.navigationController pushViewController:inlineVC animated:YES];
}

#pragma mark 检查更新

- (void)handleCheckUpdate {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:NJ_RELEASES_LATEST_URL_STR]];
    request.timeoutInterval = 15.0;
    [request setValue:@"application/vnd.github+json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"BiliBiliPlus" forHTTPHeaderField:@"User-Agent"];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (error || ![data isKindOfClass:[NSData class]]) {
                [strongSelf showAlertWithTitle:@"检查更新失败"
                                       message:@"网络请求失败，请稍后重试"];
                return;
            }
            NSError *jsonError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (![json isKindOfClass:[NSDictionary class]]) {
                [strongSelf showAlertWithTitle:@"检查更新失败"
                                       message:@"返回数据解析失败"];
                return;
            }
            NSString *tagName = json[@"tag_name"];
            NSString *htmlUrl = json[@"html_url"];
            NSString *latestVersion = [tagName stringByReplacingOccurrencesOfString:@"v" withString:@""];
            NSString *currentVersion = [NJPluginInfo pluginVersion];
            if ([latestVersion isEqualToString:currentVersion]) {
                [strongSelf showAlertWithTitle:@"已是最新版本"
                                       message:[NSString stringWithFormat:@"当前版本 v%@", currentVersion]];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发现新版本"
                                                                               message:[NSString stringWithFormat:@"最新版本 v%@，当前版本 v%@", latestVersion, currentVersion]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"前往下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSURL *url = [NSURL URLWithString:htmlUrl];
                    if (url) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    }
                }]];
                [strongSelf.settingViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
    [task resume];
}

#pragma mark 大积分

- (void)handleBigPointSignWithViewModel:(NJSettingSkullViewModel *)viewModel {
    viewModel.subTitle = @"签到中...";
    [self.tableView reloadData];
    __weak typeof(self) weakSelf = self;
    [NJApiRequest signBigPointWithCompletionHandler:^(BOOL success, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            viewModel.subTitle = success ? @"今日已签到" : @"点击领取今日大积分";
            [strongSelf.tableView reloadData];
            [strongSelf showAlertWithTitle:success ? @"大积分签到成功" : @"大积分签到失败"
                                   message:message];
        });
    }];
}

#pragma mark 提示

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self.settingViewController presentViewController:alert animated:YES completion:nil];
}

// 重启提示
- (void)rebootTip {
    if (self.isRebootTip) {
        return;
    }
    self.isRebootTip = YES;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重启应用生效"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self.settingViewController presentViewController:alert animated:YES completion:^{
        // 当弹窗展示完成后，延迟2秒再自动关闭
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - Property Methods


@end
