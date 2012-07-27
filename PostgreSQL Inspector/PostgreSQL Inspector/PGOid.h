//
//  PGOid.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGOid : NSObject

@property (nonatomic, assign) unsigned int value;

-(id)initWithValue:(unsigned int)theValue;

@end
