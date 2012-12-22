/*
 * HCDownloadCell.m
 * HCDownload
 *
 * Created by Árpád Goretity on 25/07/2012.
 * Licensed under the 3-clause BSD License
 */

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "HCDownloadCell.h"

#define kHCDownloadCellProgressViewHeight (15.0f)

@implementation HCDownloadCell

+ (id)cell
{
	return [[[self alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kHCDownloadCellID] autorelease];
}

- (id)initWithStyle:(UITableViewCellStyle)s reuseIdentifier:(NSString *)ruid
{
	if ((self = [super initWithStyle:s reuseIdentifier:ruid])) {
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.font = [UIFont boldSystemFontOfSize:12.0f];

		self.detailTextLabel.backgroundColor = [UIColor clearColor];
		self.detailTextLabel.font = [UIFont systemFontOfSize:10.0f];
		self.detailTextLabel.numberOfLines = 3;

		progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
		progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:progressView]; 
	}
	return self;
}

- (void)dealloc
{
	[progressView release];
	[super dealloc];
}

- (void)willMoveToSuperview:(UIView *)superview
{
	CGRect frm = self.contentView.bounds;
	self.imageView.layer.cornerRadius = 7.5f;
	frm.size.width = frm.size.width - (self.imageView.frame.size.width + 20.0f);
	frm.size.height = kHCDownloadCellProgressViewHeight;
	frm.origin.x = self.imageView.frame.size.width + 10.0f;
	frm.origin.y = kHCDownloadCellHeight - kHCDownloadCellProgressViewHeight;
	progressView.frame = frm;
}

- (float)progress
{
	return progressView.progress;
}

- (void)setProgress:(float)p
{
	progressView.progress = p;
}

@end
