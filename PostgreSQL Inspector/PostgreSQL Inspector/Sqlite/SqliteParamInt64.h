//
//  SqliteParamInt64.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 17/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqliteParam.h"

@interface SqliteParamInt64 : SqliteParam
{
    @private
    long long value;
}

@property (nonatomic, assign) long long value;

- (id) initWithName:(NSString *)theName int64Value:(long long)theValue;

@end
