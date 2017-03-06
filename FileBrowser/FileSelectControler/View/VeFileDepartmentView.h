//
//  CJDepartmentView.h
//  Antenna
//
//  Created by HHLY on 16/6/15.
//  Copyright © 2016年 HHLY. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CJDepartmentViewDelegate <NSObject>

- (void)didScrollToIndex:(NSInteger)index withSelectMode:(NSInteger )selectMode;

@end


@interface VeFileDepartmentView : UIScrollView

@property (strong, nonatomic) NSArray *departmentArr;

@property (assign, nonatomic) id<CJDepartmentViewDelegate> cj_delegate;

@property (assign, nonatomic)NSInteger selectMode;

- (instancetype)initWithParts:(NSArray *)partArr;
- (instancetype)initWithParts:(NSArray *)partArr withFrame:(CGRect)frame;



- (void)replaceDeparmentTitleArrWithNewArr:(NSArray *)arr ;

- (void)setSelectedIndex:(NSInteger)selectedIndex;

- (void)reloadData;

@end
