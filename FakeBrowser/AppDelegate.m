//
//  AppDelegate.m
//  FakeBrowser
//
//  Created by Sasaki Daichi on 12/07/26.
//  Copyright (c) 2012年 Sasaki Daichi. All rights reserved.
//

#import "AppDelegate.h"

BOOL isConnected = NO;
NSUserDefaults *defaults;
int nLaunch;


@implementation AppDelegate

@synthesize vc;


+ (void)initialize{
    defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObjectsAndKeys:
								 @"0", @"LaunchCount",
								 nil];
    
    [defaults registerDefaults:appDefaults];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
	 UIRemoteNotificationTypeAlert|
	 UIRemoteNotificationTypeSound];
		
	// network reachability
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called.
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
	internetReach = [Reachability reachabilityForInternetConnection];
	[internetReach startNotifier];
	[self updateInterfaceWithReachability: internetReach];
	
    wifiReach = [Reachability reachabilityForLocalWiFi];
	[wifiReach startNotifier];
	[self updateInterfaceWithReachability: wifiReach];
	
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if ([error code] == 3010) {
        NSLog(@"Push notifications don't work in the simulator!");
    } else {
        NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	nLaunch = [defaults integerForKey:@"LaunchCount"];
    nLaunch++;
	NSLog(@"nLaunch %d", nLaunch);
    
    [defaults setInteger:nLaunch forKey:@"LaunchCount"];
	[defaults synchronize];
}

// Network

- (void) configureTextField: (UITextField*) textField imageView: (UIImageView*) imageView reachability: (Reachability*) curReach
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
	
    switch (netStatus)
    {
        case NotReachable:
        {
            connectionRequired= NO;
			
			if(curReach == internetReach){
				is3GConnected = NO;
			}else if(curReach == wifiReach){
				isWifiConnected = NO;
			}
			
            break;
        }
            
        case ReachableViaWWAN:
        {
			is3GConnected = YES;
            break;
        }
        case ReachableViaWiFi:
        {
			isWifiConnected = YES;
            break;
		}
    }
    if(connectionRequired)
    {
		
    }
	
}

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
	if(curReach == internetReach)
	{
		[self configureTextField: nil imageView: nil reachability: curReach];
	}
	if(curReach == wifiReach)
	{
		[self configureTextField: nil imageView: nil reachability: curReach];
	}
	
	isConnected = (is3GConnected || isWifiConnected);
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}


@end
