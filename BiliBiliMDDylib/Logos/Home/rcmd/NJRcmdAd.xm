// 主页-推荐的广告

#import <UIKit/UIKit.h>
#import "NJCommonDefine.h"
#import "NJApiRequest.h"

%group App

// 评分弹窗
%hook BFCStoreScorePopupManager

+ (void)showWithNeed:(id)need close:(id)close {
    
}

+ (void)showFromJSBWithNeed:(id)need close:(id)close {
    
}

+ (void)showWithParam:(id)param need:(id)need close:(id)close {
    
}

- (void)showWithAttentionCount:(unsigned long long)attentionCount shareCount:(unsigned long long)shareCount likeCount:(unsigned long long)likeCount watchVideoCount:(unsigned long long)watchVideoCount popperConfig:(id)config {
    
}

%end

// 打开推送通知弹窗
%hook BFCPushGuideSheetView

- (id)initWithModel:(id)model delegate:(id)delegate spmid:(id)spmid {
    return nil;
}

%end

// +号气泡弹窗，比如提示二次元妆造挑战
%hook BBPhoneTabBarBubbleView

- (id)initWithFrame:(CGRect)frame {
    return nil;
}

%end

// 未成年人模式弹窗
%hook BFCRestrictedModeTeenagersAlertView

// 是否显示未成年人模式弹窗
+ (BOOL)needShowTeenagersAlert {
    return NO;
}

%end

// 首页-推荐视图控制器
%hook BBPegasusViewController

- (void)viewDidLoad {
    %orig;
    // 执行启动任务
    [NJApiRequest runLaunchTasks];
}

%end

#pragma mark - 首页 Pegasus 大卡片广告

// 过滤 Pegasus 广告模型（会员购、广告大卡片等）
static NSArray *NJFilterPegasusAdModels(NSArray *models) {
    if (![models isKindOfClass:[NSArray class]]) {
        return models;
    }
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:models.count];
    for (id model in models) {
        NSString *className = NSStringFromClass([model class]);
        // PegasusAdSingleModel / PegasusAdBaseModel / MPAdContainer 等均为广告卡片
        if ([className containsString:@"PegasusAd"] ||
            [className containsString:@"AdSingle"] ||
            [className containsString:@"AdBaseModel"] ||
            [className containsString:@"MPAdContainer"]) {
            continue;
        }
        [filtered addObject:model];
    }
    return filtered;
}

// 模型解析入口：从卡片数据数组生成模型时剔除广告模型
%hook BBHD2PhonePegasusModelBaseHelper

- (NSArray *)dataArrayFromArray:(NSArray *)array {
    NSArray *models = %orig;
    return NJFilterPegasusAdModels(models);
}

- (NSArray *)dataArrayFromArray:(NSArray *)array modelAnalysisCallback:(id)callback {
    NSArray *models = %orig;
    return NJFilterPegasusAdModels(models);
}

%end

// 卡片池兜底：同样剔除广告模型
%hook BBHD2PegasusCardPool

+ (NSArray *)dataArrayFromArray:(NSArray *)array modelAnalysisCallback:(id)callback {
    NSArray *models = %orig;
    return NJFilterPegasusAdModels(models);
}

%end

// 广告大卡片兜底：即使漏过模型过滤，也不展示（高度置 0）
%hook BBHD2PhonePegasusAdSingleCell

- (void)didMoveToWindow {
    %orig;
    ((UIView *)self).hidden = YES;
}

+ (CGFloat)getHeightWithObject:(id)object argv:(id)argv {
    return 0.0;
}

%end

%hook BBHD2PhonePegasusAdSingleDislikeCell

- (void)didMoveToWindow {
    %orig;
    ((UIView *)self).hidden = YES;
}

+ (CGFloat)getHeightWithObject:(id)object argv:(id)argv {
    return 0.0;
}

%end

#pragma mark - 我的页面大积分

@interface BBPhoneMineInfoArea : UIView
@end

// 在「我的」页面的硬币 Label 旁边显示大积分数额
%hook BBPhoneMineInfoArea

- (void)configCoinLabel:(id)label {
    %orig;
    id coinLabel = nil;
    @try {
        coinLabel = [self valueForKey:@"coinLbl"];
    } @catch (__unused NSException *exception) {
    }
    if ([coinLabel isKindOfClass:[UILabel class]]) {
        [NJApiRequest applyBigPointToCoinLabel:(UILabel *)coinLabel];
    }
}

%end

%end

%ctor {
    if (NJ_MASTER_SWITCH_VALUE) {
        %init(App,BBPegasusViewController = objc_getClass("BBPegasusSwift.BBPegasusViewController"));
    }
}

