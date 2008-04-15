/* InspectorController */

@class LiInspectorView;

@interface InspectorController : NSObject
{
    IBOutlet NSTabView *theTabView;
    IBOutlet NSView *theDefaultTabView;
    IBOutlet NSWindow *theWindow;

    NSMutableDictionary *theInspectorViews;
    LiFileHandle *theFile;
}
- (LiInspectorView *)inspectorViewForIdentifier: (NSString *)anIdentifier;
- (NSRect)minWindowFrame;
- (void)resizeWindow;

- (void)setFile: (LiFileHandle *)aFile;
@property (retain) LiFileHandle *theFile;
@property (retain) NSWindow *theWindow;
@property (retain) NSMutableDictionary *theInspectorViews;
@property (retain) NSTabView *theTabView;
@property (retain) NSView *theDefaultTabView;
@end
