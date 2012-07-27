//
//  SqliteParamDouble.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 17/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqliteParam.h"

@interface SqliteParamDouble : SqliteParam
{
    @private
    double value;
}

@property (nonatomic, assign) double value;

- (id) initWithName:(NSString *)theName doubleValue:(double)theValue;

@end
