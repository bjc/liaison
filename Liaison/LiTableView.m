#import "LiTableView.h"

@implementation LiTableView
+ (void)load
{
    [self poseAsClass: [NSTableView class]];
}

- methodSignatureForSelector: (SEL)aSelector
{
    id signature;

    signature = [super methodSignatureForSelector: aSelector];
    if (signature == nil) {
        NSString *selString;

        selString = NSStringFromSelector(aSelector);

        if ([selString isEqualToString: @"validateMenuItem:"]) {
            signature = [[self delegate] methodSignatureForSelector: @selector(validateMenuItem:)];
        } else if ([selString isEqualToString: @"delete:"]) {
            if ([self isKindOfClass: [NSOutlineView class]])
                signature = [[self dataSource] methodSignatureForSelector: @selector(deleteSelectedRowsInOutlineView:)];
            else
                signature = [[self dataSource] methodSignatureForSelector:
                    @selector(deleteSelectedRowsInTableView:)];
        } else if ([[self delegate] respondsToSelector: aSelector])
            signature = [[self delegate] methodSignatureForSelector: aSelector];
    }
    return signature;
}

- (void)forwardInvocation: (NSInvocation *)anInvocation
{
    NSString *selString;

    selString = NSStringFromSelector([anInvocation selector]);
    if ([selString isEqualToString: @"validateMenuItem:"]) {
        [anInvocation setTarget: [self delegate]];
        [anInvocation invoke];
    } else if ([selString isEqualToString: @"delete:"]) {
        [anInvocation setTarget: [self dataSource]];
        if ([self isKindOfClass: [NSOutlineView class]]) {
            [anInvocation setSelector: @selector(deleteSelectedRowsInOutlineView:)];
        } else {
            [anInvocation setSelector: @selector(deleteSelectedRowsInTableView:)];
        }
        
        [anInvocation setArgument: &self atIndex: 2];
        [anInvocation invoke];
    } else if ([[self delegate] respondsToSelector: [anInvocation selector]]) {
        [anInvocation setTarget: [self delegate]];
        [anInvocation invoke];
    } else
        [super forwardInvocation: anInvocation];
}

- (BOOL)respondsToSelector: (SEL)aSelector
{
    NSString *selString;
    
    if ([super respondsToSelector: aSelector])
        return YES;

    selString = NSStringFromSelector(aSelector);
    if ([selString isEqualToString: @"validateMenuItem:"]) {
        return [[self delegate] respondsToSelector: aSelector];
    } else if ([selString isEqualToString: @"delete:"]) {
        if ([self isKindOfClass: [NSOutlineView class]]) {
            return [[self dataSource] respondsToSelector:
                @selector(deleteSelectedRowsInOutlineView:)];
        } else {
            return [[self dataSource] respondsToSelector: @selector(deleteSelectedRowsInTableView:)];
        }        
    }
    return [[self delegate] respondsToSelector: aSelector];
}

- (void)keyDown: (NSEvent *)theEvent
{
    NSString *keyString;
    unichar keyChar;

    keyString = [theEvent charactersIgnoringModifiers];
    keyChar = [keyString characterAtIndex: 0];
    switch (keyChar) {
        case 0177: // Delete Key
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey: {
            SEL selector;

            if ([self isKindOfClass: [NSOutlineView class]]) {
                selector = @selector(deleteSelectedRowsInOutlineView:);
            } else {
                selector = @selector(deleteSelectedRowsInTableView:);
            }
            if ([self selectedRow] >= 0 &&
                [[self dataSource] respondsToSelector: selector]) {
                [[self dataSource] performSelector: selector
                                        withObject: self];
            }
            break;
        } default:
            [super keyDown: theEvent];
    }
}

- (BOOL)becomeFirstResponder
{
    BOOL rc;

    rc = [super becomeFirstResponder];
    if (rc == YES) {
        SEL selector;

        if ([self isKindOfClass: [NSOutlineView class]])
            selector = @selector(outlineViewDidBecomeFirstResponder:);
        else
            selector = @selector(tableViewDidBecomeFirstResponder:);
        
        if ([[self delegate] respondsToSelector: selector])
            [[self delegate] performSelector: selector
                                  withObject: self];
    }
    return rc;
}

- (void)mouseDown: (NSEvent *)theEvent
{
    if ([[self delegate] respondsToSelector: @selector(mouseDownEvent:)])
        [[self delegate] performSelector: @selector(mouseDownEvent:)
                              withObject: theEvent];
    [super mouseDown: theEvent];
}

- (unsigned int)draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
    if (isLocal)
        return NSDragOperationPrivate;
    else
        return NSDragOperationCopy | NSDragOperationLink | NSDragOperationGeneric;
}

- (void)textDidEndEditing: (NSNotification *)aNotification
{
    int keyPressed;

    keyPressed = [[[aNotification userInfo] objectForKey: @"NSTextMovement"] intValue];
    if (keyPressed == NSReturnTextMovement) {
        NSMutableDictionary *newUserInfo;
        NSNotification *newNotification;

        newUserInfo = [NSMutableDictionary dictionaryWithDictionary:
            [aNotification userInfo]];
        [newUserInfo setObject: [NSNumber numberWithInt:0]
                        forKey: @"NSTextMovement"];
        newNotification = [NSNotification notificationWithName: [aNotification name]
                                                        object: [aNotification object]
                                                      userInfo: newUserInfo];
        [super textDidEndEditing: newNotification];
        
        [[self window] makeFirstResponder: self];
    } else
        [super textDidEndEditing: aNotification];
}
@end