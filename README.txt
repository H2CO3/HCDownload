Usage:

    HCDownloadViewController *dlvc = [[HCDownloadViewController alloc] init];
    dlvc.downloadDirectory = @"/var/mobile/Library/Downloads";
    dlvc.delegate = self;
    [dlvc downloadURL:[NSURL URLWithString:@"http://megaupload.com/piratedSong.mp3"] userInfo:nil];

userInfo is an NSDictionary with arbitrary values, it can even be nil. However, some special keys are respected by the view controller:
kHCDownloadKeyTitle corresponds to an NSString which will be used as the title of the download in the table view
instead of the file name, and kHCDownloadKeyImage must correspond to an UIImage (if present) that will be displayed in the
left side of the table view cell. kHCDownloadKeyFileName shall specify an NSString (if any) that contains a valid filename,
to which the downloaded data is to be saved. If not present, the filename suggested by the server will be used.

To inspect the number of downloads currently in progress, use dlvc.numberOfDownloads.

To respond to download events, implement the optional delegate methods:

- (void)downloadController:(HCDownloadViewController *)vc startedDownloadingURL:(NSURL *)url userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc dowloadedFromURL:(NSURL *)url progress:(float)progress userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc finishedDownloadingURL:(NSURL *)url toFile:(NSString *)fileName userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc failedDownloadingURL:(NSURL *)url withError:(NSError *)error userInfo:(NSDictionary *)userInfo;

Enjoy!
