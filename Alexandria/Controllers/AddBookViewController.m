//
//  AddBookViewController.m
//  Alexandria
//
//  Created by Kristen Mills on 2/9/14.
//  Copyright (c) 2014 Society of Software Engineers. All rights reserved.
//

#import "AddBookViewController.h"
#import "BarcodeScannerViewController.h"
#import "Colours.h"

@interface AddBookViewController () <BarcodeScannerViewControllerDelegate>

@end

@implementation AddBookViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	BarcodeScannerViewController *controller = (BarcodeScannerViewController *)segue.destinationViewController;
	controller.identifier = segue.identifier;
	[[segue destinationViewController] setDelegate:self];
}

- (void)addBarcodeViewController:(BarcodeScannerViewController *)controller didFinishEnteringBarcode:(NSString *)barcode forButton:(NSString *)identifier
{
	if(barcode == nil) {
		[_statusLabel setTextColor:[UIColor grapefruitColor]];
		[_statusLabel setText:@"Invalid Barcode"];
	} else {
		[_statusLabel setTextColor:[UIColor greenColor]];
		[_statusLabel setText:@"Successfully Scanned!"];
		if([identifier isEqualToString:@"book"]) {
			[_isbnField setText:barcode];
		} else if([identifier isEqualToString:@"librarian"]) {
			[_librarianField setText:barcode];
		}
	}
}

- (IBAction)submitAddBook:(id)sender {
	[_statusLabel setTextColor:[UIColor blackColor]];
	[_statusLabel setText:@"Attempting to Add Book..."];
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	NSURL *URL = [NSURL URLWithString:@"http://alexandria.ad.sofse.org:8080/books.json"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	// Set request type
	request.HTTPMethod = @"POST";
	
	// Set params to be sent to the server
	NSString *params = [NSString stringWithFormat:@"isbn=%@&librarian_barcode=%@", _isbnField.text, _librarianField.text];
	// Encoding type
	NSData *data = [params dataUsingEncoding:NSUTF8StringEncoding];
	// Add values and contenttype to the http header
	[request addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:data];
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	NSString *dataString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
	if(error != nil){
		NSString *message = [error localizedDescription];
		[_statusLabel setTextColor:[UIColor grapefruitColor]];
		[_statusLabel setText:[NSString stringWithFormat:@"Error: %@", message]];
	}else{
		NSError *e;
		NSDictionary *json =[NSJSONSerialization JSONObjectWithData: [dataString dataUsingEncoding:NSUTF8StringEncoding]
															options: NSJSONReadingMutableContainers
															  error: &e];
		NSInteger status = [(NSHTTPURLResponse*)response statusCode];
		if(status == 201){
			[_statusLabel setTextColor:[UIColor cardTableColor]];
			[_statusLabel setText:[NSString stringWithFormat:@"You've successfully added the book %@!", [json valueForKey:@"title"]]];
		}else {
			[_statusLabel setTextColor:[UIColor grapefruitColor]];
			NSString* string = @"Errors:\n";
			for(id key  in [json keyEnumerator]){
				NSArray* array = [json valueForKey:key];
				for(id phrase in array){
					string = [string stringByAppendingString:[NSString stringWithFormat:@"%@\n", phrase]];
				}
			}
			[_statusLabel setText:string];
		}
	}
}
@end
