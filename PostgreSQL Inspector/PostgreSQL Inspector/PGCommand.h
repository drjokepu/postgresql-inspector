//
//  PGCommand.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import <Foundation/Foundation.h>

@class PGConnection, PGResult;

@interface PGCommand : NSObject

@property (nonatomic, strong) NSString* commandText;
@property (nonatomic, strong) PGConnection *connection;

-(void)execAsyncWithCallback:(void(^)(PGResult *result))resultCallback;

@end
