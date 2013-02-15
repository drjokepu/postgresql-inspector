//
//  NSImage+PGImage.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/02/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface NSImage (PGImage)

-(NSImage *)imageScaledToSize:(NSSize)newSize proportionally:(BOOL)proportional;

@end
