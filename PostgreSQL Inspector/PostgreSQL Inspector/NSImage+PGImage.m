//
//  NSImage+PGImage.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/02/2013.
//
//

#import "NSImage+PGImage.h"

@implementation NSImage (PGImage)

-(NSImage *)imageScaledToSize:(NSSize)newSize proportionally:(BOOL)proportional
{
    NSImage *copy = [self copy];
    NSSize size = [copy size];
    
    if (proportional)
    {
        const CGFloat rx = newSize.width / size.width;
        const CGFloat ry = newSize.height / size.height;
        const CGFloat r = rx < ry ? rx : ry;
        size.width *= r;
        size.height *= r;
    }
    else
    {
        size = newSize;
    }
    
    [copy setScalesWhenResized:YES];
    [copy setSize:size];
    
    return copy;
}

@end
