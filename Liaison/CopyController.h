/* CopyController */

@class DownloadStatusView;

@interface CopyController : NSObject
{
    IBOutlet NSWindow *theWindow;
    IBOutlet DownloadStatusView *theTemplate;
    IBOutlet NSBox *theContentBox;
    IBOutlet NSScrollView *theScrollView;

    BOOL theWindowIsShowing;
    
    NSMutableDictionary *theDownloads;
}

- (void)showWindow;
- (void)hideWindow;

- (DownloadStatusView *)statusViewForFileHandle: (LiFileHandle *)aFile;
@property (retain) NSScrollView *theScrollView;
@property (retain) DownloadStatusView *theTemplate;
@property (retain) NSBox *theContentBox;
@property (retain) NSWindow *theWindow;
@property BOOL theWindowIsShowing;
@property (retain) NSMutableDictionary *theDownloads;
@end
