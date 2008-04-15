//
//  ImageAndTextCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

@interface ImageAndTextCell : NSTextFieldCell
{
@private
    NSImage	*image;
}

- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView;
- (NSSize)cellSize;
@end

@interface ImageAndTextCell (Accessors)
- (NSImage *)image;
- (void)setImage: (NSImage *)anImage;
@end