#import "WindowController.h"

#import "ApplicationController.h"
#import "FileTableDelegate.h"
#import "GroupTableDelegate.h"

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTable(aString, @"WindowElements", @"");
}

static void
logRect(NSString *desc, NSRect aRect)
{
    [LiLog logAsDebug: @"%@, (%f, %f, %f, %f)", desc, aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height];
}

@implementation WindowController (WindowDelegate)
- (NSRect)windowWillUseStandardFrame: (NSWindow *)aWindow
                        defaultFrame: (NSRect)defaultFrame
{
    FileTableDelegate *fileDelegate;
    GroupTableDelegate *groupDelegate;
    NSRect curGroupFrame, curFileFrame, windowFrame;
    NSSize minGroupSize, minFileSize;
    float newWidth, newHeight, splitterWidth, headerHeight;

    [LiLog logAsDebug: @"[WindowController minSize]"];
    [LiLog indentDebugLog];

    groupDelegate = [theGroupList delegate];
    fileDelegate = [theFileList delegate];

    windowFrame = [aWindow frame];
    logRect(@"Unadjusted window frame", windowFrame);

    windowFrame = [NSWindow contentRectForFrameRect: [aWindow frame]
                                          styleMask: [aWindow styleMask]];
    logRect(@"Old window frame", windowFrame);

    curFileFrame = [[theFileList superview] frame];
    logRect(@"curFileFrame", curFileFrame);
    curGroupFrame = [[theGroupList superview] frame];
    logRect(@"curGroupFrame", curGroupFrame);

    splitterWidth = windowFrame.size.width - (curFileFrame.size.width + curGroupFrame.size.width);
    [LiLog logAsDebug: @"splitter width: %f", splitterWidth];
    headerHeight = windowFrame.size.height - MAX(curFileFrame.size.height, curGroupFrame.size.height);
    [LiLog logAsDebug: @"header height: %f, wf.height: %f, MAX(file,group).height: %f", headerHeight, windowFrame.size.height, MAX(curFileFrame.size.height, curGroupFrame.size.height)];

    minGroupSize = [groupDelegate minSize];
    [LiLog logAsDebug: @"minGroupSize: %f, %f", minGroupSize.width, minGroupSize.height];
    minFileSize = [fileDelegate minSize];
    [LiLog logAsDebug: @"minFileSize: %f, %f", minFileSize.width, minFileSize.height];

    newWidth = minGroupSize.width + minFileSize.width + splitterWidth;
    newHeight = MAX(minGroupSize.height, minFileSize.height) + headerHeight + 6.0;
    
    [LiLog logAsDebug: @"newWidth, newHeight: %f, %f", newWidth, newHeight];

    windowFrame.origin.y += windowFrame.size.height;
    windowFrame.origin.y -= newHeight;
    windowFrame.size = NSMakeSize(newWidth, newHeight);
    windowFrame = [NSWindow frameRectForContentRect: windowFrame
                                          styleMask: [aWindow styleMask]];

    if ((windowFrame.origin.x + windowFrame.size.width) >
        (defaultFrame.origin.x + defaultFrame.size.width)) {
        [LiLog logAsDebug: @"Need to adjust width"];
        if (windowFrame.size.width > defaultFrame.size.width) {
            windowFrame.origin.x = defaultFrame.origin.x;
            windowFrame.size.width = defaultFrame.size.width;
        } else {
            windowFrame.origin.x = defaultFrame.size.width - windowFrame.size.width;
        }
    }
    if ((windowFrame.origin.y + windowFrame.size.height) >
        (defaultFrame.origin.y + defaultFrame.size.height)) {
        [LiLog logAsDebug: @"Need to adjust height"];
        if (windowFrame.size.height > defaultFrame.size.height) {
            windowFrame.origin.y = defaultFrame.origin.y;
            windowFrame.size.height = defaultFrame.size.height;
        } else {
            windowFrame.origin.y = defaultFrame.size.height - windowFrame.size.height;
        }
    }
    logRect(@"New window frame", windowFrame);

    [LiLog unindentDebugLog];
        
    return windowFrame;
}

- (void)windowDidBecomeKey: (NSNotification *)aNotificatin
{
    [LiLog logAsDebug: @"[WindowController windowDidBecomeKey]"];
    [[theMainWindow firstResponder] becomeFirstResponder];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    FileTableDelegate *fileDelegate;

    fileDelegate = [theFileList dataSource];
    [fileDelegate saveSelectionOfTableView: theFileList];
    [fileDelegate setSearchString:
        [[[[aNotification object] stringValue] lowercaseString] retain]];
    [fileDelegate redisplay];
    [fileDelegate restoreSelectionToTableView: theFileList refresh: YES];
}
@end

@implementation WindowController
- (id)init
{
    self = [super init];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setupToolbar
{
    NSToolbar *toolbar;

    toolbar = [[[NSToolbar alloc]
             initWithIdentifier: @"mainToolbar"] autorelease];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [theMainWindow setToolbar: toolbar];
}

- (void)awakeFromNib
{
    [self setupToolbar];
}
@synthesize theInspectorWindow;
@synthesize theGroupList;
@synthesize theFileList;
@synthesize theSearchField;
@synthesize theMainWindow;
@end

@implementation WindowController (ToolbarDelegateCategory)
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        @"AddFilesItem",
        @"RemoveFilesItem",
        @"SearchItem",
        @"InfoItem",
        @"AddGroupItem",
        @"RemoveGroupItem",
        @"RevealInFinderItem",
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        @"AddGroupItem",
        @"RemoveGroupItem",
        NSToolbarSeparatorItemIdentifier,
        @"AddFilesItem",
        @"RemoveFilesItem",
        @"InfoItem",
        @"RevealInFinderItem",
        NSToolbarFlexibleSpaceItemIdentifier,
        @"SearchItem",
        NSToolbarSeparatorItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:
        itemIdentifier];

    if ([itemIdentifier isEqualToString: @"AddFilesItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarAddFileLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarAddFilePaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarAddFileToolTip")];

        [item setImage: [NSImage imageNamed: @"AddFiles.tiff"]];
        [item setTarget: self];
        [item setAction: @selector(addToLibrary:)];
    } else if ([itemIdentifier isEqualToString: @"RemoveFilesItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarRemoveFileLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarRemoveFilePaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarRemoveFileToolTip")];

        [item setImage: [NSImage imageNamed: @"RemoveFiles.tiff"]];
        [item setTarget: self];
        [item setAction: @selector(removeFiles:)];
    } else if ([itemIdentifier isEqualToString: @"SearchItem"]) {
        NSRect frame;

        frame = [theSearchField frame];
        [item setLabel: myLocalizedString(@"LiToolbarSearchLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarSearchPaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarSearchToolTip")];

        [item setView: theSearchField];
        [item setMinSize: frame.size];
        [item setMaxSize: frame.size];
    } else if ([itemIdentifier isEqualToString: @"InfoItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarGetInfoLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarGetInfoPaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarGetInfoToolTip")];

        [item setImage: [NSImage imageNamed: @"info (italic).tiff"]];
        [item setTarget: self];
        [item setAction: @selector(openInspector:)];
    } else if ([itemIdentifier isEqualToString: @"AddGroupItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarAddGroupLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarAddGroupPaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarAddGroupToolTip")];

        [item setImage: [NSImage imageNamed: @"AddGroup.tiff"]];
        [item setTarget: self];
        [item setAction: @selector(addGroup:)];
    } else if ([itemIdentifier isEqualToString: @"RemoveGroupItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarRemoveGroupLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarRemoveGroupPaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarRemoveGroupToolTip")];

        [item setImage: [NSImage imageNamed: @"RemoveGroup.tiff"]];
        [item setTarget: self];
        [item setAction: @selector(removeGroup:)];
    } else if ([itemIdentifier isEqualToString: @"RevealInFinderItem"]) {
        [item setLabel: myLocalizedString(@"LiToolbarRevealLabel")];
        [item setPaletteLabel: myLocalizedString(@"LiToolbarRevealPaletteLabel")];
        [item setToolTip: myLocalizedString(@"LiToolbarRevealToolTip")];

        [item setImage: [NSImage imageNamed: @"reveal.tiff"]];
        [item setTarget: self];
        [item setAction: @selector(revealInFinder:)];
    }
    return [item autorelease];
}

- (BOOL)validateToolbarItem: (NSToolbarItem *)theItem
{
    GroupTableDelegate *groupDelegate;
    FileTableDelegate *fileDelegate;

    groupDelegate = [theGroupList delegate];
    fileDelegate = [theFileList delegate];
    if ([theItem action] == @selector(addToLibrary:)) {
        return [fileDelegate validateAction: @selector(addFiles:)];
    } else if ([theItem action] == @selector(revealInFinder:)) {
        return [fileDelegate validateAction: @selector(revealInFinder:)];
    } else if ([theItem action] == @selector(removeFiles:)) {
        return [fileDelegate validateAction: @selector(delete:)];
    } else if ([theItem action] == @selector(addGroup:)) {
        return [groupDelegate validateAction: @selector(addGroup:)];
    } else if ([theItem action] == @selector(removeGroup:)) {
        return [groupDelegate validateAction: @selector(delete:)];
    }

    return YES;
}

- (IBAction)addGroup:(id)sender
{
    [[theGroupList delegate] addGroup: self];
}

- (IBAction)removeGroup:(id)sender
{
    [theGroupList performSelector: @selector(delete:) withObject: sender];
}

- (IBAction)addToLibrary:(id)sender
{
    [[theFileList delegate] addFiles: self];
}

- (IBAction)removeFiles:(id)sender
{
    [theFileList performSelector: @selector(delete:) withObject: sender];
}

- (IBAction)openInspector:(id)sender
{
    [[ApplicationController theApp] showInspectorWindow: self];
}

- (IBAction)revealInFinder:(id)sender
{
    [[theFileList delegate] revealInFinder: self];
}
@end