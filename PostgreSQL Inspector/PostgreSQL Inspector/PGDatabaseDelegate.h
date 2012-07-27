//
//  PGDatabaseDelegate.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGDatabase;

@protocol PGDatabaseDelegate <NSObject>

-(void)databaseDidUpdateSchema:(PGDatabase*)theDatabase;

@end
