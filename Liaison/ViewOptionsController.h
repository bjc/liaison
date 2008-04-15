/* ViewOptionsController */

@class FileTableDelegate;

@interface ViewOptionsController : NSObject
{
    NSMatrix *layoutMatrix;

    IBOutlet FileTableDelegate *theFileDelegate;
    IBOutlet id theHeaderField;
    IBOutlet id theContentView;
    IBOutlet NSWindow *theWindow;

    NSMutableArray *theShownColumns;
}

- (IBAction)showWindow: (id)sender;
@property (retain) id theHeaderField;
@property (retain) FileTableDelegate *theFileDelegate;
@property (retain) NSWindow *theWindow;
@property (retain) NSMatrix *layoutMatrix;
@property (retain) id theContentView;
@property (retain) NSMutableArray *theShownColumns;
@end
