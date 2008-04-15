/* DownloadStatusView */

@interface DownloadStatusView : NSView
{
    IBOutlet NSTextField *theFilename;
    IBOutlet NSImageView *theIcon;
    IBOutlet NSProgressIndicator *theProgressBar;
    IBOutlet NSButton *theButton;

    LiFileHandle *theFileHandle;
}
- (LiFileHandle *)fileHandle;
- (void)setFileHandle: (LiFileHandle *)aFileHandle;

- (void)setIcon: (NSImage *)anIcon;
- (void)setFilename: (NSString *)aFilename;
- (void)setProgress: (double)aProgress;
- (void)setButtonImage: (NSImage *)anImage;
- (void)setButtonAltImage: (NSImage *)anImage;
- (void)setButtonTarget: (id)aTarget;
- (void)setButtonAction: (SEL)anAction;
@property (retain,getter=fileHandle) LiFileHandle *theFileHandle;
@property (retain) NSTextField *theFilename;
@property (retain) NSButton *theButton;
@property (retain) NSImageView *theIcon;
@property (retain) NSProgressIndicator *theProgressBar;
@end
