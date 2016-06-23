//
//  ViewController.m
//  LGCitySorting
//
//  Created by 李堪阶 on 16/6/23.
//  Copyright © 2016年 DM. All rights reserved.
//

#import "ViewController.h"
#import "FMDB.h"
@interface ViewController ()
@property (nonatomic,strong)FMDatabaseQueue *dataBaseQ;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong ,nonatomic) NSMutableArray *cityArray;
@property (strong ,nonatomic) NSMutableArray *zmMutableArray;
@property (strong ,nonatomic) NSMutableArray *zuihoudecity;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //打开数据库
    NSString *path = [[NSBundle mainBundle]pathForResource:@"china_cities.db" ofType:nil];
    
    //创建数据库的队列
    FMDatabaseQueue *dataBaseQ = [FMDatabaseQueue databaseQueueWithPath:path];
    self.dataBaseQ = dataBaseQ;
    
    
    [dataBaseQ inDatabase:^(FMDatabase *db) {
        
        BOOL success = [db open];
        if (success) {
            NSLog(@"数据库创建成功!");
        }else{
            NSLog(@"数据库创建失败!");
        }
        
    }];
    
    [self selectData];
    
    //拿到所有拼音首字母
    NSMutableArray *pinyinPreS = [[NSMutableArray alloc]init];
    [self.cityArray enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyinPre = [dict[@"pinyin"] substringToIndex:1];
        [pinyinPreS addObject:pinyinPre];
    }];
    
    //过滤重复拼音
    NSSet *pinyinSet = [NSSet setWithArray:pinyinPreS];
    NSArray *filteredPinyinPres = [pinyinSet allObjects];
    
    //排序字母
    NSArray *zmArray = [filteredPinyinPres sortedArrayUsingSelector:@selector(compare:)];
    //小写转大写
    self.zmMutableArray = [NSMutableArray array];
    
    [zmArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *txt = [obj stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[obj uppercaseString]];
        
        [self.zmMutableArray addObject:txt];
    }];
    
    //循环
    NSMutableArray *cityFilteredDatas = [[NSMutableArray alloc]init];
    [zmArray enumerateObjectsUsingBlock:^(NSString *pinyinPre, NSUInteger idx, BOOL * _Nonnull stop) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"pinyin LIKE[cd] '%@*'",pinyinPre]];
        NSArray *citys = [self.cityArray filteredArrayUsingPredicate:predicate];
        [cityFilteredDatas addObject:citys];
    }];
    
    //排序
    self.zuihoudecity = [[NSMutableArray alloc]init];
    for (NSArray *citys in cityFilteredDatas) {
        [self.zuihoudecity addObject:[citys sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *city1, NSDictionary *city2) {
            NSString *city1Pinyin = city1[@"pinyin"];
            NSString *city2Pinyin = city2[@"pinyin"];
            if (city1Pinyin > city2Pinyin) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }]];
    }
    

}
- (void)selectData{
    
    __weak typeof(self)weakSelf = self;
    [self.dataBaseQ inDatabase:^(FMDatabase *db) {
        
        NSString *strSql =  @"SELECT * FROM city;";
        //查询语句  执行的方法
        FMResultSet *set =  [db executeQuery:strSql];
        
        while ([set next]) {
            
            NSString *name = [set stringForColumn:@"name"];
            
            NSString *pinyin = [set stringForColumn:@"pinyin"];
            
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
            [mutableDict setValue:name forKey:@"name"];
            [mutableDict setValue:pinyin forKey:@"pinyin"];
            
            [weakSelf.cityArray addObject:mutableDict];
        }
        
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return  self.zuihoudecity.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSArray *array = self.zuihoudecity[section];
    
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"SelectCityViewController";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSArray *array = self.zuihoudecity[indexPath.section];
    
    NSDictionary *dict = array[indexPath.row];
    
    cell.textLabel.text = dict[@"name"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 25;
}
/**
 *  返回分组索引数组
 */
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    
    return self.zmMutableArray;
}
/**
 *  返回第section组对应的头部标题
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return self.zmMutableArray[section];
}

#pragma mark - getter
- (NSMutableArray *)cityArray{
    
    if (_cityArray == nil) {
        
        _cityArray = [NSMutableArray array];
    }
    return _cityArray;
}


@end
