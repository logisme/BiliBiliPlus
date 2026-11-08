//
//  NJInlineSettingViewController.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/17.
//

#import "NJInlineSettingViewController.h"
#import "BBMFInlineSettingCell.h"
#import "NJInlineSettingModel.h"

static NSString * const kInlineSettingCellID = @"BBMFInlineSettingCell";

@interface NJInlineSettingViewController ()

- (BOOL)allModelsSelected;

@end

@implementation NJInlineSettingViewController

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
                        title:(NSString *)title
                   dataSource:(NSArray<NJInlineSettingModel *> *)dataSource {
    self = [super initWithStyle:style];
    if (self) {
        self.title = title;
        self.dataSource = dataSource;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTableView];
}

#pragma mark - Setup

- (void)setupTableView {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 42;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];

    [self.tableView registerClass:NSClassFromString(@"BBMFInlineSettingCell")
           forCellReuseIdentifier:kInlineSettingCellID];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count + (self.selectAllTitle.length > 0 ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    BBMFInlineSettingCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kInlineSettingCellID
                                        forIndexPath:indexPath];

    if (self.selectAllTitle.length > 0 && indexPath.row == 0) {
        [cell installWithTitle:self.selectAllTitle
                    isSelected:[self allModelsSelected]];
    } else {
        NSInteger modelIndex = indexPath.row - (self.selectAllTitle.length > 0 ? 1 : 0);
        NJInlineSettingModel *model = self.dataSource[modelIndex];
        [cell installWithTitle:model.title
                    isSelected:model.selected];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

/// 是否所有项都已选中
- (BOOL)allModelsSelected {
    if (self.dataSource.count == 0) {
        return NO;
    }
    for (NJInlineSettingModel *model in self.dataSource) {
        if (!model.selected) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // 置顶「显示全部」：全选 / 全不选
    if (self.selectAllTitle.length > 0 && indexPath.row == 0) {
        BOOL selectAll = ![self allModelsSelected];
        for (NJInlineSettingModel *model in self.dataSource) {
            model.selected = selectAll;
        }
        [tableView reloadData];
        [self notifyMultiSelection];
        return;
    }

    NSInteger modelIndex = indexPath.row - (self.selectAllTitle.length > 0 ? 1 : 0);
    NJInlineSettingModel *current = self.dataSource[modelIndex];

    if (self.allowsMultipleSelection) {
        // 多选：切换当前项
        current.selected = !current.selected;
        [tableView reloadData];
        [self notifyMultiSelection];
        return;
    }

    // 单选逻辑（InlineSetting 常见）
    for (NSInteger i = 0; i < self.dataSource.count; i++) {
        NJInlineSettingModel *model = self.dataSource[i];
        model.selected = (i == modelIndex);
    }

    [tableView reloadData];

    [self handleBizSelection:current];
}

/// 通知多选结果
- (void)notifyMultiSelection {
    if (!self.multiSelectedHandler) {
        return;
    }
    NSMutableArray<NJInlineSettingModel *> *selectedModels = [NSMutableArray array];
    for (NJInlineSettingModel *model in self.dataSource) {
        if (model.selected) {
            [selectedModels addObject:model];
        }
    }
    self.multiSelectedHandler([selectedModels copy]);
}

#pragma mark - Business

- (void)handleBizSelection:(NJInlineSettingModel *)model {
    if (self.selectedHandler) {
        self.selectedHandler(model);
    }
}

@end
