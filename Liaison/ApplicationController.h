/* ApplicationController */

@protocol LiFileStoreDelegate;

@interface ApplicationController : NSObject
{
    IBOutlet NSWindow *inspectorWindow;
    IBOutlet NSWindow *mainWindow;

    LiFileStore *theFileStore;
}
+ (ApplicationController *)theApp;

- (IBAction)openHomepage:(id)sender;

- (IBAction)showInspectorWindow:(id)sender;
- (IBAction)showMainWindow:(id)sender;
@property (retain) NSWindow *mainWindow;
@property (retain) NSWindow *inspectorWindow;
@property (retain) LiFileStore *theFileStore;
@end