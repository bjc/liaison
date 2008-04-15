/* WindowController */

@interface WindowController : NSObject
{
    IBOutlet NSTableView *theFileList;
    IBOutlet NSOutlineView *theGroupList;
    IBOutlet NSWindow *theInspectorWindow;
    IBOutlet NSWindow *theMainWindow;

    IBOutlet id theSearchField;
}
@property (retain) id theSearchField;
@property (retain) NSTableView *theFileList;
@property (retain) NSWindow *theMainWindow;
@property (retain) NSWindow *theInspectorWindow;
@property (retain) NSOutlineView *theGroupList;
@end