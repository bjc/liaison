/* LoadPanelController */

@interface LoadPanelController : NSObject
{
    IBOutlet NSTextField *thePathField, *theStatusField;
    IBOutlet NSProgressIndicator *theProgressBar;
    IBOutlet NSPanel *theLoadPanel;

    NSModalSession modalSession;

    BOOL isShowing;
}
- (void)show;
- (void)hide;

- (void)setStatus: (NSString *)aStatusMsg;
- (void)setPath: (NSString *)aPath;
- (void)setProgress: (double)aProgress;
- (void)setIndeterminantProgress: (BOOL)isIndeterminante;
- (void)update;
@property BOOL isShowing;
@property (retain) NSPanel *theLoadPanel;
@property (retain) NSProgressIndicator *theProgressBar;
@property NSModalSession modalSession;
@end
