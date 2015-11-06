//
//  ViewController.m
//  JetWindow
//
//  Created by Sean Kram on 9/22/15.
//  Copyright © 2015 SK. All rights reserved.
//

#import "InputViewController.h"
#import "FlightViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface InputViewController () 

@property (strong, nonatomic) UIImageView *logo;
@property (strong, nonatomic) UIImageView *aerialBack;
@property (strong, nonatomic) UITextField *fromPlace;
@property (strong, nonatomic) UITextField *toPlace;
@property (strong, nonatomic) UILabel *fromLabel;
@property (strong, nonatomic) UILabel *toLabel;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *goButton;
@property (nonatomic) CLLocationCoordinate2D start;
@property (nonatomic) CLLocationCoordinate2D end;

@end

@implementation InputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.aerialBack = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aerial-bkgd.jpg"]];
    self.aerialBack.contentMode = UIViewContentModeScaleAspectFill;
    self.aerialBack.alpha = 0.7;
    
    CGRect backFrame;
    if ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) {
        backFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
        backFrame.size.height = [[UIScreen mainScreen] bounds].size.height;
    } else {
        backFrame.size.height = [[UIScreen mainScreen] bounds].size.width;
        backFrame.size.width = [[UIScreen mainScreen] bounds].size.height;
    }
    
    self.aerialBack.frame = backFrame;
    
    [self.view addSubview:self.aerialBack];
    
    
    self.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"jw-logo.jpg"]];
    self.logo.contentMode = UIViewContentModeScaleAspectFit;
    self.logo.frame = CGRectMake(self.view.bounds.size.width / 8, self.view.bounds.size.height / 7,
                            self.view.bounds.size.width - (self.view.bounds.size.width / 4),
                            80);
    [self.view addSubview:self.logo];
    
    
    self.fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,(self.view.bounds.size.height / 2) - 45,100,21)];
    self.fromLabel.font = [UIFont systemFontOfSize:17.0];
    self.fromLabel.textColor = [UIColor whiteColor];
    self.fromLabel.textAlignment = NSTextAlignmentCenter;
    self.fromLabel.text = @"Fly me from:";
    
    self.toLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,(self.view.bounds.size.height / 2) - 5,100,21)];
    self.toLabel.font = [UIFont systemFontOfSize:17.0];
    self.toLabel.textColor = [UIColor whiteColor];
    self.toLabel.textAlignment = NSTextAlignmentCenter;
    self.toLabel.text = @"To:";
    
    self.errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, (self.view.bounds.size.height / 2) + 35, self.view.bounds.size.width - 16, 42)];
    self.errorLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.errorLabel.textColor = [UIColor whiteColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.errorLabel.numberOfLines = 0;
    
    [self.view addSubview:self.fromLabel];
    [self.view addSubview:self.toLabel];
    [self.view addSubview:self.errorLabel];
    
    self.fromPlace = [[UITextField alloc] initWithFrame:CGRectMake(112,(self.view.bounds.size.height / 2) - 47, (self.view.bounds.size.width - 120), 25)];
    self.fromPlace.font = [UIFont systemFontOfSize:17.0];
    self.fromPlace.backgroundColor = [UIColor whiteColor];
    self.fromPlace.borderStyle = UITextBorderStyleRoundedRect;
    self.fromPlace.delegate = self;
    
    self.toPlace = [[UITextField alloc] initWithFrame:CGRectMake(112,(self.view.bounds.size.height / 2) - 7, (self.view.bounds.size.width - 120), 25)];
    self.toPlace.font = [UIFont systemFontOfSize:17.0];
    self.toPlace.backgroundColor = [UIColor whiteColor];
    self.toPlace.borderStyle = UITextBorderStyleRoundedRect;
    self.toPlace.delegate = self;
    
    [self.view addSubview:self.fromPlace];
    [self.view addSubview:self.toPlace];
    
    self.goButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width / 2) - 33, self.view.bounds.size.height - 150, 66, 30)];
    [self.goButton addTarget:self
                 action:@selector(beginFlight:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.goButton setTitle:@"Go!" forState:UIControlStateNormal];
    [self.goButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.goButton.showsTouchWhenHighlighted = YES;
    
    [self.view addSubview:self.goButton];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewDidLayoutSubviews {
    if ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) {
        [self setVerticalLayout];
    } else {
        [self setHorizontalLayout];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    self.errorLabel.hidden = YES;
}

- (void)hideKeyboard {
    [self.fromPlace resignFirstResponder];
    [self.toPlace resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.fromPlace resignFirstResponder];
    [self.toPlace resignFirstResponder];
    return YES;
}

- (void)beginFlight:(id)sender {
    self.errorLabel.hidden = YES;
    self.fromPlace.layer.borderColor=[[UIColor clearColor] CGColor];
    self.toPlace.layer.borderColor=[[UIColor clearColor] CGColor];
    
    if ([self.fromPlace.text isEqual:@""]) {
        self.fromPlace.layer.cornerRadius = 8.0f;
        self.fromPlace.layer.masksToBounds = YES;
        self.fromPlace.layer.borderColor = [[UIColor redColor] CGColor];
        self.fromPlace.layer.borderWidth = 0.75f;
        
        self.errorLabel.text = @"Please enter a starting location first!";
        self.errorLabel.hidden = NO;
    } else if ([self.toPlace.text isEqual:@""]) {
        self.toPlace.layer.cornerRadius = 8.0f;
        self.toPlace.layer.masksToBounds = YES;
        self.toPlace.layer.borderColor = [[UIColor redColor] CGColor];
        self.toPlace.layer.borderWidth = 0.75f;
        
        self.errorLabel.text = @"Please enter a destination first!";
        self.errorLabel.hidden = NO;
    } else {
        [self parseStart:self.fromPlace.text];
        
        self.errorLabel.text = @"Loading trip...";
        self.errorLabel.hidden = NO;
    }
}

- (void)parseStart:(NSString *)coordString {

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:coordString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            if (placemarks && placemarks.count > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                NSLog(@"%@", location);
                NSLog(@"%f", location.coordinate.latitude);
                self.start = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                [self parseEnd:self.toPlace.text];
            }
        } else {
            NSLog(@"parseStart error: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.fromPlace.layer.cornerRadius = 8.0f;
                self.fromPlace.layer.masksToBounds = YES;
                self.fromPlace.layer.borderColor = [[UIColor redColor] CGColor];
                self.fromPlace.layer.borderWidth = 0.75f;
                
                self.errorLabel.text = @"Sorry, the starting location you specified was invalid.";
                self.errorLabel.hidden = NO;
            });
        }
    }];
}

- (void)parseEnd:(NSString *)coordString {
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:coordString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            if (placemarks && placemarks.count > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                NSLog(@"%@", location);
                NSLog(@"%f", location.coordinate.latitude);
                self.end = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                [self takeoff];
            }
        } else {
            NSLog(@"parseEnd error: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.toPlace.layer.cornerRadius = 8.0f;
                self.toPlace.layer.masksToBounds = YES;
                self.toPlace.layer.borderColor = [[UIColor redColor] CGColor];
                self.toPlace.layer.borderWidth = 0.75f;
                
                self.errorLabel.text = @"Sorry, the destination you specified was invalid.";
                self.errorLabel.hidden = NO;
            });
        }
    }];
}

- (void)takeoff {
    FlightViewController *fvc = [[FlightViewController alloc] initWithStartCoord:self.start
                                                                        endCoord:self.end];
    [self.navigationController pushViewController:fvc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setVerticalLayout {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.logo.frame = CGRectMake(self.view.bounds.size.width * .08, self.view.bounds.size.height * .14,
                                     self.view.bounds.size.width * .84, 80);
        self.fromLabel.frame = CGRectMake(self.view.bounds.size.width * .5 - 300, self.view.bounds.size.height * .5 - 45, 100, 21);
        self.toLabel.frame = CGRectMake(self.view.bounds.size.width * .5 - 300, self.view.bounds.size.height * .5 - 5, 100, 21);
        self.errorLabel.frame = CGRectMake(8, self.view.bounds.size.height * .5 + 35, self.view.bounds.size.width - 16, 42);
        self.fromPlace.frame = CGRectMake(self.view.bounds.size.width * .5 - 188, self.view.bounds.size.height * .5 - 47, 488, 25);
        self.toPlace.frame = CGRectMake(self.view.bounds.size.width * .5 - 188, self.view.bounds.size.height * .5 - 7, 488, 25);
        self.goButton.frame = CGRectMake(self.view.bounds.size.width * .5 - 75, self.view.bounds.size.height - 175, 150, 80);
        self.goButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
        self.errorLabel.font = [UIFont boldSystemFontOfSize:20.0];
    } else {
        self.logo.frame = CGRectMake(self.view.bounds.size.width / 8, self.view.bounds.size.height / 7,
                                     self.view.bounds.size.width - (self.view.bounds.size.width / 4),
                                     80);
        self.fromLabel.frame = CGRectMake(8,(self.view.bounds.size.height / 2) - 45,100,21);
        self.toLabel.frame = CGRectMake(8,(self.view.bounds.size.height / 2) - 5,100,21);
        self.errorLabel.frame = CGRectMake(8, (self.view.bounds.size.height / 2) + 35, self.view.bounds.size.width - 16, 42);
        self.fromPlace.frame = CGRectMake(112,(self.view.bounds.size.height / 2) - 47, (self.view.bounds.size.width - 120), 25);
        self.toPlace.frame = CGRectMake(112,(self.view.bounds.size.height / 2) - 7, (self.view.bounds.size.width - 120), 25);
        self.goButton.frame = CGRectMake(self.view.bounds.size.width * .5 - 75, self.view.bounds.size.height - 175, 150, 80);
    }
}

- (void)setHorizontalLayout {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.logo.frame = CGRectMake(self.view.bounds.size.width * .08, self.view.bounds.size.height * .14,
                                     self.view.bounds.size.width * .84, 80);
        self.fromLabel.frame = CGRectMake(self.view.bounds.size.width * .5 - 375, self.view.bounds.size.height * .5 - 45, 100, 21);
        self.toLabel.frame = CGRectMake(self.view.bounds.size.width * .5 - 375, self.view.bounds.size.height * .5 - 5, 100, 21);
        self.errorLabel.frame = CGRectMake(8, self.view.bounds.size.height * .5 + 35, self.view.bounds.size.width - 16, 42);
        self.fromPlace.frame = CGRectMake(self.view.bounds.size.width * .5 - 263, self.view.bounds.size.height * .5 - 47, 638, 25);
        self.toPlace.frame = CGRectMake(self.view.bounds.size.width * .5 - 263, self.view.bounds.size.height * .5 - 7, 638, 25);
        self.goButton.frame = CGRectMake(self.view.bounds.size.width * .5 - 75, self.view.bounds.size.height - 175, 150, 80);
        self.goButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
        self.errorLabel.font = [UIFont boldSystemFontOfSize:20.0];
    } else {
        self.logo.frame = CGRectMake(self.view.bounds.size.width / 3.5, self.view.bounds.size.height / 10,
                                     self.view.bounds.size.width - (self.view.bounds.size.width / 1.75),
                                     80);
        self.fromLabel.frame = CGRectMake(8,(self.view.bounds.size.height / 2) - 30,100,21);
        self.toLabel.frame = CGRectMake(8,(self.view.bounds.size.height / 2) + 10,100,21);
        self.fromPlace.frame = CGRectMake(112,(self.view.bounds.size.height / 2) - 32, (self.view.bounds.size.width - 120), 25);
        self.toPlace.frame = CGRectMake(112,(self.view.bounds.size.height / 2) + 8, (self.view.bounds.size.width - 120), 25);
        self.errorLabel.frame = CGRectMake(8, (self.view.bounds.size.height / 2) + 30, self.view.bounds.size.width - 16, 42);
        self.goButton.frame = CGRectMake((self.view.bounds.size.width / 2) - 33, (self.view.bounds.size.height / 2) + 85, 66, 30);
    }
}

@end
