//
//  ViewController.m
//  GoogleMapsDemo
//
//  Created by Karl on 16/5/13.
//  Copyright © 2016年 Karl. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import <GoogleMaps/GoogleMaps.h>
#define GoogleMapKey @"AIzaSyC6UdZfvOoEvOL9fFHQPfRawNix38ToRgM"
@interface ViewController ()<GMSAutocompleteFetcherDelegate,GMSMapViewDelegate,CLLocationManagerDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>{
    
    GMSMapView *_googleMapView;
    CLLocationManager *_loacationManager;
    UITextField *_addressTextField;//地址搜索框
    GMSAutocompleteFetcher *_autoCompleteFetcher;
    UITableView *_mainTableView;//用以展示自动补全结果的表格式图
    NSMutableArray *_dataArray;
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createMapView];
    [self createCenterViw];
    [self createTextField];
    _autoCompleteFetcher = [[GMSAutocompleteFetcher alloc] init];
    _autoCompleteFetcher.delegate = self;
    _dataArray = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldSelectAll) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChanged) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)createTextField{
    _addressTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 40, self.view.bounds.size.width-40, 40)];
    _addressTextField.delegate = self;
    _addressTextField.backgroundColor = [UIColor whiteColor];
    _addressTextField.textColor = [UIColor blackColor];
    _addressTextField.returnKeyType = UIReturnKeySearch;
    _addressTextField.textAlignment = NSTextAlignmentCenter;
    _addressTextField.placeholder = @"查找地址";
    _addressTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_addressTextField];
    
    _mainTableView = [[UITableView alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width-40, 200) style:UITableViewStyleGrouped];
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    [self.view addSubview:_mainTableView];
    _mainTableView.hidden = YES;
}

- (void)createMapView{
    /*
     地图初始化
     **/
    _googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _googleMapView.delegate = self;
    _googleMapView.indoorEnabled = NO;
    _googleMapView.settings.rotateGestures = NO;
    _googleMapView.settings.tiltGestures = NO;
    _googleMapView.settings.myLocationButton = YES;
    _googleMapView.myLocationEnabled = YES;
    _loacationManager = [[CLLocationManager alloc] init];
    _loacationManager.delegate  = self;
    [_loacationManager requestWhenInUseAuthorization];
    [self.view addSubview:_googleMapView];
    
}

- (void)createCenterViw{
    /**
     中间定位图标
     */
    UIImageView *centerImageView=[[UIImageView alloc]initWithFrame:CGRectMake((_googleMapView.bounds.size.width)/2-7, (_googleMapView.bounds.size.height)/2-40, 15, 40)];
    centerImageView.image=[UIImage imageNamed:@"btn_home_Business2"];
    [self.view addSubview:centerImageView];
    
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    /**
     *    拿到授权发起定位请求
     
     */
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [_loacationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    /**
     * 位置更新时调用
     */
    CLLocation *currentLocation = locations.firstObject;
    _googleMapView.camera = [[GMSCameraPosition alloc] initWithTarget:currentLocation.coordinate zoom:15 bearing:0 viewingAngle:0];
    [_loacationManager stopUpdatingLocation];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self geoSearchWithString:textField.text];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldChanged{
    if ([_addressTextField.text isEqualToString:@""]) {
        _mainTableView.hidden = YES;
        [_dataArray removeAllObjects];
        [_mainTableView reloadData];
    }else{
        [_autoCompleteFetcher sourceTextHasChanged:_addressTextField.text];
    }
    
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [_addressTextField selectAll:self];
}
#pragma  mark - Mapview Delegate
- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate{
    _mainTableView.hidden =YES;
    [_addressTextField resignFirstResponder];
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture{
    
    _addressTextField.text = @"移动图钉";
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position{
    
    //反向地理编码
    [[GMSGeocoder geocoder]reverseGeocodeCoordinate:position.target completionHandler:^(GMSReverseGeocodeResponse * response, NSError * error) {
        if (response.results) {
            GMSAddress *address = response.results[0];
            NSLog(@"%@",address.thoroughfare);
            _addressTextField.text = address.thoroughfare;
            
        }
    }];
}

#pragma mark -- autoCompleteDelegate
- (void)didAutocompleteWithPredictions:(NSArray<GMSAutocompletePrediction *> *)predictions{
    if (predictions.count) {
        _mainTableView.hidden = NO;
        _dataArray = (NSMutableArray *)predictions;
        [_mainTableView reloadData];
    }
}

- (void)didFailAutocompleteWithError:(NSError *)error{
    
}

- (void)textFieldSelectAll{
    [_addressTextField selectAll:self];
}

#pragma  mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    GMSAutocompletePrediction *prediction = _dataArray[indexPath.row];
    cell.textLabel.text = prediction.attributedFullText.string;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{    return 40.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    GMSAutocompletePrediction *prediction = _dataArray[indexPath.row];
    [self geoSearchWithString:prediction.attributedFullText.string];
    _mainTableView.hidden = YES;
    
}

- (void)geoSearchWithString:(NSString *)string{
    /**
     *  发起地理编码请求
     */
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=%@",[string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],GoogleMapKey];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *responseDic = responseObject;
        if ([responseDic[@"status"] isEqualToString:@"OK"]) {
            NSArray *returenArray = responseDic[@"results"];
            CLLocationCoordinate2D search ;
            NSDictionary *addressDic = returenArray[0];
            NSDictionary *locationDic = addressDic[@"geometry"][@"location"];
            search.longitude = [locationDic[@"lng"] floatValue];
            search.latitude = [locationDic[@"lat"] floatValue];
            [_googleMapView animateToLocation:search];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    [_addressTextField resignFirstResponder];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
