//
//  PGActionBlockWrapper.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/06/2013.
//
//

#import <Foundation/Foundation.h>

@interface PGActionBlockWrapper : NSObject
@property (nonatomic, strong) void(^block)();
-(id)initWithBlock:(void(^)())theBlock;
-(void)action;
@end
