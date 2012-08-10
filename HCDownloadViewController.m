/**
 * HCDownloadViewController.m
 * HCDownload
 *
 * Created by Árpád Goretity on 25/07/2012.
 * Licensed under the 3-clause BSD License
 */

#import <QuartzCore/QuartzCore.h>
#import "HCDownloadViewController.h"

#define kHCDownloadKeyURL @"URL"
#define kHCDownloadKeyStartTime @"startTime"
#define kHCDownloadKeyTotalSize @"totalSize"
#define kHCDownloadKeyConnection @"connection"
#define kHCDownloadKeyFileName @"fileName"
#define kHCDownloadKeyFileHandle @"fileHandle"
#define kHCDownloadKeyUserInfo @"userInfo"

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
	if ((self = [super initWithStyle:style]))
	{
		downloads = [[NSMutableArray alloc] init];
		self.downloadDirectory = @"/var/mobile/Downloads";
		self.title = NSLocalizedString(@"Downloads", nil);
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)] autorelease];
	}
	return self;
}

- (void)dealloc
{
	[self.tableView beginUpdates];
	while (downloads.count > 0)
		[self removeURLAtIndex:0];

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
	if (userInfo != nil)
		[dict setObject:userInfo forKey:kHCDownloadKeyUserInfo];

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

	if ([self.delegate respondsToSelector:@selector(downloadController:failedDownloadingURL:withError:userInfo:)])
	{
		NSError *error = [NSError errorWithDomain:kHCDownloadErrorDomain code:kHCDownloadErrorCodeCancelled userInfo:nil];
		[self.delegate downloadController:self failedDownloadingURL:url withError:error userInfo:userInfo];
	}

	[userInfo release];
	[url release];
}

- (void)removeURL:(NSURL *)url
{
	NSInteger index = -1;
	for (NSDictionary *d in downloads)
	{
		NSURL *otherUrl = [d objectForKey:kHCDownloadKeyURL];
		if ([otherUrl isEqual:url])
		{
			index = [downloads indexOfObject:d];
			break;
		}
	}

	if (index != -1)
		[self removeURLAtIndex:index];
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
	
	if (downloads.count == 0)
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)setupCell:(HCDownloadCell *)cell withAttributes:(NSDictionary *)dict
{
	NSDictionary *userInfo = [dict objectForKey:kHCDownloadKeyUserInfo];
	NSString *title =  [userInfo objectForKey:kHCDownloadKeyTitle];
	if (title == nil) title = [dict objectForKey:kHCDownloadKeyFileName];
	if (title == nil) title = NSLocalizedString(@"Downloading...", nil);
	cell.textLabel.text = title;
	cell.imageView.image = [userInfo objectForKey:kHCDownloadKeyImage];
	cell.imageView.layer.cornerRadius = 7.5f;

	NSFileHandle *fileHandle = [dict objectForKey:kHCDownloadKeyFileHandle];
	if (fileHandle != nil)
	{
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
	}
	else
	{
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
	HCDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCDownloadCellID];
	if (cell == nil)
	{
		cell = [HCDownloadCell cell];
	}

	NSMutableDictionary *dict = [downloads objectAtIndex:indexPath.row];
	
	[self setupCell:cell withAttributes:dict];

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kHCDownloadCellHeight;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (style == UITableViewCellEditingStyleDelete)
		if (indexPath.section == 0)
			[self cancelDownloadingURLAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.imageView.layer.cornerRadius = 7.5f;
}

// NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)resp
{
	for (NSMutableDictionary *dict in downloads)
	{
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn])
		{
			NSString *fileName = [resp suggestedFilename];
			NSString *path = [self.downloadDirectory stringByAppendingPathComponent:fileName];
			[[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
			NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
			[dict setObject:fileName forKey:kHCDownloadKeyFileName];
			[dict setObject:fileHandle forKey:kHCDownloadKeyFileHandle];

			long long length = [resp expectedContentLength];
			if (length != NSURLResponseUnknownLength)
			{
				NSNumber *totalSize = [NSNumber numberWithUnsignedLongLong:(unsigned long long)length];
				[dict setObject:totalSize forKey:kHCDownloadKeyTotalSize];
			}

			[dict setObject:[NSDate date] forKey:kHCDownloadKeyStartTime];

			if ([self.delegate respondsToSelector:@selector(downloadController:startedDownloadingURL:userInfo:)])
			{
				NSURL *url = [dict objectForKey:kHCDownloadKeyURL];
				NSDictionary *userInfo = [dict objectForKey:kHCDownloadKeyUserInfo];
				[self.delegate downloadController:self startedDownloadingURL:url userInfo:userInfo];
			}

			[self.tableView reloadData];
			break;
		}
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{

	for (NSMutableDictionary *dict in downloads)
	{
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn])
		{
			NSFileHandle *fileHandle = [dict objectForKey:kHCDownloadKeyFileHandle];
			[fileHandle writeData:data];
		
			NSInteger row = [downloads indexOfObject:dict];
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
			HCDownloadCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
			
			[self setupCell:cell withAttributes:dict];
			break;
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	NSInteger index = -1;
	NSMutableDictionary *d = nil;
	for (NSMutableDictionary *dict in downloads)
	{
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn])
		{
			d = [dict retain];
			index = [downloads indexOfObject:dict];
			break;
		}
	}

	if (index != -1)
	{
		[self removeURLAtIndex:index];
		if ([self.delegate respondsToSelector:@selector(downloadController:finishedDownloadingURL:toFile:userInfo:)])
		{
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
	for (NSMutableDictionary *dict in downloads)
	{
		NSURLConnection *otherConn = [dict objectForKey:kHCDownloadKeyConnection];
		if ([otherConn isEqual:conn])
		{
			d = [dict retain];
			index = [downloads indexOfObject:dict];
			break;
		}
	}

	if (index != -1)
	{
		[self removeURLAtIndex:index];
		NSURL *url = [[d objectForKey:kHCDownloadKeyURL] retain];
		NSDictionary *userInfo = [d objectForKey:kHCDownloadKeyUserInfo];

		if ([self.delegate respondsToSelector:@selector(downloadController:failedDownloadingURL:withError:userInfo:)])
		{
			[self.delegate downloadController:self failedDownloadingURL:url withError:error userInfo:userInfo];
		}
	}

	[d release];
}

@end

