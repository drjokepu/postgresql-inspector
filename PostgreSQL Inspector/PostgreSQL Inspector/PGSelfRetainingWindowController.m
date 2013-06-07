//
//  PGSelfRetainingWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGSelfRetainingWindowController.h"

static NSMutableArray *windowList = nil;

@interface PGSelfRetainingWindowController()
{
    void (^errorAlertCallback)(void);
}

@end

@implementation PGSelfRetainingWindowController

+(void)initialize
{
    if (windowList == nil)
    {
        windowList = [[NSMutableArray alloc] init];
    }
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    [windowList addObject:self];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [windowList removeObject:self];
}

-(void)showError:(NSString *)message informativeText:(NSString*)informativeText callback:(void (^)(void))endCallback
{
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@.", [PGSelfRetainingWindowController stringWithUppercaseFirstCharacter:informativeText]];
    self->errorAlertCallback = endCallback;
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (self->errorAlertCallback != nil)
    {
        self->errorAlertCallback();
        self->errorAlertCallback = nil;
    }
}

+(NSString*)stringWithUppercaseFirstCharacter:(NSString*)str
{
    if ([str length] == 0) return @"";
    if ([str length] == 1) return [str uppercaseString];
    NSString *firstChar = [str substringToIndex:1];
    NSString *tail = [str substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", [firstChar uppercaseString], tail];
}

@end
