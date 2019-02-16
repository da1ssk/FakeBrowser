//
//  MainViewController.h
//  WildBrowser
//
//  Created by Sasaki Daichi on 12/07/26.
//  Copyright (c) 2012年 Sasaki Daichi. All rights reserved.
//

#import "FlipsideViewController.h"
#import "MBProgressHUD.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <AVFoundation/AVFoundation.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, MBProgressHUDDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, AVAudioPlayerDelegate> {

	IBOutlet UIView *titleView;
	IBOutlet UIView *converterView;
	IBOutlet UIView *browserView;

	IBOutlet UITextView *originalTextView;
	IBOutlet UITextView *convertedTextView;

	IBOutlet UIWebView *webView;
	IBOutlet UIBarButtonItem *forwardButton;
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UISearchBar *searchBar;
	
	NSString *hostName;
	NSMutableArray *dicArray;
}

@property (nonatomic, strong) AVAudioPlayer *theAudio;

-(IBAction) pressedConverterButton :(id)sender;
-(IBAction) pressedBrowserButton :(id)sender;
-(IBAction) pressedSugchanButton :(id)sender;
-(IBAction) pressedConvertButton:(id)sender;
-(IBAction) pressedConvertShareButton:(id)sender;
-(IBAction) pressedClearButton:(id)sender;
-(IBAction)pressedTextShareButton:(id)sender;


@end
