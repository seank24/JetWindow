//
//  FlightViewController.m
//  JetWindow
//
//  Created by Sean Kram on 9/21/15.
//  Copyright (c) 2015 SK. All rights reserved.
//

#import "InputViewController.h"
#import "FlightViewController.h"
@import GoogleMaps;


@interface FlightViewController () <GMSMapViewDelegate>

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMapView *miniMap;
@property (strong, nonatomic) GMSMutablePath *pathToHere;
@property (strong, nonatomic) GMSPolyline *tripSoFar;
@property (copy, nonatomic) NSSet *markers;
@property (strong, nonatomic) NSURLSession *markerSession;
@property (copy, nonatomic) NSArray *steps;
@property (strong, nonatomic) UILabel *estLength;
@property (strong, nonatomic) UILabel *flyoverCity;
@property (strong, nonatomic) UILabel *kmToGo;
@property (strong, nonatomic) UIButton *goBack;
@property (strong, nonatomic) UIButton *begin;
@property (strong, nonatomic) UIButton *startOver;
@property (strong, nonatomic) CLLocation *endObject;

@property (nonatomic) CLLocationCoordinate2D start;
@property (nonatomic) CLLocationCoordinate2D end;
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) CLLocationDistance dist;
@property (nonatomic) CLLocationDirection bearing;
@property (nonatomic) float maxZoom;
@property (nonatomic) float tripLength;
@property (nonatomic) float squareSize;
@property (nonatomic) BOOL arrived;
@property (nonatomic) int noDataCounter;

@end

@implementation FlightViewController

- (instancetype)init {
    return self;
}

- (instancetype)initWithStartCoord:(CLLocationCoordinate2D)start
                          endCoord:(CLLocationCoordinate2D)end {
    self = [super init];
    
    if (self) {
        self.start = start;
        self.end = end;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureRoute];
    
    GMSCameraPosition *previewCam = [GMSCameraPosition cameraWithLatitude:self.center.latitude
                                                                longitude:self.center.longitude
                                                                     zoom:1];
    GMSMapView *previewMap = [GMSMapView mapWithFrame:self.view.bounds camera:previewCam];
    previewMap.mapType = kGMSTypeHybrid;

    
    GMSMutablePath *path = [GMSMutablePath path];
    [path addCoordinate:self.start];
    [path addCoordinate:self.end];
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeWidth = 2.5;
    polyline.geodesic = NO;
    polyline.map = previewMap;
    
    GMSStrokeStyle *lineGradient = [GMSStrokeStyle gradientFromColor:[UIColor yellowColor] toColor:[UIColor redColor]];
    polyline.spans = @[[GMSStyleSpan spanWithStyle:lineGradient]];
    
    GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithPath:path];
    
    GMSMarker *startPoint = [GMSMarker markerWithPosition:self.start];
    startPoint.map = previewMap;
    
    GMSMarker *endPoint = [GMSMarker markerWithPosition:self.end];
    endPoint.map = previewMap;
                           
    self.view = previewMap;
    
    self.estLength = [[UILabel alloc] init];
    self.estLength.frame = CGRectMake(0, 20, self.view.bounds.size.width, 40);
    self.estLength.shadowColor = [UIColor blackColor];
    self.estLength.shadowOffset = CGSizeMake(1.0, 1.0);
    self.estLength.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.estLength.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:0.4f alpha:1.0f];
    self.estLength.textAlignment = NSTextAlignmentCenter;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.estLength.font = [UIFont boldSystemFontOfSize:22.5];
        startPoint.icon = [UIImage imageNamed:@"grnflag-lg.png"];
        endPoint.icon = [UIImage imageNamed:@"chkflag-lg.png"];
        [previewMap animateWithCameraUpdate:[GMSCameraUpdate fitBounds:coordBounds withPadding:108.0]];
        
    } else {
        self.estLength.font = [UIFont boldSystemFontOfSize:15.0];
        startPoint.icon = [UIImage imageNamed:@"grnflag-sm.png"];
        endPoint.icon = [UIImage imageNamed:@"chkflag-sm.png"];
        [previewMap animateWithCameraUpdate:[GMSCameraUpdate fitBounds:coordBounds withPadding:84.0]];
    }
    
    [self.view addSubview:self.estLength];
    
    int tripMins = self.tripLength * 2 / 60;
    int tripSecs = (int) self.tripLength * 2 % 60;
    
    if (tripMins == 1 && tripSecs == 1) {
        self.estLength.text = [NSString stringWithFormat:@"Your trip will take: %d minute, %d second.", tripMins, tripSecs];
    } else if (tripMins == 1) {
        self.estLength.text = [NSString stringWithFormat:@"Your trip will take: %d minute, %d seconds.", tripMins, tripSecs];
    } else if (tripSecs == 1) {
        self.estLength.text = [NSString stringWithFormat:@"Your trip will take: %d minutes, %d second.", tripMins, tripSecs];
    } else {
        self.estLength.text = [NSString stringWithFormat:@"Your trip will take: %d minutes, %d seconds.", tripMins, tripSecs];
    }
    
    
    self.goBack = [UIButton buttonWithType:UIButtonTypeSystem];
    self.goBack.frame = CGRectMake((self.view.bounds.size.width / 2) - 59, self.view.bounds.size.height - 50, 55, 30);
    [self.goBack addTarget:self
                       action:@selector(backToMain:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.goBack setTitle:@"Back" forState:UIControlStateNormal];
    [self.goBack setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.goBack.backgroundColor = [UIColor colorWithRed:128.0 green:128.90 blue:128.0 alpha:0.75];
    self.goBack.tintColor = [UIColor blueColor];
    self.goBack.layer.cornerRadius = 5;
    [self.view addSubview:self.goBack];
    
    self.begin = [UIButton buttonWithType:UIButtonTypeSystem];
    self.begin.frame = CGRectMake((self.view.bounds.size.width / 2) - 1, self.view.bounds.size.height - 50, 60, 30);
    [self.begin addTarget:self
                       action:@selector(beginTrip:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.begin setTitle:@"Begin" forState:UIControlStateNormal];
    [self.begin setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.begin.backgroundColor = [UIColor colorWithRed:128.0 green:128.90 blue:128.0 alpha:0.75];
    self.begin.tintColor = [UIColor blueColor];
    self.begin.layer.cornerRadius = 5;
    [self.view addSubview:self.begin];
    
    self.squareSize = [self getMiniMapSize];
}

- (void)viewDidLayoutSubviews {
    self.miniMap.frame = CGRectMake(5, self.view.bounds.size.height - self.squareSize - 5, self.squareSize, self.squareSize);
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.flyoverCity.font = [UIFont boldSystemFontOfSize:22.5];
        self.kmToGo.font = [UIFont boldSystemFontOfSize:21.0];
        self.kmToGo.frame = CGRectMake(self.view.bounds.size.width * .66, self.view.bounds.size.height - 50, self.view.bounds.size.width * .33, 50);
        self.startOver.frame = CGRectMake(5 + self.squareSize, self.view.bounds.size.height - 50, 65, 50);
        self.startOver.titleLabel.font = [UIFont boldSystemFontOfSize:21.0];
        self.goBack.frame = CGRectMake((self.view.bounds.size.width / 2) - 59, self.view.bounds.size.height - 50, 55, 30);
        self.begin.frame = CGRectMake((self.view.bounds.size.width / 2) - 1, self.view.bounds.size.height - 50, 60, 30);
    } else {
        self.kmToGo.frame = CGRectMake(self.view.bounds.size.width - 125, self.view.bounds.size.height - 28, 120, 28);
        self.startOver.frame = CGRectMake(5 + self.squareSize, self.view.bounds.size.height - 28, 40, 28);
        self.goBack.frame = CGRectMake((self.view.bounds.size.width / 2) - 59, self.view.bounds.size.height - 50, 55, 30);
        self.begin.frame = CGRectMake((self.view.bounds.size.width / 2) - 1, self.view.bounds.size.height - 50, 60, 30);
    }
}

- (void)beginTrip:(id)sender {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.start.latitude
                                                            longitude:self.start.longitude
                                                                 zoom:16.25
                                                              bearing:self.bearing
                                                         viewingAngle:0.0];
    
    self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    self.mapView.mapType = kGMSTypeSatellite;
    self.mapView.delegate = self;
    
    self.mapView.settings.scrollGestures = NO;
    self.mapView.settings.zoomGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    
    self.view = self.mapView;
    
    self.flyoverCity = [[UILabel alloc] init];
    self.flyoverCity.frame = CGRectMake(0, 20, self.view.bounds.size.width, 40);
    self.flyoverCity.font = [UIFont boldSystemFontOfSize:15.0];
    self.flyoverCity.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.flyoverCity.textColor = [UIColor whiteColor];
    self.flyoverCity.textAlignment = NSTextAlignmentCenter;
    self.flyoverCity.lineBreakMode = NSLineBreakByWordWrapping;
    self.flyoverCity.numberOfLines = 0;
    [self.view addSubview:self.flyoverCity];
    
    self.kmToGo = [[UILabel alloc] init];
    self.kmToGo.frame = CGRectMake(self.view.bounds.size.width - 125, self.view.bounds.size.height - 36, 120, 36);
    self.kmToGo.font = [UIFont boldSystemFontOfSize:14.0];
    self.kmToGo.textColor = [UIColor whiteColor];
    self.kmToGo.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.kmToGo.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.kmToGo];
    
    self.startOver = [[UIButton alloc] initWithFrame:CGRectMake(5 + self.squareSize, self.view.bounds.size.height - 36, 40, 36)];
    [self.startOver addTarget:self
                       action:@selector(backToMain:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.startOver setTitle:@"Back" forState:UIControlStateNormal];
    [self.startOver setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startOver.showsTouchWhenHighlighted = YES;
    self.startOver.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    self.startOver.hidden = YES;
    [self.view addSubview:self.startOver];
    
    GMSMarker *startPoint = [GMSMarker markerWithPosition:self.start];
    startPoint.map = self.mapView;
    
    GMSMarker *endPoint = [GMSMarker markerWithPosition:self.end];
    endPoint.map = self.mapView;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        startPoint.icon = [UIImage imageNamed:@"grnflag-lg.png"];
        endPoint.icon = [UIImage imageNamed:@"chkflag-lg.png"];
    } else {
        startPoint.icon = [UIImage imageNamed:@"grnflag-sm.png"];
        endPoint.icon = [UIImage imageNamed:@"chkflag-sm.png"];
    }
    
    
    GMSCameraPosition *miniCam = [GMSCameraPosition cameraWithLatitude:self.start.latitude
                                                            longitude:self.start.longitude
                                                                  zoom:self.maxZoom - 7.0];
    self.miniMap = [GMSMapView mapWithFrame:CGRectMake(5, self.view.bounds.size.height - self.squareSize - 5, self.squareSize, self.squareSize) camera:miniCam];
    self.miniMap.mapType = kGMSTypeNormal;
    
    GMSMutablePath *path = [GMSMutablePath path];
    [path addCoordinate:self.start];
    [path addCoordinate:self.end];
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeColor = [UIColor yellowColor];
    polyline.strokeWidth = 2.0;
    polyline.geodesic = NO;
    polyline.map = self.miniMap;
    
    GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithPath:path];
    [self.miniMap animateWithCameraUpdate:[GMSCameraUpdate fitBounds:coordBounds withPadding:24.0]];
    
    [self.view addSubview:self.miniMap];
    
    [self flyMeAround];
}

- (void)flyMeAround {
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:3.0f] forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:^{
        [self getCurrentCoords];
        [self andGo];
    }];
    NSLog(@"Bearing: %g", self.bearing);
    NSLog(@"Max Zoom: %g", self.maxZoom);
    NSLog(@"Distance (km): %g", self.dist);
    NSLog(@"Trip Length (sec): %g", self.tripLength * 2);
    self.mapView.mapType = kGMSTypeSatellite;
    self.arrived = NO;
    self.noDataCounter = 0;
    self.startOver.hidden = NO;
    [self.mapView animateToViewingAngle:25.0];
    
    self.pathToHere = [GMSMutablePath path];
    [self.pathToHere addCoordinate:self.start];
    [self.pathToHere addCoordinate:self.start];
    
    self.tripSoFar = [GMSPolyline polylineWithPath:self.pathToHere];
    self.tripSoFar.strokeColor = [UIColor redColor];
    self.tripSoFar.strokeWidth = 2.0;
    self.tripSoFar.geodesic = NO;
    self.tripSoFar.map = self.miniMap;
    
    [CATransaction commit];
}

- (void)andGo {
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:self.tripLength] forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:^{
        [self andLand];
    }];
    [self.mapView animateToViewingAngle:45.0];
    [self.mapView animateToZoom:self.maxZoom];
    [self.mapView animateToLocation:self.center];
    [CATransaction commit];
}

- (void)andLand {
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:self.tripLength] forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:^{
        self.arrived = YES;
    }];
    [self.mapView animateToZoom:16.25];
    [self.mapView animateToLocation:self.end];
    [CATransaction commit];
}

- (void)configureRoute {
    // Find the center point between the start and end coordinates.
    
    double lon1 = self.start.longitude * M_PI / 180;
    double lon2 = self.end.longitude * M_PI / 180;
    
    double lat1 = self.start.latitude * M_PI / 180;
    double lat2 = self.end.latitude * M_PI / 180;
    
    double dLon = lon2 - lon1;
    
    double x = cos(lat2) * cos(dLon);
    double y = cos(lat2) * sin(dLon);
    
    double lat3 = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y));
    double lon3 = lon1 + atan2(y, cos(lat1) + x);
    
    double centerLat = lat3 * 180 / M_PI;
    double centerLon = lon3 * 180 / M_PI;
    
    self.center = CLLocationCoordinate2DMake(centerLat, centerLon);
    
    self.endObject = [[CLLocation alloc] initWithLatitude:self.end.latitude longitude:self.end.longitude];
    self.dist = [self calcDistance];
    self.bearing = [self getBearing:lat1 :lat2 :lon1 :lon2];
    self.maxZoom = [self getMaxZoom];
    self.tripLength = [self getTripLength];
}

- (double)getBearing:(double)lat1 :(double)lat2 :(double)lon1 :(double)lon2 {
    lat1 = [self degreesToRadians:self.start.latitude];
    lat2 = [self degreesToRadians:self.end.latitude];
    
    lon1 = [self degreesToRadians:self.start.longitude];
    lon2 = [self degreesToRadians:self.end.longitude];
    
    double dLon = lon2 - lon1;
    
    double x = (cos(lat1) * sin(lat2)) - (sin(lat1) * cos(lat2) * cos(dLon));
    double y = sin(dLon) * cos(lat2);
    double radians = atan2(y, x);
    
    if (radians < 0.0) {
        radians += 2 * M_PI;
    }
    
    return [self radiansToDegrees:radians];
}

- (float)getMaxZoom {
    if (self.dist > 1000) {
        return 10.05;
    } else if (self.dist < 100) {
        return 13.55 + (2.2 * ((100 - self.dist) / 100));
    } else {
        return [self logWithBase:2.0 andNumber:40000.0 / ((self.dist + 100.0) / 100.0)] - 1;
    }
}

- (float)getTripLength {
    return (self.dist / 30.0) * 30.0;;
}

- (CLLocationDistance)calcDistance {
    CLLocation *startObject = [[CLLocation alloc] initWithLatitude:self.start.latitude longitude:self.start.longitude];
    
    // Converts distance received in meters into km
    return [startObject distanceFromLocation:self.endObject] / 1000;
    
}

- (double)degreesToRadians:(double)degrees {
    return degrees * M_PI / 180.0;
}

- (double)radiansToDegrees:(double)radians {
    return radians * 180.0 / M_PI;
}

- (double)logWithBase:(double)base andNumber:(double)x {
    return log(x) / log(base);
}

- (float)getMiniMapSize {
    if (self.view.bounds.size.width < self.view.bounds.size.height) {
        return self.view.bounds.size.width / 3.5;
    } else {
        return self.view.bounds.size.height / 3.5;
    }
}

- (void)getCurrentCoords {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^void{
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            CGPoint point = self.mapView.center;
            CLLocationCoordinate2D coord = [self.mapView.projection coordinateForPoint:point];
            CLLocation *currSpot = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
            CLLocationDistance currDist = [currSpot distanceFromLocation:self.endObject] / 1609.34;
            self.kmToGo.text = [NSString stringWithFormat:@"%.f mi to go", currDist];
            
            [self.pathToHere removeLastCoordinate];
            [self.pathToHere addCoordinate:coord];
            
            self.tripSoFar = [GMSPolyline polylineWithPath:self.pathToHere];
            self.tripSoFar.strokeColor = [UIColor redColor];
            self.tripSoFar.strokeWidth = 2.0;
            self.tripSoFar.geodesic = NO;
            self.tripSoFar.map = self.miniMap;
            
            // GMSCameraUpdate *miniUpdate = [GMSCameraUpdate setTarget:coord];
            // [self.miniMap animateWithCameraUpdate:miniUpdate];
            
            if (self.arrived == YES) {
                self.flyoverCity.text = @"You have arrived!";
                self.mapView.mapType = kGMSTypeHybrid;
                self.startOver.hidden = NO;
                
                self.mapView.settings.scrollGestures = YES;
                self.mapView.settings.zoomGestures = YES;
                self.mapView.settings.tiltGestures = YES;
                return;
            } else {
                [self getCurrentCity:coord];
                [self performSelector:@selector(getCurrentCoords) withObject:self afterDelay:1.0];
            }
        });
    });
}

- (void)getCurrentCity:(CLLocationCoordinate2D)coord {
    [[GMSGeocoder geocoder] reverseGeocodeCoordinate:coord completionHandler:^(GMSReverseGeocodeResponse * response, NSError *error) {
        GMSAddress *addressObj = [response.results firstObject];
        if (addressObj.locality != NULL && addressObj.administrativeArea != NULL) {
            self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@, %@", addressObj.locality, addressObj.administrativeArea];
            self.noDataCounter = 0;
            NSLog(@"lines=%@", addressObj.lines);
            return;
        } else if (addressObj.locality != NULL && addressObj.subLocality != NULL) {
            self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@, %@", addressObj.locality, addressObj.subLocality];
            self.noDataCounter = 0;
            NSLog(@"lines=%@", addressObj.lines);
            return;
        } else if (addressObj.locality != NULL && addressObj.country != NULL) {
            self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@, %@", addressObj.locality, addressObj.country];
            self.noDataCounter = 0;
            NSLog(@"lines=%@", addressObj.lines);
            return;
        } else {
            [self findWater:coord];
            self.noDataCounter++;
            
            if (self.noDataCounter >= 4 && addressObj.subLocality != NULL) {
                self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@, %@", addressObj.subLocality, addressObj.country];
                NSLog(@"lines=%@", addressObj.lines);
            } else if (self.noDataCounter >= 4 && addressObj.country != NULL) {
                self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@", addressObj.country];
                NSLog(@"lines=%@", addressObj.lines);
            }
        }
    }];
}

- (void)findWater:(CLLocationCoordinate2D)coord {
    NSString *jsonUrl = [NSString stringWithFormat:@"https://api.koordinates.com/api/vectorQuery.json?key=da442359991647ab832192e078afdfe4&layer=1294&x=%f&y=%f&max_results=1&radius=1000&geometry=false",
                         coord.longitude, coord.latitude];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:jsonUrl]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                if (!error) {
                    NSError *jsonError = nil;
                    
                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:0
                                                                                 error:&jsonError];
                    if (jsonError) {
                        NSLog(@"Serialization error: %@", jsonError.localizedDescription);
                    } else {
                        NSDictionary *vectorQuery = [dictionary valueForKey:@"vectorQuery"];
                        NSDictionary *layers = [vectorQuery valueForKey:@"layers"];
                        NSDictionary *waters = [layers valueForKey:@"1294"];
                        NSArray *features = [waters valueForKey:@"features"];
                        
                        if (features && features.count > 0) {
                            NSDictionary *featureZero = features[0];
                            NSDictionary *properties = [featureZero valueForKey:@"properties"];
                            NSString *bodyOfWater = [properties valueForKey:@"Name"];
                            self.noDataCounter = 0;
                            
                            if ([[bodyOfWater uppercaseString] isEqualToString:bodyOfWater]) {
                                bodyOfWater = [bodyOfWater capitalizedString];
                            }
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.flyoverCity.text = [NSString stringWithFormat:@"Flying over %@", bodyOfWater];
                            });
                        }
                    }
                } else {
                    NSLog(@"Error: %@", error.localizedDescription);
                }
                
            }] resume];
}


- (void)backToMain:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    UINavigationController *navController = self.navigationController;
    [navController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
