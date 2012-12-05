//
//  PGDataReader.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libpq-fe.h>

@class PGResult;

@interface PGDataReader : NSObject

@property (nonatomic, assign) NSUInteger sequenceNumber;

-(id)initWithPXResult:(px_result *)thePxResult;
-(PGResult*)result;
-(void)close;

@end
