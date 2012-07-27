//
//  SqliteParamInt32.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqliteParam.h"

@interface SqliteParamInt32 : SqliteParam
{
    @private
    int value;
}

@property (nonatomic, assign) int value;

- (id) initWithName:(NSString *)theName int32Value:(int)theValue;

@end
