//
//  ViewController.m
//  fileManage
//
//  Created by Vieene on 2016/10/13.
//  Copyright © 2016年 Vieene. All rights reserved.
//
#import <Photos/Photos.h>

static NSInteger MAXSelect = 5;
static NSInteger MAXFILESIZE = 5000000;

//文件默认存储的路径
#define HomeFilePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"CJFileCache1"]

///屏幕高度/宽度
#define CJScreenWidth        [UIScreen mainScreen].bounds.size.width
#define CJScreenHeight       [UIScreen mainScreen].bounds.size.height
#import "CJFileManagerVC.h"
#import "CJFileObjModel.h"
#import "VeFileViewCell.h"
#import "VeFileManagerToolBar.h"
#import "VeFileDepartmentView.h"
#import "CJFlieLookUpVC.h"
#import "UIView+CJToast.h"
#import "UIColor+CJColorCategory.h"
#import "CJFileObjModel.h"
#import <MJExtension.h>
#import <AssetsLibrary/AssetsLibrary.h>

CGFloat departmentH = 48;
CGFloat toolBarHeight = 49;

@interface CJFileManagerVC ()<UITableViewDelegate,UITableViewDataSource,TYHInternalAssetGridToolBarDelegate,CJDepartmentViewDelegate>


@property (strong, nonatomic) VeFileDepartmentView *departmentView;//文件的类目视图
@property (strong, nonatomic) VeFileManagerToolBar *assetGridToolBar;//底部发送的工具条
@property (strong, nonatomic) NSMutableArray *selectedItems;//记录选中的cell的模型
@property (nonatomic,strong) UITableView *tabvlew;
@property (nonatomic,strong) NSMutableArray *dataSource;
@property (nonatomic,strong) NSMutableArray *originFileArray;
@property (nonatomic,strong) UIDocumentInteractionController *documentInteraction;
@property (nonatomic,strong) NSArray *depatmentArray;//文件分类数组
@property (nonatomic,strong) NSArray *depatmentArraytwo;
@property (nonatomic,strong) UISegmentedControl *segmentControl;

@property (nonatomic,assign) SelectFileMode mode;

@property (nonatomic,strong) NSMutableArray *recentTimeSource;

@property (nonatomic,strong) NSMutableArray *videoArray;

@end

@implementation CJFileManagerVC

- (NSMutableArray *)recentTimeSource {
    if (!_recentTimeSource ) {
        _recentTimeSource = [NSMutableArray array];
    }return _recentTimeSource;
}

- (NSMutableArray *)videoArray {
    if (!_videoArray) {
        _videoArray = [NSMutableArray array];
    }return _videoArray;
}

+ (void)initialize
{
    [self getHomeFilePath];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"文件默认存储的路径---%@",HomeFilePath);
    self.title = (@"我的文件");
    self.view.backgroundColor = [UIColor whiteColor];
    //关闭系统自动偏移64点
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self initNAV];
    
    [self loadData];
    [self loadVideo];
    [self setClickPartmentView];
    [self setupToolbar];
}

- (void)loadVideo {
    
    PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
    if (author == PHAuthorizationStatusRestricted || author ==PHAuthorizationStatusDenied) {
        //无权限
        
    }
    else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //这里用PHAsset来获取视频数据 ALAsset显得很无力了。。。
            PHFetchResult *voideResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
            PHImageManager *manager = [PHImageManager defaultManager];
            // 视频请求对象
            PHVideoRequestOptions *options = [PHVideoRequestOptions new];
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            [voideResult enumerateObjectsUsingBlock:^(PHAsset *obj, NSUInteger idx, BOOL *stop) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"YY-MM-dd HH:mm:ss"];
                CJFileObjModel *model = [CJFileObjModel new];
                model.creatTime = [dateFormatter stringFromDate:obj.creationDate];
                
                [manager requestImageForAsset:obj targetSize:CGSizeMake(80, 80) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    model.image = result;
                }];
                [manager requestAVAssetForVideo:obj options:options resultHandler:^(AVAsset * asset, AVAudioMix * audioMix, NSDictionary * info) {
                    
                    NSArray *tracks = asset.tracks;
//                    float estimatedSize = 0.0 ;
                    for (AVAssetTrack * track in tracks) {
                        float rate = ([track estimatedDataRate] / 8); // convert bits per second to bytes per second
                        float seconds = CMTimeGetSeconds([track timeRange].duration);
                        model.fileSizefloat += seconds * rate;
                    }
                    
                    model.fileSize = [NSString stringWithFormat:@"%.2lfM",model.fileSizefloat / 1000 / 1000];
                    
                    model.name = [asset mj_keyValues][@"propertyListForProxy"][@"name"];
                    //                model.fileSize = [[asset mj_keyValues][@"propertyListForProxy"][@"moop"] length];
                    model.fileData = [asset mj_keyValues][@"propertyListForProxy"][@"moop"];
                    [self.videoArray addObject:model];
                }];
                
                
                
            }];
            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                NSArray *results =[self.videoArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
//                    CJFileObjModel *model1 = obj1;
//                    CJFileObjModel *model2 = obj2;
//                    NSComparisonResult result = [model1.creatTime compare:model2.creatTime];
//                    return result == NSOrderedAscending;
//                }];
//                [self.videoArray removeAllObjects];
//                [self.videoArray addObjectsFromArray:results];
//            });
            
        });
    }
    
   

}

- (void)clearDataSource {
    [self.tabvlew removeFromSuperview];
    self.tabvlew = nil;

    [self.dataSource removeAllObjects];
}
- (void)loadDataWithRecentTimeSendFileMode {
    [self clearDataSource];
    [self.departmentView replaceDeparmentTitleArrWithNewArr:self.depatmentArray];
//    [self loadData];
    self.dataSource = self.originFileArray.mutableCopy;
    [self tabvlew];
}

- (void)loadDataWithLocalFileMode {
    [self clearDataSource];
    [self.departmentView replaceDeparmentTitleArrWithNewArr:self.depatmentArraytwo];
    
}

- (void)setMode:(SelectFileMode)mode {
    _mode = mode;
    _departmentView.selectMode = mode;
    if (_mode == RecentTimeSendFileMode) {
        [self loadDataWithRecentTimeSendFileMode];
    }else if (_mode == LocalFileMode) {
        [self loadDataWithLocalFileMode];
    }
}

- (UISegmentedControl *)segmentControl {
    
    if (!_segmentControl) {
        _segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"最近文件",@"本地文件"]];
        [_segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithHexString:@"22aeff"]} forState:UIControlStateSelected];
        _segmentControl.selectedSegmentIndex = 0;
        self.mode = RecentTimeSendFileMode;
        [_segmentControl addTarget:self action:@selector(segmentValueChange:) forControlEvents:UIControlEventValueChanged];
        _segmentControl.tintColor = [UIColor whiteColor];
    }
    return _segmentControl;
}

- (NSArray *)depatmentArraytwo {
    if (!_depatmentArraytwo) {
        _depatmentArraytwo = @[@"文档",@"视频",@"相册",@"音乐",@"其他"];
    }
    return _depatmentArraytwo;
}

- (NSArray *)depatmentArray
{
    if (_depatmentArray == nil) {
        _depatmentArray = @[@"全部",@"音乐",@"文档",@"应用",@"其他"];
    }
     return  _depatmentArray;
}
- (UITableView *)tabvlew
{
    if (_tabvlew == nil) {
        CGRect frame = CGRectMake(0, departmentH + 10 + 64, CJScreenWidth, CJScreenHeight  - toolBarHeight - departmentH - 10 - 64);
        _tabvlew = [[UITableView alloc]   initWithFrame:frame style:UITableViewStylePlain];
        _tabvlew.tableFooterView = [[UIView alloc] init];
        _tabvlew.delegate = self;
        _tabvlew.dataSource = self;
        _tabvlew.bounces = NO;
        [self.view addSubview:self.tabvlew];

    }
    return _tabvlew;
}
- (void)setupToolbar
{
    VeFileManagerToolBar *toolbar = [[VeFileManagerToolBar alloc] initWithFrame:CGRectMake(0, CJScreenHeight - toolBarHeight, CJScreenWidth, toolBarHeight)];
    toolbar.delegate = self;
    _assetGridToolBar = toolbar;
    _assetGridToolBar.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_assetGridToolBar];
}
- (void)setClickPartmentView
{
    [self departmentView];
}
- (NSMutableArray *)selectedItems
{
    if (!_selectedItems) {
        _selectedItems = @[].mutableCopy;
    }
    return _selectedItems;
}

- (VeFileDepartmentView *)departmentView
{
    if (_departmentView == nil) {
        CGRect frame = CGRectMake(0, 64, CJScreenWidth, departmentH);
        _departmentView = [[VeFileDepartmentView alloc] initWithParts:self.depatmentArray withFrame:frame];
        _departmentView.cj_delegate = self;
        [self.view addSubview:_departmentView];
    }
    return _departmentView;
}
- (void)initNAV {
    
    self.navigationItem.titleView = self.segmentControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction)];
}

#pragma mark - loadData
- (void)loadData{
    [_dataSource removeAllObjects];
    self.originFileArray = @[].mutableCopy;
    self.view.backgroundColor = [UIColor whiteColor];
    //默认加入几个文件
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"宋冬野 - 董小姐" ofType:@"mp3"];
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"IMG_4143" ofType:@"PNG"];
    NSString *path3 = [[NSBundle mainBundle] pathForResource:@"angle" ofType:@"jpg"];
    NSString *path4 = [[NSBundle mainBundle] pathForResource:@"he is a pirate" ofType:@"mp3"];

    CJFileObjModel *mode1 = [[CJFileObjModel alloc] initWithFilePath:path1];
    CJFileObjModel *mode2 = [[CJFileObjModel alloc] initWithFilePath:path2];
    CJFileObjModel *mode3 = [[CJFileObjModel alloc] initWithFilePath:path3];
    CJFileObjModel *mode4 = [[CJFileObjModel alloc] initWithFilePath:path4];

    [self.originFileArray addObjectsFromArray:@[mode1,mode2,mode3,mode4]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //遍历HomeFilePath文件夹下的子文件
    NSArray<NSString *> *subPathsArray = [fileManager contentsOfDirectoryAtPath:HomeFilePath error: NULL];
    
    for(NSString *str in subPathsArray){
        CJFileObjModel *object = [[CJFileObjModel alloc] initWithFilePath: [NSString stringWithFormat:@"%@/%@",HomeFilePath, str]];
        [self.originFileArray addObject: object];
    }
//    self.recentTimeSource = self.originFileArray.mutableCopy;
//    self.dataSource = self.recentTimeSource;
    self.dataSource = self.originFileArray.mutableCopy;
    [self.tabvlew reloadData];
}
#pragma mark - Action
- (void)segmentValueChange:(UISegmentedControl *)seg{
    self.mode = seg.selectedSegmentIndex;
}

- (void)cancelAction {

}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VeFileViewCell *cell = (VeFileViewCell *)[tableView dequeueReusableCellWithIdentifier:@"fileCell"];
    if (cell == nil) {
         cell = [[VeFileViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"];
    }
    CJFileObjModel *actualFile = [_dataSource objectAtIndex:indexPath.row];
    cell.model = actualFile;
    __weak typeof(self) weakSelf = self;
    /*
     cell☑️回调
     */
    
    cell.Clickblock = ^(CJFileObjModel *model,UIButton *btn){
        if (weakSelf.selectedItems.count>= MAXSelect && btn.selected) {
            btn.selected =  NO;
            model.select = btn.selected;
            [weakSelf.view makeToast:@"最多支持5个文件选择" duration:0.5 position:CSToastPositionCenter];
            return ;
        }
        if ([weakSelf checkFileSize:model]) {
            if (btn.isSelected) {
                [weakSelf.selectedItems addObject:model];
                weakSelf.assetGridToolBar.selectedItems = weakSelf.selectedItems;
            }else{
                [weakSelf.selectedItems removeObject:model];
                weakSelf.assetGridToolBar.selectedItems = weakSelf.selectedItems;
            }
        }else{
            [weakSelf.view makeToast:@"暂时不支持超过5MB的文件" duration:0.5 position:CSToastPositionCenter];
            btn.selected =  NO;
            model.select = btn.selected;
        }
    };
    return cell;
}

#pragma mark -UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CJFileObjModel *actualFile = [_dataSource objectAtIndex:indexPath.row];
    NSString *cachePath =actualFile.filePath;
    NSLog(@"调用文件查看控制器%@---type %zd, %@",actualFile.name,actualFile.fileType,cachePath);
    CJFlieLookUpVC *vc = [[CJFlieLookUpVC alloc] initWithFileModel:actualFile];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark -  SEARCH -> Action
//获得其他文件
- (void)searchUnkownFileForPath{
    [self.dataSource removeAllObjects];
    for (CJFileObjModel * model in self.originFileArray) {
        if (model.fileType == MKFileTypeUnknown) {
            [self.dataSource addObject:model];
        }
    }
    [self.tabvlew reloadData];
}

//获得应用
- (void)searchAPPForPath {
    [self.dataSource removeAllObjects];
    for (CJFileObjModel * model in self.originFileArray) {
        if (model.fileType == MKFileTypeApplication) {
            [self.dataSource addObject:model];
        }
    }
    [self.tabvlew reloadData];
}

//获得MP3
- (void)searchMP3ForPath {
    [self.dataSource removeAllObjects];
    for (CJFileObjModel * model in self.originFileArray) {
        if (model.fileType == MKFileTypeAudioVidio) {
            [self.dataSource addObject:model];
        }
    }
    [self.tabvlew reloadData];
}

//获得文档
- (void)searchDocumentsForPath {
    [self.dataSource removeAllObjects];
    for (CJFileObjModel * model in self.originFileArray) {
        if (model.fileType == MKFileTypeTxt) {
            [self.dataSource addObject:model];
        }
    }
    [self.tabvlew reloadData];
}

//获取视频
- (void)searchVideoForPhoto {
    [self.dataSource removeAllObjects];
    
    NSArray *results =[self.videoArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CJFileObjModel *model1 = obj1;
        CJFileObjModel *model2 = obj2;
        NSComparisonResult result = [model1.creatTime compare:model2.creatTime];
        return result == NSOrderedAscending;
    }];
    [self.videoArray removeAllObjects];
    [self.videoArray addObjectsFromArray:results];
    
    [self.dataSource addObjectsFromArray:self.videoArray];
    [self.tabvlew reloadData];
}

//获取图片
- (void)searchPictureForPhoto {
    
}


#pragma mark --CJDepartmentViewDelegate
//根据点击进行数据过滤
- (void)didScrollToIndex:(NSInteger)index withSelectMode:(NSInteger)selectMode{
    [self setOrigArray];
        switch (index) {
            case 0:
            {
                if (selectMode == RecentTimeSendFileMode) {
                    NSLog(@"btn.tag%zd",index);
                    self.dataSource = self.originFileArray.mutableCopy;
                    [self.dataSource enumerateObjectsUsingBlock:^(CJFileObjModel * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSLog(@"obj----%zd",self.dataSource);
                    }];
                    [self.tabvlew reloadData];
                }else {
                    [self searchDocumentsForPath];
                }
            }
                break;
            case 1:
            {
                if (selectMode == RecentTimeSendFileMode) {
                    NSLog(@"btn.tag%zd",index);
                    [self searchMP3ForPath];
                    
                }else {
                    //获取视频
                    [self searchVideoForPhoto];
                }
                
            }
                break;
            case 2:
            {
                if (selectMode == RecentTimeSendFileMode) {
                    NSLog(@"btn.tag%zd",index);
                    [self searchDocumentsForPath];
                }else {
                    [self searchPictureForPhoto];
                }
            }
                break;
            case 3:
            {
                if (selectMode == RecentTimeSendFileMode) {
                    NSLog(@"btn.tag%zd",index);
                    [self searchAPPForPath];
                }else {
                    [self searchMP3ForPath];
                }
            }
                break;
            case 4:
            {
                if (selectMode == RecentTimeSendFileMode) {
                    NSLog(@"btn.tag%zd",index);
                    [self searchUnkownFileForPath];
                }else {
                    [self searchUnkownFileForPath];
                }
            }
                break;
            default:
                NSLog(@"btn.tag%zd",index);
                break;
        }
}



//将已经记录选中的文件，保存
- (void)setOrigArray{
    for (CJFileObjModel *model  in self.selectedItems) {
        [self.originFileArray enumerateObjectsUsingBlock:^(CJFileObjModel *origModel, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([origModel.filePath isEqualToString:model.filePath]) {
                origModel.select = model.select;
                NSLog(@"被选中的item 是：%@",origModel.filePath);
            }
        }];
    }
}
#pragma mark --TYHInternalAssetGridToolBarDelegate

- (void)didClickSenderButtonInAssetGridToolBar:(VeFileManagerToolBar *)internalAssetGridToolBar
{
    
    NSLog(@"SenderButtonInAsset----%@",self.selectedItems);
    [self dismissViewControllerAnimated:YES completion:nil];

    if ([self.fileSelectVcDelegate respondsToSelector:@selector(fileViewControlerSelected:)]) {
        [self.fileSelectVcDelegate fileViewControlerSelected:self.selectedItems];
    }
}

+ (void)getHomeFilePath
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:HomeFilePath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:HomeFilePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
}
- (BOOL )checkFileSize:(CJFileObjModel *)model
{
    if (model.fileSizefloat >= MAXFILESIZE) {
        return NO;
    }
    return YES;
}
@end
