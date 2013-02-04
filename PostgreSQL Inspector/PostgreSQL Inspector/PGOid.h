//
//  PGOid.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGType.h"

@interface PGOid : NSObject <NSCopying>

@property (nonatomic, assign) PGType type;

-(id)initWithType:(PGType)theType;
-(NSInteger)integerValue;
-(NSUInteger)unsignedIntegerValue;

@end
