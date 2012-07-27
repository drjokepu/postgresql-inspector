//
//  PGCommandDelegate.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGCommand, PGDataReader;

@protocol PGCommandDelegate <NSObject>

@required
-(void)command:(PGCommand*)command receivedResult:(PGDataReader*)reader;

@optional
-(void)commandHasNoMoreResults:(PGCommand*)command;

@end
