//
//  NSMutableArray+PGMutableArray.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/02/2013.
//
//

#import "NSMutableArray+PGMutableArray.h"

@implementation NSMutableArray (PGMutableArray)

-(void)swapObjectAtIndex:(const NSUInteger)index0 withObjectAtIndex:(const NSUInteger)index1
{
    const id obj0 = self[index0];
    self[index0] = self[index1];
    self[index1] = obj0;
}

@end
