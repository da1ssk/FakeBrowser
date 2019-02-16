//
//  AppDelegate.h
//  WildBrowser
//
//  Created by Sasaki Daichi on 12/07/26.
//  Copyright (c) 2012年 Sasaki Daichi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MainViewController.h"

#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
	
    MainViewController *vc;
	
	Reachability* internetReach;
	Reachability* wifiReach;
	BOOL isWifiConnected;
	BOOL is3GConnected;
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) IBOutlet MainViewController *vc;

@end
