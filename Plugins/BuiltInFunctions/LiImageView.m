#import "LiImageView.h"

@implementation LiImageView
- (NSArray *)namesOfPromisedFilesDroppedAtDestination: (NSURL *)dropDestination
{
    NSFileManager *defaultManager;
    NSString *imageDir, *path, *filename;
    int suffix;
    
    [LiLog logAsDebug: @"[LiImageView names..Desitination: %@]", dropDestination];

    imageDir = [dropDestination path];
    defaultManager = [NSFileManager defaultManager];
    for (suffix = 0; suffix < 100; suffix++) {
        filename = [NSString stringWithFormat: @"LiaisonIcon%02d.tiff", suffix];
        path = [imageDir stringByAppendingPathComponent: filename];
        if ([defaultManager fileExistsAtPath: path] == NO) {
            [LiLog logAsDebug: @"\tsaving to path: %@", path];
            break;
        }
    }

    if (suffix < 100) {
        if ([defaultManager createFileAtPath: path
                                    contents: [[self image] TIFFRepresentation]
                                  attributes: nil] == NO) {
            return nil;
        }
    } else
        return nil;

    return [NSArray arrayWithObject: filename];
}

- (void)mouseDown: (NSEvent *)theEvent
{
    NSPoint dragPosition;
    NSRect imageLocation;

    [[NSApp keyWindow] makeFirstResponder: self];
    
    dragPosition = [self convertPoint: [theEvent locationInWindow]
                             fromView: nil];
    dragPosition.x -= 16;
    dragPosition.y -= 16;
    imageLocation.origin = dragPosition;
    imageLocation.size = NSMakeSize(32,32);
    [self dragPromisedFilesOfTypes: [NSArray arrayWithObject: @"tiff"]
                          fromRect: imageLocation source: self
                         slideBack: YES event: theEvent];
}

- (void)mouseDragged: (NSEvent *)anEvent
{
    [LiLog logAsDebug: @"[LiImageView mouseDragged]"];

    [super mouseDragged: anEvent];
}
@end
