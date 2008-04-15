#import "PreferencesController.h"

#import "RenManager.h"

@implementation PreferencesController (ToolbarDelegate)
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        @"Network",
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        @"Network",
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item;

    item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
    if ([itemIdentifier isEqualToString: @"Network"]) {
        [item setLabel: @"Network"];
        [item setPaletteLabel: @"Network"];
        [item setToolTip: @"Open network preferences."];
        [item setImage: [NSImage imageNamed: @"Network (Large).tiff"]];
        [item setTarget: self];
        [item setAction: @selector(revealNetworkPane:)];
    }

    return item;
}

- (BOOL)validateToolbarItem: (NSToolbarItem *)theItem
{
    return YES;
}
@end

@implementation PreferencesController
- (void)setupToolbar
{
    NSToolbar *toolbar;

    toolbar = [[[NSToolbar alloc]
             initWithIdentifier: @"prefsToolbar"] autorelease];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [theWindow setToolbar: toolbar];
}

- (void)awakeFromNib
{
    // We don't need this yet, but leave the stubs.
    //[self setupToolbar];
}
    
- (IBAction)applyChanges:(id)sender
{
    Preferences *prefs;
    
    prefs = [Preferences sharedPreferences];

    [prefs setDownloadDirectory: [theDownloadField stringValue]];

    if ([[prefs hostname] isEqualToString:
        [theHostnameField stringValue]] == NO) {
        [prefs setHostname: [theHostnameField stringValue]];
        [[RenManager sharedManager] updateHostname];
    }
    
    if ([theNetworkEnabledButton state] == 1 &&
        [prefs networkEnabled] == NO) {
        [prefs setNetworkEnabled: YES];
        [[RenManager sharedManager] startSharing];
    } else if ([theNetworkEnabledButton state] == 0 &&
               [prefs networkEnabled] == YES) {
        [prefs setNetworkEnabled: NO];
        [[RenManager sharedManager] stopSharing];
    }

    [theWindow close];
}

- (IBAction)toggleNetworkEnabled:(id)sender
{
    if ([sender state] == 1) {
        [theHostnameFieldDescription setEnabled: YES];
        [theHostnameField setEnabled: YES];
    } else {
        [theHostnameFieldDescription setEnabled: NO];
        [theHostnameField setEnabled: NO];
    }
}

- (IBAction)selectDownloadDirectory:(id)sender
{
    NSOpenPanel *openPanel;

    openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle: @"Select Download Directory"];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];

    [openPanel beginSheetForDirectory: [theDownloadField stringValue]
                                 file: nil
                                types: nil
                       modalForWindow: theWindow
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: nil];
}

- (void)openPanelDidEnd: (NSOpenPanel *)aPanel
             returnCode: (int)rc
            contextInfo: (void *)someContext
{
    if (rc == NSCancelButton)
        return;

    [theDownloadField setStringValue: [[aPanel filenames] objectAtIndex: 0]];
}

- (void)showWindow
{
    Preferences *prefs;
    
    prefs = [Preferences sharedPreferences];
    [theDownloadField setStringValue: [prefs downloadDirectory]];
    [theHostnameField setStringValue: [prefs hostname]];
    [theNetworkEnabledButton setState:
          [prefs networkEnabled] ? 1 : 0];
    [self toggleNetworkEnabled: theNetworkEnabledButton];
    [theWindow makeKeyAndOrderFront: self];
}
@synthesize theWindow;
@synthesize theNetworkEnabledButton;
@synthesize theHostnameFieldDescription;
@synthesize theHostnameField;
@synthesize theDownloadField;
@end
