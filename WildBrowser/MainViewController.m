//
//  MainViewController.m
//  WildBrowser
//
//  Created by Sasaki Daichi on 12/07/26.
//  Copyright (c) 2012年 Sasaki Daichi. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <Twitter/TWTweetComposeViewController.h>
#import <StoreKit/StoreKit.h>

MBProgressHUD *HUD;
NSFileManager *fm;
NSString *docDir;
BOOL iPhone5 = NO;

extern BOOL isConnected;
extern int nLaunch;

@interface MainViewController ()

@end

@implementation MainViewController

+(void)initialize {
	if ([[UIScreen mainScreen] bounds].size.height == 568) {
		iPhone5 = YES;
	} else {
		iPhone5 = NO;
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.vc = self;
	
	fm = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	docDir = [paths objectAtIndex:0];
	NSString *savePath = [docDir stringByAppendingPathComponent:@"tmp/"];
	[fm removeItemAtPath:savePath error:nil];
	[fm createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:nil];

	// load dictionary
	NSString* dicpath = [[NSBundle mainBundle] pathForResource:@"wild" ofType:@"txt"];
	NSString *dictionary = [NSString stringWithContentsOfFile:dicpath encoding:NSUTF8StringEncoding error:nil];
	NSArray *tmpDicArray = [dictionary componentsSeparatedByString:@"\n"];
	
	dicArray = [[NSMutableArray alloc]initWithCapacity:100];
	
	for(int i=0; i<[tmpDicArray count]; i++){
		NSString *line = (NSString *)[tmpDicArray objectAtIndex:i];
		
		NSRange rng = [line rangeOfString:@"#"];
		if(rng.location == 0 || [line length] == 0)
			continue;
		
		NSArray *lineElem = [line componentsSeparatedByString:@","];
		[dicArray addObject:lineElem];
	}
	
//	backButton.enabled = forwardButton.enabled = NO;

	[self goHome];
	
	if (iPhone5) {
		CGRect r = webView.frame;
		r.size.height = 410;
		webView.frame = r;
	}


	NSString *path = [[NSBundle mainBundle] pathForResource:@"wild" ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: path];
    self.theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:NULL];
    self.theAudio.volume = 1.0;
    self.theAudio.delegate = self;
}

-(IBAction) pressedConverterButton :(id)sender {
	browserView.hidden = YES;
	converterView.hidden = NO;

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];

	CGRect r = [[UIScreen mainScreen] bounds];
	titleView.frame = CGRectMake(0, -r.size.height, titleView.frame.size.width, titleView.frame.size.height);

	[UIView commitAnimations];
}

-(IBAction) pressedBrowserButton :(id)sender {
	browserView.hidden = NO;
	converterView.hidden = YES;

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];

	CGRect r = [[UIScreen mainScreen] bounds];
	titleView.frame = CGRectMake(0, -r.size.height, titleView.frame.size.width, titleView.frame.size.height);

	[UIView commitAnimations];
}

-(IBAction) pressedSugchanButton :(id)sender {
	[originalTextView resignFirstResponder];

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];

	CGRect r = [[UIScreen mainScreen] bounds];
	titleView.frame = CGRectMake(0, 0, titleView.frame.size.width, titleView.frame.size.height);

	[UIView commitAnimations];
}

-(IBAction) pressedConvertButton:(id)sender {
	// hide keyboard
	[originalTextView resignFirstResponder];

	// play sound
    [self.theAudio prepareToPlay];
    [self.theAudio play];

	// convert
	NSString *orgSentense = originalTextView.text;

	if (! [orgSentense hasSuffix:@"。"]) {
		if ([orgSentense length] == 0)
			orgSentense = [orgSentense stringByAppendingString:@"何もなくたって変換しちゃうぜぇ。"];
		else
			orgSentense = [orgSentense stringByAppendingString:@"。"];
	}

	// convert
	int nAry = [dicArray count];
	for(int i=0; i<nAry; i++){
		NSArray *dicElem = (NSArray *)[dicArray objectAtIndex:i];
		NSString *orgStr = (NSString *)[dicElem objectAtIndex:0];
		NSString *newStr = (NSString *)[dicElem objectAtIndex:1];
		newStr = [NSString stringWithFormat:@"%@%@", newStr, @"ワイルドだろ〜。"];
		orgSentense = [orgSentense stringByReplacingOccurrencesOfString:orgStr withString:newStr];
	}

	if (! [orgSentense hasSuffix:@"ワイルドだろ〜。"]) {
		orgSentense = [orgSentense stringByAppendingString:@"ワイルドだろ〜。"];
	}
	
	convertedTextView.text = orgSentense;
	
}

-(IBAction) pressedConvertShareButton:(id)sender {
	NSString *text = convertedTextView.text;

	if(NSClassFromString(@"UIActivityViewController")) {
		NSString *shareText = [NSString stringWithFormat:@"ワイルドコンバーター！ http://ow.ly/ekLe8 %@", text];
		NSArray *activityItems = @[shareText];

		UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

		NSArray *excludeActivities = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypeMessage];
		activityController.excludedActivityTypes = excludeActivities;

		[self presentViewController:activityController animated:YES completion:^{
			NSLog(@"Activity complete!!");
		}];
	}
	else if (NSClassFromString(@"TWTweetComposeViewController")) {
		UIActionSheet *as = [[UIActionSheet alloc] init];
		as.tag = 10;
		as.delegate = self;
		as.title = @"コンバート結果をシェアするぜぇ";
		[as addButtonWithTitle:@"Twitter"];
		[as addButtonWithTitle:@"メール"];
		[as addButtonWithTitle:@"キャンセル"];
		as.cancelButtonIndex = 2;
		[as showInView:self.view];
	} else {
		UIActionSheet *as = [[UIActionSheet alloc] init];
		as.tag = 20;
		as.delegate = self;
		as.title = @"コンバート結果をシェアするぜぇ";
		[as addButtonWithTitle:@"メール"];
		[as addButtonWithTitle:@"キャンセル"];
		as.cancelButtonIndex = 1;
		[as showInView:self.view];
	}
}


-(IBAction) pressedClearButton:(id)sender {
	originalTextView.text = convertedTextView.text = @"";
}

-(void) startFlurryTimer:(float) interval {
}

-(void) showAppBankNetwork {
}

-(void) showAppBankNetworkInConverter {
}

-(IBAction) goHome {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSURL *url;
	
	if (isConnected) {
		url = [NSURL URLWithString:@"https://da1ssk.github.io/wildbrowser/index.html"];
	} else {
		url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
	}
	
	[webView loadRequest:[NSURLRequest requestWithURL:url]];
}

int showFlurryAdCount = 0;

-(void) showFlurryAd {
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	return NO;//(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
}

-(void) showHUD {
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	HUD.delegate = self;
	HUD.labelText = @"コンバート中だぜぇ。ワイルドだろ〜。";
	[HUD show:YES];
}


BOOL bConverted = NO;
int webViewLoads_ = 0;

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked){
		bConverted = NO;
		webViewLoads_ = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
//		[self showHUD];
	}
	
	return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
	webViewLoads_++;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	webViewLoads_--;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	if (webViewLoads_ > 0) {
		return;
	}
	
	if (! bConverted) {
		bConverted = YES;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		// c.f. http://blog.yatsu.info/2010/05/iphoneuiwebview.html?m=1

		// get the original HTML
		NSString *html = [aWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML;"];
		
		// convert
		int nAry = [dicArray count];
		for(int i=0; i<nAry; i++){
			NSArray *dicElem = (NSArray *)[dicArray objectAtIndex:i];
			NSString *orgStr = (NSString *)[dicElem objectAtIndex:0];
			NSString *newStr = (NSString *)[dicElem objectAtIndex:1];
			newStr = [NSString stringWithFormat:@"%@%@", newStr, @"<b>ワイルドだろ〜 </b>"];
			html = [html stringByReplacingOccurrencesOfString:orgStr withString:newStr];
		}
		
		// escape quotation marks
		html = [html stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
//		html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
		
		// make it one line
		html = [html stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
		
	//	NSLog(html);
		
		// execute the JavaScript code
		NSString *js = [NSString stringWithFormat:@"document.body.innerHTML = '%@';", html];
		[aWebView stringByEvaluatingJavaScriptFromString:js];
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	//	[HUD hide:YES];
	}
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	bConverted = NO;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	[searchBar resignFirstResponder];
	
	NSString *text = [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSRange rangeHttp = [text rangeOfString:@"http://"];
	NSRange rangeHttps = [text rangeOfString:@"https://"];
	NSString *urlString;
	NSString *urlStringForDisplay;
	
	if(rangeHttp.length != 0 || rangeHttps.length != 0){
		urlString = text;
		urlStringForDisplay = searchBar.text;
	}else{
		urlString = @"https://www.google.co.jp/search?q=QUERY&ie=UTF-8&oe=UTF-8&hl=ja&client=safari";
		urlStringForDisplay = [urlString stringByReplacingOccurrencesOfString:@"QUERY" withString:searchBar.text];
		urlString = [urlString stringByReplacingOccurrencesOfString:@"QUERY" withString:text];
	}
	
	searchBar.text = urlStringForDisplay;
	
	NSURL *url = [NSURL URLWithString:urlString];
	[webView loadRequest:[NSURLRequest requestWithURL:url]];
	
}


-(IBAction) pressedBack{
	bConverted = NO;
	webViewLoads_ = 0;
	
	[webView goBack];
}

-(IBAction) pressedForward{
	bConverted = NO;
	webViewLoads_ = 0;
	
	[webView goForward];
}

enum {
	ALERT_RATE=100
};


NSTimer *loadProductTimer;

-(IBAction) pressedInfo {
	Class c = NSClassFromString(@"SKStoreProductViewController");
	int appId;
	if (c) {
		HUD = [[MBProgressHUD alloc] initWithView:self.view];
		[self.view addSubview:HUD];
		HUD.mode = MBProgressHUDModeIndeterminate;
		HUD.delegate = self;
		[HUD show:YES];

		// timeout timer just in case
		loadProductTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkLoadProductTimeout) userInfo:nil repeats:NO];

		SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
		viewController.delegate = self;

		// Kakumei URL: https://itunes.apple.com/jp/artist/kakumei/id348827338
		NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier: [NSNumber numberWithInteger:348827338]};

		[viewController loadProductWithParameters:parameters completionBlock: ^(BOOL result, NSError *error) {
			if (result) {
				[self presentViewController:viewController animated:YES completion:nil];
			} else {
				// error
			}

			if (HUD)
				[HUD hide:YES];

			if (loadProductTimer) {
				[loadProductTimer invalidate];
				loadProductTimer = nil;
			}
		}];

	} else {
		UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"" message:@"ワイルドコンバーター、気に入っただろぉ〜。5つ星よろしくだぜぇ〜。" delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:@"ワイルドだろぉ〜", nil];
		av.tag = ALERT_RATE;
		[av show];
	}
}
-(void) checkLoadProductTimeout {
	loadProductTimer = nil;

	if (HUD) {
		[HUD hide:YES];

		UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"" message:@"ワイルドコンバーター、気に入っただろぉ〜。5つ星よろしくだぜぇ〜。" delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:@"ワイルドだろぉ〜", nil];
		av.tag = ALERT_RATE;
		[av show];
	}
}
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:^{

	}];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (alertView.tag == ALERT_RATE) {
		if (buttonIndex == 1)
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ow.ly/ekLe8"]];
	}
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden {
	// Remove HUD from screen when the HUD was hidded
	[HUD removeFromSuperview];
	HUD = nil;
}


#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}


// save a screen capture
-(IBAction)pressedShareButton:(id)sender {
	UIImage *image = [self captureView:webView];

	if(NSClassFromString(@"UIActivityViewController")) {
		NSString *shareText = @"ワイルドコンバーターだぜぇ〜。ワイルドだろぉ〜。http://ow.ly/ekLe8 ";
//		NSURL *shareURL = [NSURL URLWithString:@"http://ow.ly/ekLe8"];
		NSArray *activityItems = @[image, shareText];

		UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

		NSArray *excludeActivities = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypeMessage];
		activityController.excludedActivityTypes = excludeActivities;

		// modalで表示
		[self presentViewController:activityController animated:YES completion:^{
			NSLog(@"Activity complete!!");
		}];
	}
	else if (NSClassFromString(@"TWTweetComposeViewController")) {
		UIActionSheet *as = [[UIActionSheet alloc] init];
		as.tag = 1;
		as.delegate = self;
		as.title = @"スクリーンショットをシェアするぜぇ";
		[as addButtonWithTitle:@"Twitter"];
		[as addButtonWithTitle:@"メール"];
		[as addButtonWithTitle:@"カメラロールに保存"];
		[as addButtonWithTitle:@"キャンセル"];
		as.cancelButtonIndex = 3;
		[as showInView:self.view];
	} else {
		UIActionSheet *as = [[UIActionSheet alloc] init];
		as.tag = 2;
		as.delegate = self;
		as.title = @"スクリーンショットをシェアするぜぇ";
		[as addButtonWithTitle:@"メール"];
		[as addButtonWithTitle:@"カメラロールに保存"];
		[as addButtonWithTitle:@"キャンセル"];
		as.cancelButtonIndex = 2;
		[as showInView:self.view];
	}
}


- (UIImage *)captureView:(UIView *)view {
    CGRect screenRect = [view bounds];

	CGSize size = screenRect.size;
	if (UIGraphicsBeginImageContextWithOptions != NULL) {
		UIGraphicsBeginImageContextWithOptions(size, YES, 0);
	} else {
		UIGraphicsBeginImageContext(size);
	}

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//	HUD.hidden = YES;
	
}

-(void) tweetImage {
	NSString *shareText = @"ワイルドコンバーターだぜぇ〜。ワイルドだろぉ〜。http://ow.ly/ekLe8";
//	NSURL *shareURL = [NSURL URLWithString:@"http://ow.ly/ekLe8"];
	
	TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
	[tweetViewController setInitialText:[NSString stringWithFormat:shareText]];
	[tweetViewController addImage:[self captureView:webView]];

	[tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
		if (result == TWTweetComposeViewControllerResultDone) {
			// show message
			
		}
		[self dismissModalViewControllerAnimated:YES];
	}];
	
	// http://stackoverflow.com/questions/1823317/how-do-i-legally-get-the-current-first-responder-on-the-screen-on-an-iphone
	[self presentViewController:tweetViewController animated:YES completion:^{

	}];
}

-(void) tweetText{
	NSString *shareText = @"ワイルドコンバーター！ http://ow.ly/ekLe8 %@";

	TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
	NSString *tweettxt = [NSString stringWithFormat:shareText, convertedTextView.text];

	if ([tweettxt length] > 140) [tweetViewController setInitialText:[tweettxt substringToIndex:140]];
	else [tweetViewController setInitialText:tweettxt];
	
	[tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
		if (result == TWTweetComposeViewControllerResultDone) {
			// show message

		}
		[self dismissModalViewControllerAnimated:YES];
	}];

	// http://stackoverflow.com/questions/1823317/how-do-i-legally-get-the-current-first-responder-on-the-screen-on-an-iphone
	[self presentViewController:tweetViewController animated:YES completion:^{

	}];
}

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 1) {	// iOS 5
		switch (buttonIndex) {
			case 0:	// Twitter
				[self tweetImage];
				break;
			case 1:	// Email
				[self displayComposerSheetAndAttach];
				break;
			case 2:	// Save
				[self saveImage];
				break;
			default:
				break;
		}
	} else if (actionSheet.tag == 2) {	// iOS 4.3
		switch (buttonIndex) {
			case 0:	// Email
				[self displayComposerSheetAndAttach];
				break;
			case 1:	// Save
				[self saveImage];
				break;
			default:
				break;
		}
	} else if (actionSheet.tag == 10) {	// iOS 5
		switch (buttonIndex) {
			case 0:	// Twitter
				[self tweetText];
				break;
			case 1:	// Email
				[self displayComposerSheet];
				break;
			default:
				break;
		}
	} else if (actionSheet.tag == 20) {	// iOS 4.3
		switch (buttonIndex) {
			case 0:	// Email
				[self displayComposerSheet];
				break;
			default:
				break;
		}
	}
}

-(void) saveImage {
	UIImageWriteToSavedPhotosAlbum([self captureView:webView], self, @selector(finishUIImageWriteToSavedPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}

#pragma mark -
#pragma mark Compose Mail

-(IBAction) openMailAttach:(id)sender{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));

    if (mailClass != nil)
	{
        if ([mailClass canSendMail]){
            [self displayComposerSheetAndAttach];
        }
        else{
            [self launchMailAppOnDevice];
        }
    }
    else{
        [self launchMailAppOnDevice];
    }
}
-(void)launchMailAppOnDevice
{
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"mailto:"]];
}

// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayComposerSheetAndAttach
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

	CFTimeInterval time = CFAbsoluteTimeGetCurrent();
	int iTime = time;
	NSString *jpegname = [NSString stringWithFormat:@"%d.jpg", iTime];
	[picker addAttachmentData:UIImageJPEGRepresentation([self captureView:webView], 0.8)
					 mimeType:@"image/jpeg"
					 fileName:jpegname];

    NSString *title;
	NSString *emailBody;
	title = @"ワイルドコンバーター";
	emailBody = @"ワイルドコンバーターだぜぇ〜。ワイルドだろぉ〜。<a href=\n\nhttp://ow.ly/ekLe8>App Store</a>";

    [picker setSubject:[title stringByAppendingString:@"!"]];
    [picker setMessageBody:emailBody isHTML:YES];

    [self presentModalViewController:picker animated:YES];
}

-(void)displayComposerSheet
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    NSString *title;
	NSString *emailBody;
	title = @"ワイルドコンバーター！";
	emailBody = [NSString stringWithFormat:@"ワイルドコンバーターだぜぇ〜。ワイルドだろぉ〜。<a href=http://ow.ly/ekLe8>App Store</a><br><br>%@", convertedTextView.text];

    [picker setMessageBody:emailBody isHTML:YES];

    [self presentModalViewController:picker animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    UIAlertView *av;
	NSString *aMessage;

    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //          message.text = @"Result: canceled";
            break;
        case MFMailComposeResultSaved:
            //         message.text = @"Result: saved";
            break;
        case MFMailComposeResultSent:
		{
			NSLog(@"sent");
            break;
		}
        case MFMailComposeResultFailed:
            //         message.text = @"Result: failed";
			NSLog(@"failed");

			aMessage = NSLocalizedString(@"Failed to send email", nil);

			av = [[UIAlertView alloc]initWithTitle:@"" message:aMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[av show];
            break;
        default:
            //         message.text = @"Result: not sent";
            break;
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
    [super dealloc];
}


@end
