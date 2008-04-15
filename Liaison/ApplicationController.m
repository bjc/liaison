#import "ApplicationController.h"

#import "FileTableDelegate.h"
#import "Group.h"
#import "GroupTableDelegate.h"
#import "NIBConnector.h"
#import "PluginManager.h"
#import "RenManager.h"
#import "WindowController.h"

@implementation ApplicationController
// Set in awakeFromNib.
static ApplicationController *theApp = nil;

+ (ApplicationController *)theApp;
{
    return theApp;
}

- (void)awakeFromNib
{
    theApp = self;
}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    RenManager *renManager;
    NSArray *fileStorePlugins;
    NSString *libraryPath;
    id <LiFileStorePlugin>plugin;

    // Make sure the library exists.
    libraryPath = [[[Preferences sharedPreferences] libraryPath] stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath: libraryPath
                                               attributes: nil];

    // Load the plugins.
    fileStorePlugins = [[PluginManager defaultManager] fileStorePlugins];
    plugin = [fileStorePlugins objectAtIndex: 0]; // XXX
    [plugin initFileStore];
    
    renManager = [RenManager sharedManager];
    [renManager setFileStore: [plugin fileStore]];
    [renManager startup];
}

- (BOOL)application: (NSApplication *)anApp openFile: (NSString *)aPath
{
    [[NSWorkspace sharedWorkspace] openFile: aPath];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL fileURLWithPath: aPath]];
    return YES;
}

- (IBAction)openHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString: @"http://www.kublai.com/~shmit/software/Liaison/"]];
}


- (IBAction)showInspectorWindow:(id)sender
{
    [inspectorWindow makeKeyAndOrderFront: self];
}

- (IBAction)showMainWindow:(id)sender
{
    [mainWindow makeKeyAndOrderFront: self];
}
@synthesize theFileStore;
@synthesize inspectorWindow;
@synthesize mainWindow;
@end

@implementation ApplicationController (AppleScript)
- (BOOL)application: (NSApplication *)anApp
 delegateHandlesKey: (NSString *)aKey
{
    [LiLog logAsDebug: @"[ApplicationController application:delegateHandlesKey: %@", aKey];
    if ([aKey isEqualToString: @"orderedFileStores"])
        return YES;
    return NO;
}

- (NSArray *)orderedFileStores
{
    [LiLog logAsDebug: @"[ApplicationController orderedFileStores]"];
    return [LiFileStore allFileStores];
}
@end