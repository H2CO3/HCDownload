/*
 * HCDownloadViewController.m
 * HCDownload
 *
 * Created by Árpád Goretity on 25/07/2012.
 * Licensed under the 3-clause BSD License
 */

#import <QuartzCore/QuartzCore.h>
#import "HCDownloadViewController.h"

/*
 * User info keys for internal use
 */
#define kHCDownloadKeyURL @"URL"
#define kHCDownloadKeyStartTime @"startTime"
#define kHCDownloadKeyTotalSize @"totalSize"
#define kHCDownloadKeyConnection @"connection"
#define kHCDownloadKeyFileHandle @"fileHandle"
#define kHCDownloadKeyUserInfo @"userInfo"

/*
 * Private methods
 */
@interface HCDownloadViewController ()
- (void)removeURL:(NSURL *)url;
- (void)removeURLAtIndex:(NSInteger)index;
- (void)setupCell:(HCDownloadCell *)cell withAttributes:(NSDictionary *)attr;
- (void)cancelDownloadingURLAtIndex:(NSInteger)index;
@end

@implementation HCDownloadViewController

@synthesize downloadDirectory;
@synthesize delegate;

- (id)init
{
	return [self initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super initWithStyle:style])) {
		downloads = [[NSMutableArray alloc] init];
		self.downloadDirectory = @"/var/mobile/Downloads";
		self.title = NSLocalizedString(@"Downloads", nil);
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)] autorelease];
	}
	return self;
}

- (void)dealloc
{
	// Cancel all downloads in progress
	[self.tableView beginUpdates];
	while (downloads.count > 0) {
		[self removeURLAtIndex:0];
	}

	[self.tableView endUpdates];

	[downloads release];
	self.downloadDirectory = nil;
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
{
	return o = UIInterfaceOrientationPortrait;
}

- (NSInteger)numberOfDownloads
{
	return downloads.count;
}

- (void)close
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)downloadURL:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
	NSURLRequest *rq = [NSURLRequest requestWithURL:url];
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:rq delegate:self];

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:url forKey:kHCDownloadKeyURL];
	[dict setObject:conn forKey:kHCDownloadKeyConnection];
	if (userInfo != nil) {
		[dict setObject:userInfo forKey:kHCDownloadKeyUserInfo];
	}

	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:downloads.count inSection:0];
	[downloads addObject:dict];
	NSArray *paths = [NSArray arrayWithObject:indexPath];
	[self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationRight];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)cancelDownloadingURLAtIndex:(NSInteger)index;
{
	NSMutableDictionary *dict = [downloads objectAtIndex:index];
	NSDictionary *userInfo = [[dict objectForKey:kHCDownloadKeyUserInfo] retain];
	NSURL *url = [[dict objectForKey:kHCDownloadKeyUserInfo] retain];
	[self removeURLAtIndex:index];

	if ([self.delegate respondsToSelector:@selector(downloadController:failedDownloadingURL:withError:userInfo:)]) {
		NSError *error = [NSError errorWithDomain:kHCDownloadErrorDomain code:kHCDownloadErrorCodeCancelled userInfo:nil];
		[self.delegate downloadController:self failedDownloadingURL:url withError:error userInfo:userInfo];
	}

	[userInfo release];
	[url release];
}

- (void)removeURL:(NSURL *)url
{
	NSInteger index = -1;
	NSDictionary *d;
	for (d in downloads) {
		NSURL *otherUrl = [d objectForKey:kHCDownloadKeyURL];
		if ([otherUrl isEqual:url]) {
			index = [downloads indexOfObject:d];
			break;
		}
	}

	if (index != -1) {
		[self removeURLAtIndex:index];
	}
}

- (void)removeURLAtIndex:(NSInteger)index
{
	NSDictionary *dict = [downloads objectAtIndex:index];

	NSURLConnection *conn = [dict objectForKey:kHCDownloadKeyConnection];
	[conn cancel];

	NSFileHandle *fileHandle = [dict objectForKey:kHCDownloadKeyFileHandle];
	[fileHandle closeFile];

	[downloads removeObjectAtIndex:index];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	NSArray *paths = [NSArray arrayWithObject:indexPath];
	[self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationRight];
	
	if (downloads.count == 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

- (void)setupCell:(HCDownloadCell *)cell withAttributes:(NSDictionary *)dict
{
	NSDictionary *userInfo = [dict objectForKey:kHCDownloadKeyUserInfo];
	NSString *title =  [userInfo objectForKey:kHCDownloadKeyTitle];
	if (title == nil) title = [dict objectForKey:kHCDownloadKeyFileName];
	if (title == nil) title = NSLocalizedString(@"Downloading...", nil);
	cell.textLabel.text = title;
	cell.imageView.image = [userInfo objectForKey:kHCDownloadKeyImage];

	// Calculate the progress
	NSFileHandle *fileHandle = [dict objectForKey:kHCDownloadKeyFileHandle];
	if (fileHandle != nil) {
		unsigned long long downloaded = [fileHandle offsetInFile];
		NSDate *startTime = [dict objectForKey:kHCDownloadKeyStartTime];
		unsigned long long total = [[dict objectForKey:kHCDownloadKeyTotalSize] unsignedLongLongValue];

		NSTimeInterval dt = -1 * [startTime timeIntervalSinceNow];
		float speed = downloaded / dt;
		unsigned long long remaining = total - downloaded;
		int remainingTime = (int)(remaining / speed);
		int hours = remainingTime / 3600;
		int minutes = (remainingTime - hours * 3600) / 60;
		int seconds = remainingTime - hours * 3600 - minutes * 60;

		float downloadedF, totalF;
		char prefix;
		if (total >= 1024 * 1024 * 1024) {
			downloadedF = (float)downloaded / (1024 * 1024 * 1024);
			totalF = (float)total / (1024 * 1024 * 1024);
			prefix = 'G';
		} else if (total >= 1024 * 1024) {
			downloadedF = (float)downloaded / (1024 * 1024);
			totalF = (float)total / (1024 * 1024);
			prefix = 'M';
		} else if (total >= 1024) {
			downloadedF = (float)downloaded / 1024;
			totalF = (float)total / 1024;
			prefix = 'k';
		} else {
			downloadedF = (float)downloaded;
			totalF = (float)total;
			prefix = '\0';
		}

		// float speedNorm = downloadedF / dt;
		NSString *subtitle = [[NSString alloc] initWithFormat:@"%.2f of %.2f %cB, %02d:%02d:%02d remaining\n \n",
			downloadedF, totalF, prefix, hours, minutes, seconds];
		cell.detailTextLabel.text = subtitle;
		cell.progress = downloadedF / totalF;
		[subtitle release];
	} else {
		cell.detailTextLabel.text = nil;
	}
}

// UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return downloads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	HCDownloadCell *cell = (HCDownloadCell *)[tableView dequeueReusableCellWithIdentifier:kHCDownloadCellID];
	if (cell == nil) {
		cell = [HCDownloadCell cell];
	}

	NSMutableDictionary *dict = [downloads objectAtIndex:indexPath.row];
	[self setupCell:cell withAttributes:dict];

	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.imageView.layer.cornerRadius = 7.5f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kHCDownloadCellHeight;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Handle delete action initiated by the user
	if (style == UITableViewCellEditingStyleDelete) {
		if (indexPath.section == 0) {
			[self cancelDownloadingURLAtIndex:indexPath.row];
		}
	}
}

// NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)resp
{
	// Search for the connection in all downloads
	NSMutableDictionary *dict;
	for (dict in downloads) {
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn]) { // found the connection
			// If no default filename is provided, use the suggested one
			NSDictionary *userInfo = [dict objectForKey:kHCDownloadKeyUserInfo];
			NSString *fileName = [userInfo objectForKey:kHCDownloadKeyFileName];
			if (fileName == nil) {
				fileName = [resp suggestedFilename];
			}
			
			// Create the file to be written
			NSString *path = [self.downloadDirectory stringByAppendingPathComponent:fileName];
			[[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
			NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
			[dict setObject:fileName forKey:kHCDownloadKeyFileName];
			[dict setObject:fileHandle forKey:kHCDownloadKeyFileHandle];

			long long length = [resp expectedContentLength];
			if (length != NSURLResponseUnknownLength) {
				NSNumber *totalSize = [NSNumber numberWithUnsignedLongLong:(unsigned long long)length];
				[dict setObject:totalSize forKey:kHCDownloadKeyTotalSize];
			}

			// Set the start time in order to be able to calculate
			// an approximate remaining time
			[dict setObject:[NSDate date] forKey:kHCDownloadKeyStartTime];

			// Notify the delegate
			if ([self.delegate respondsToSelector:@selector(downloadController:startedDownloadingURL:userInfo:)]) {
				NSURL *url = [dict objectForKey:kHCDownloadKeyURL];
				[self.delegate downloadController:self startedDownloadingURL:url userInfo:userInfo];
			}

			// Refresh the table view
			[self.tableView reloadData];
			break;
		}
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	NSMutableDictionary *dict;
	for (dict in downloads) {
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn]) {
			NSFileHandle *fileHandle = [dict objectForKey:kHCDownloadKeyFileHandle];
			[fileHandle writeData:data];
		
			// Update the corresponding table view cell
			NSInteger row = [downloads indexOfObject:dict];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
			HCDownloadCell *cell = (HCDownloadCell *)[self.tableView cellForRowAtIndexPath:indexPath];
			
			[self setupCell:cell withAttributes:dict];
			
			// Notify the delegate
			if ([self.delegate respondsToSelector:@selector(downloadController:dowloadedFromURL:progress:userInfo:)]) {
				NSURL *url = [dict objectForKey:kHCDownloadKeyURL];
				NSDictionary *userInfo = [dict objectForKey:kHCDownloadKeyUserInfo];
				unsigned long long totalSize = [(NSNumber *)[dict objectForKey:kHCDownloadKeyTotalSize] unsignedLongLongValue];
				unsigned long long downloadSize = [fileHandle offsetInFile];
				float progress = (float)downloadSize / totalSize;
				[self.delegate downloadController:self dowloadedFromURL:url progress:progress userInfo:userInfo];
			}
			break;
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	NSInteger index = -1;
	NSMutableDictionary *d = nil;
	NSMutableDictionary *dict;
	
	// Search for the download context dictionary
	for (dict in downloads) {
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn]) {
			d = [dict retain];
			index = [downloads indexOfObject:dict];
			break;
		}
	}

	// Clen up
	if (index != -1) {
		[self removeURLAtIndex:index];
		if ([self.delegate respondsToSelector:@selector(downloadController:finishedDownloadingURL:toFile:userInfo:)]) {
			NSString *fileName = [d objectForKey:kHCDownloadKeyFileName];
			NSURL *url = [d objectForKey:kHCDownloadKeyURL];
			NSDictionary *userInfo = [d objectForKey:kHCDownloadKeyUserInfo];
			[self.delegate downloadController:self finishedDownloadingURL:url toFile:fileName userInfo:userInfo];
		}
	}

	[d release];
}

- (void)connection:(NSURLConnection *)conn didFailLoadWithError:(NSError *)error
{
	NSInteger index = -1;
	NSMutableDictionary *d = nil;
	NSMutableDictionary *dict;
	
	// Search for the download context dictionary
	for (dict in downloads) {
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn]) {
			d = [dict retain];
			index = [downloads indexOfObject:dict];
			break;
		}
	}

	// Clean up
	if (index != -1) {
		[self removeURLAtIndex:index];
		NSURL *url = [[d objectForKey:kHCDownloadKeyURL] retain];
		NSDictionary *userInfo = [d objectForKey:kHCDownloadKeyUserInfo];

		if ([self.delegate respondsToSelector:@selector(downloadController:failedDownloadingURL:withError:userInfo:)]) {
			[self.delegate downloadController:self failedDownloadingURL:url withError:error userInfo:userInfo];
		}
	}

	[d release];
}

@end
