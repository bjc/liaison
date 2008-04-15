#import "LoadPanelController.h"

@implementation LoadPanelController
- (id)init
{
    self = [super init];

    isShowing = NO;
    
    return self;
}

- (void)sheetDidEnd: (NSWindow *)sheet
         returnCode: (int)returnCode
        contextInfo: (void  *)contextInfo
{
    [sheet close];
}

- (void)show
{
    if (isShowing == NO) {
        [NSApp beginSheet: theLoadPanel
           modalForWindow: [NSApp mainWindow]
            modalDelegate: self
           didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo: nil];
        modalSession = [NSApp beginModalSessionForWindow: theLoadPanel];
        isShowing = YES;
    }
}

- (void)hide
{
    if (isShowing) {
        [NSApp endModalSession: modalSession];
        [NSApp endSheet: theLoadPanel];
        isShowing = NO;
    }
}

- (void)setStatus: (NSString *)aStatusMsg
{
    [theStatusField setStringValue: aStatusMsg];
}

- (void)setPath: (NSString *)aPath
{
    [thePathField setStringValue: aPath];
}

- (void)setProgress: (double)aProgress
{
    [theProgressBar setDoubleValue: aProgress];
}

- (void)setIndeterminantProgress: (BOOL)isIndeterminante
{
    [theProgressBar setIndeterminate: isIndeterminante];
}

- (void)update
{
    if (isShowing) {
        if ([theProgressBar isIndeterminate])
            [theProgressBar animate: self];
        [NSApp runModalSession: modalSession];
    }
}
@synthesize modalSession;
@synthesize isShowing;
@synthesize theProgressBar;
@synthesize theLoadPanel;
@end
