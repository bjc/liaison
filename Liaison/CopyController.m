#import "CopyController.h"

#import "DownloadStatusView.h"

@implementation CopyController
- (id)init
{
    self = [super init];

    theDownloads = [[NSMutableDictionary alloc] init];
    theWindowIsShowing = NO;
    
    return self;
}

- (void)dealloc
{
    [theDownloads release];

    [super dealloc];
}

- (void)awakeFromNib
{
    [theContentBox setFrame: NSMakeRect(0.0, 0.0, 0.0, 0.0)];
}

- (BOOL)windowShouldClose:(id)sender
{
    theWindowIsShowing = NO;
    
    return YES;
}

- (NSRect)windowWillUseStandardFrame: (NSWindow *)aWindow
                        defaultFrame: (NSRect)defaultFrame
{
    NSRect stdFrame;
    NSSize smallSize, boxSize;
    
    defaultFrame.origin.y += 64;
    defaultFrame.size.height -= 64;

    stdFrame = [NSWindow contentRectForFrameRect: [aWindow frame]
                                       styleMask: [aWindow styleMask]];
    
    boxSize = [theContentBox bounds].size;
    smallSize.width = MIN(defaultFrame.size.width, boxSize.width);
    smallSize.height = MIN(defaultFrame.size.height, boxSize.height);

    // XXX
    stdFrame.size.height = MAX(smallSize.height, 100.0);
    stdFrame.size.width = MAX(smallSize.width, 220.0);
    stdFrame = [NSWindow frameRectForContentRect: stdFrame
                                       styleMask: [aWindow styleMask]];   

    return stdFrame;
}

- (void)showWindow
{
    if (theWindowIsShowing == NO) {
        [theWindow makeKeyAndOrderFront: self];
        theWindowIsShowing = YES;
    }
}

- (void)hideWindow
{
    if (theWindowIsShowing) {
        [theWindow close];
        theWindowIsShowing = NO;
    }
}

- (void)addDownloadView: (NSView *)aView
{
    NSRect viewFrame;
    NSSize contentSize, viewSize, boxSize;

    viewSize = [aView bounds].size;
    boxSize = [theContentBox bounds].size;
    contentSize.width = MAX(viewSize.width, boxSize.width);
    contentSize.height = boxSize.height + viewSize.height;
    [theContentBox setFrameSize: contentSize];

    viewFrame.size = viewSize;
    viewFrame.origin = NSMakePoint(0.0, boxSize.height);
    [aView setFrame: viewFrame];

    [[theScrollView contentView] addSubview: aView];
    //viewFrame.origin.y *= -1;
    [aView scrollRectToVisible: viewFrame];
}

- (DownloadStatusView *)newDownloadView
{
    DownloadStatusView *tmpView;
    NSData *viewData;

    viewData = [NSKeyedArchiver archivedDataWithRootObject: theTemplate];
    tmpView = [NSKeyedUnarchiver unarchiveObjectWithData: viewData];

    return tmpView;
}

- (DownloadStatusView *)statusViewForFileHandle: (LiFileHandle *)aFile;
{
    NSString *viewKey;
    DownloadStatusView *downloadView;

    viewKey = [NSString stringWithFormat: @"%@:%@", [aFile storeID], [aFile fileID]];
    
    downloadView = [theDownloads objectForKey: viewKey];
    if (downloadView == nil) {
        downloadView = [self newDownloadView];
        [downloadView setFileHandle: aFile];

        [theDownloads setObject: downloadView forKey: viewKey];

        [self addDownloadView: downloadView];
    }

    [self showWindow];
    return downloadView;
}
@synthesize theTemplate;
@synthesize theWindowIsShowing;
@synthesize theScrollView;
@synthesize theContentBox;
@synthesize theWindow;
@synthesize theDownloads;
@end
