//
//  SQLHelper.m
//  SecMail
//
//  Created by liugang.zhang on 13-10-29.
//  Copyright (c) 2013年 CandZen Co., Ltd. All rights reserved.
//

#import "SQLHelper.h"

static SQLHelper *_sharedSQLHelper;

@implementation SQLHelper

- (id) init
{
    self=[super init];
    if (self) {
        [self openDatabase];
        [self createTable];
        [self closeDatabase];
    }
    return self;
}

+ (SQLHelper*) sharedSQLHelper
{
    @synchronized([SQLHelper class]){
		if (!_sharedSQLHelper){
			_sharedSQLHelper = [[self alloc] init];
		}
        return _sharedSQLHelper;
	}
}

+ (MCOIMAPMessage *)imapMessageFromDictionary:(NSDictionary *)dict {
    MCOAddress *sender = [MCOAddress addressWithDisplayName:[dict objectForKey:@"mail_sender"] mailbox:[dict objectForKey:@"sendermailbox"]];
    MCOAddress *from= [MCOAddress addressWithDisplayName:[dict objectForKey:@"mail_from"] mailbox:[dict objectForKey:@"frommailbox"]];
    MCOMessageHeader *header = [[MCOMessageHeader alloc] init];
    header.sender = sender;
    header.from = from;
    header.messageID = [dict objectForKey:@"messageid"];
    header.date = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"mail_date"] longLongValue]];
    header.subject = [dict objectForKey:@"subject"];
    
    MCOIMAPMessage *mess = [[MCOIMAPMessage alloc] init];
    mess.header = header;
    mess.uid = [[dict objectForKey:@"uid"] integerValue];
    
    return mess;
}

- (NSString *)databasePath {
    NSString *pathName = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [pathName stringByAppendingString:@"/tissot.sqlite"];
}

- (void) openDatabase {
    if (sqlite3_open([[self databasePath] UTF8String], &db) == SQLITE_OK) {
        const char* key = [@"BIGSecret" UTF8String];
        sqlite3_key(db, key, strlen(key));
    } else {
        NSLog(@"open database failed;");
    }
}

- (void) closeDatabase {
    sqlite3_close(db);
}

- (void) createTable {
    NSString *sql = @"create table if not exists mails(id integer primary key autoincrement,uid integer,subject text,messageid text,mail_date integer,mail_sender text,sendermailbox text, mail_from text,frommailbox text,plaintextbody text);";
    char *err;
    if(sqlite3_exec(db, [sql UTF8String], nil, nil, &err) != SQLITE_OK)
    {
        NSLog(@"create table failed,%s",err);
    }
}

- (int)countOfTable:(NSString *)table {
    NSString *sql = [NSString stringWithFormat:@"select count(*) from %@",table];
    sqlite3_stmt *statment;
    int count = 0;
    [self openDatabase];
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &statment, nil) == SQLITE_OK) {
        while (sqlite3_step(statment) == SQLITE_ROW) {
            count = sqlite3_column_int(statment, 0);
            NSLog(@"table:%@ count number :%d",table,count);
        }
    }
    sqlite3_finalize(statment);
    [self closeDatabase];
    return count;
}

- (int)insertMailWithUid:(NSInteger)uid subject:(NSString *)subject messageid:(NSString *)messageid date:(NSInteger)date sender:(NSString *)sender add:(NSString *)senderMailBox from:(NSString *)from add:(NSString *)fromMailBox body:(NSString *)plaintextbody {
    NSString *sql = [NSString stringWithFormat:@"insert into 'mails' ('uid','subject','messageid','mail_date','mail_sender','sendermailbox','mail_from','frommailbox','plaintextbody') values (%d,'%@','%@',%d,'%@','%@','%@','%@','%@')",uid,subject,messageid,date,sender,senderMailBox,from,fromMailBox,plaintextbody];
    return  [self insertSQL:sql];
}

- (void)updateMailWithUid:(NSInteger)uid body:(NSString *)plaintextbody {
    NSString *sql = [NSString stringWithFormat:@"update mails set plaintextbody = '%@' where uid = %d",plaintextbody,uid];
    [self executeSQL:sql];
}


- (NSArray*) querySQL:(NSString*)sql {
    [self openDatabase];
    sqlite3_stmt *statment = nil;
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &statment, nil) == SQLITE_OK) {
        int columnCount = sqlite3_column_count(statment);
        NSLog(@"column number :%d",columnCount);
        while (sqlite3_step(statment) == SQLITE_ROW) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            for (int i = 0; i < columnCount; i++) {
                const char *type = sqlite3_column_decltype(statment, i);
                const char *name = sqlite3_column_name(statment, i);
                if (strcmp(type, "integer") == 0|| strcmp(type, "boolean") == 0) {
                    [dict setObject:[NSNumber numberWithInt:sqlite3_column_int(statment, i)] forKey:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
                }else if (strcmp(type, "text") == 0 || strcmp(type, "date") == 0) {
                    const char * value = (const char *)sqlite3_column_text(statment, i);
                    if (value) {
                        [dict setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:[NSString stringWithCString:name encoding:NSUTF8StringEncoding ]];
                    }
                    
                }else if (strcmp(type, "float") == 0 || strcmp(type, "double") == 0) {
                    [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statment, i)] forKey:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
                }
            }
            [arr addObject:dict];
        }
    }
    
    [self closeDatabase];
    return arr;
}

- (int) insertSQL:(NSString*)sql {
    NSLog(@"insert sql:%@",sql);
    [self openDatabase];
    int i = 0;
    sqlite3_stmt *statment = nil;
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &statment, nil) == SQLITE_OK) {
        if (sqlite3_step(statment) == SQLITE_DONE) {
            i = (int)sqlite3_last_insert_rowid(db);
            NSLog(@"insert success, id:%d",i);
        }
    }else {
        NSLog(@"insert failed");
    }
    [self closeDatabase];
    return i;
}

- (void) executeSQL :(NSString*)sql {
    [self openDatabase];
    NSLog(@"execute sql:%@",sql);
    char *err;
    sqlite3_exec(db, [sql UTF8String], nil, nil, &err);
    if (err) {
        NSLog(@"execute failed:%s",err);
    }
    [self closeDatabase];
}

@end
