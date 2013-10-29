//
//  SQLHelper.h
//  SecMail
//
//  Created by liugang.zhang on 13-10-29.
//  Copyright (c) 2013年 CandZen Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <MailCore/MailCore.h>

@interface SQLHelper : NSObject
{
    sqlite3 *db;
}

+ (SQLHelper*) sharedSQLHelper;

+ (MCOIMAPMessage*)imapMessageFromDictionary:(NSDictionary*) dict;

- (int) countOfTable:(NSString*)table;

- (NSArray*) querySQL:(NSString*)sql;

- (int) insertMailWithUid:(NSInteger)uid subject:(NSString*)subject messageid:(NSString*)messageid date:(NSInteger)date sender:(NSString*)sender add:(NSString*)senderMailBox from:(NSString*)from add:(NSString*)fromMailBox body:(NSString*)plaintextbody;

- (void) updateMailWithUid:(NSInteger)uid body:(NSString*)plaintextbody;
@end
