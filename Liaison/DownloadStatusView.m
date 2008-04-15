#import "DownloadStatusView.h"

@implementation DownloadStatusView (NSCoding)
- (id)initWithCoder: (NSCoder *)aCoder
{
    self = [super initWithCoder: aCoder];

    if ([aCoder allowsKeyedCoding]) {
        theFilename = [aCoder decodeObjectForKey: @"filename"];
        theIcon = [aCoder decodeObjectForKey: @"icon"];
        theProgressBar = [aCoder decodeObjectForKey: @"progressBar"];
        theButton = [aCoder decodeObjectForKey: @"button"];
    } else {
        theFilename = [aCoder decodeObject];
        theIcon = [aCoder decodeObject];
        theProgressBar = [aCoder decodeObject];
        theButton = [aCoder decodeObject];
    }

    [theFilename retain];
    [theIcon retain];
    [theProgressBar retain];
    [theButton retain];

    return self;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject: theFilename forKey: @"filename"];
        [aCoder encodeObject: theIcon forKey: @"icon"];
        [aCoder encodeObject: theProgressBar forKey: @"progressBar"];
        [aCoder encodeObject: theButton forKey: @"button"];
    } else {
        [aCoder encodeObject: theFilename];
        [aCoder encodeObject: theIcon];
        [aCoder encodeObject: theProgressBar];
        [aCoder encodeObject: theButton];
    }
    [super encodeWithCoder: aCoder];
}
@end

@implementation DownloadStatusView (NSViewSubclass)
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect: rect];
}
@end

@implementation DownloadStatusView
- (void)dealloc
{
    [self setFileHandle: nil];

    [super dealloc];
}

- (LiFileHandle *)fileHandle
{
    return theFileHandle;
}

- (void)setFileHandle: (LiFileHandle *)aFileHandle
{
    [aFileHandle retain];
    [theFileHandle release];
    theFileHandle = aFileHandle;
}

- (void)setIcon: (NSImage *)anIcon
{
    [theIcon setImage: anIcon];
}

- (void)setFilename: (NSString *)aFilename
{
    [theFilename setStringValue: aFilename];
}

- (void)setProgress: (double)aProgress
{
    [theProgressBar setDoubleValue: aProgress];
}

- (void)setButtonImage: (NSImage *)anImage
{
    [theButton setImage: anImage];
}

- (void)setButtonAltImage: (NSImage *)anImage
{
    [theButton setAlternateImage: anImage];
}

- (void)setButtonTarget: (id)aTarget
{
    [theButton setTarget: aTarget];
}

- (void)setButtonAction: (SEL)anAction
{
    [theButton setAction: anAction];
}
@synthesize theFileHandle;
@synthesize theButton;
@synthesize theProgressBar;
@synthesize theIcon;
@synthesize theFilename;
@end
