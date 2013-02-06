//
//  NSMutableArray+PGMutableArray.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/02/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (PGMutableArray)

-(void)swapObjectAtIndex:(const NSUInteger)index0 withObjectAtIndex:(const NSUInteger)index1;

@end
