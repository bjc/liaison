/* PreferencesController */

@interface PreferencesController : NSObject
{
    IBOutlet NSWindow *theWindow;

    IBOutlet NSTextField *theDownloadField;
    IBOutlet NSTextField *theHostnameFieldDescription;
    IBOutlet NSTextField *theHostnameField;
    IBOutlet NSButton *theNetworkEnabledButton;
}
- (IBAction)applyChanges:(id)sender;
- (IBAction)selectDownloadDirectory:(id)sender;
- (IBAction)toggleNetworkEnabled:(id)sender;

- (void)showWindow;
@property (retain) NSWindow *theWindow;
@property (retain) NSButton *theNetworkEnabledButton;
@property (retain) NSTextField *theHostnameFieldDescription;
@property (retain) NSTextField *theDownloadField;
@property (retain) NSTextField *theHostnameField;
@end
