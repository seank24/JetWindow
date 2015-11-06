//
//  FlightViewController.h
//  JetWindow
//
//  Created by Sean Kram on 9/22/15.
//  Copyright © 2015 SK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FlightViewController : UIViewController

- (instancetype)initWithStartCoord:(CLLocationCoordinate2D)start
                          endCoord:(CLLocationCoordinate2D)end;

@end
