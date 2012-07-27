//
//  PGConnectionDelegate.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGConnection;

@protocol PGConnectionDelegate <NSObject>

@optional
-(void)connectionSuccessful:(PGConnection*)theConnection;
-(void)connectionNeedsPassword:(PGConnection*)theConnection;
-(void)connectionFailed:(PGConnection*)theConnection message:(NSString*)theMessage;

@end
