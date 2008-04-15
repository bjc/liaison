/*
	ImageAndTextCell.m
	Copyright (c) 2001-2002, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

        Subclass of NSTextFieldCell which can display text and an image simultaneously.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ImageAndTextCell.h"

#define LEADINGEDGE 2

@implementation ImageAndTextCell

- (void)dealloc
{
    [self setImage: nil];
    [super dealloc];
}

- copyWithZone: (NSZone *)zone
{
    ImageAndTextCell *cell;

    cell = (ImageAndTextCell *)[super copyWithZone: zone];
    [cell setImage: [self image]];
    return cell;
}

- (NSRect)imageFrameForCellFrame: (NSRect)cellFrame
{
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += LEADINGEDGE;
        imageFrame.origin.y +=
            ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame: (NSRect)aRect
               inView: (NSView *)controlView
               editor: (NSText *)textObj
             delegate: (id)anObject
                event: (NSEvent *)theEvent
{
    NSRect textFrame, imageFrame;

    NSDivideRect(aRect, &imageFrame, &textFrame,
                 LEADINGEDGE + [image size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor: textObj delegate: anObject event: theEvent];
}

- (void)selectWithFrame: (NSRect)aRect
                 inView: (NSView *)controlView
                 editor: (NSText *)textObj
               delegate: (id)anObject
                  start: (int)selStart
                 length: (int)selLength
{
    NSRect textFrame, imageFrame;

    NSDivideRect (aRect, &imageFrame, &textFrame, LEADINGEDGE + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    if (image != nil) {
        NSSize imageSize;
        NSRect imageFrame;

        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, LEADINGEDGE + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += LEADINGEDGE;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y +=
                ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y +=
                ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [image compositeToPoint: imageFrame.origin operation: NSCompositeSourceOver];
    }
    [super drawWithFrame: cellFrame inView: controlView];
}

- (NSSize)cellSize
{
    NSSize cellSize;

    cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + LEADINGEDGE;
    return cellSize;
}
@end

@implementation ImageAndTextCell (Accessors)
- (NSImage *)image
{
    return image;
}

- (void)setImage: (NSImage *)anImage
{
    [anImage retain];
    [image release];
    image = anImage;
}
@end