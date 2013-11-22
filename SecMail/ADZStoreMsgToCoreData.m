#import "ADZStoreMsgToCoreData.h"

#define printfPart   NSLog( @"\n***************************************************\n"  \
                            @"file:%s,"   \
                            @"line:%d,"@"function:%s\n"  \
                            @"partID:%@\n"  \
                            @"filename:%@\n"  \
                            @"mimeType:%@\n"  \
                            @"uniqueID:%@\n"  \
                            @"contentID:%@\n" \
                            @"contentLocation:%@\n"   \
                            @"contentDescription:%@\n"   \
                            @"charset:%@\n"   \
                            @"encoding:%d\n"  \
                            @"***************************************************", __FILE__, __LINE__, __FUNCTION__, part.partID, part.filename, part.mimeType, part.uniqueID, part.contentID, part.contentLocation, part.contentDescription, part.charset, part.encoding)
#define printMsg    NSLog(  @"\n***************************************************\n" \
                            @"file:%s,"   \
                            @"line:%d\n"  \
                            @"uid:%d\n"   \
                            @"modSeqValue:%llu\n" \
                            @"mainPart:%@\n"  \
                            @"header:%@\n"    \
                            @"attachments:%@\n"   \
                            @"htmlInlineAttachments:%@\n" \
                            @"***************************************************", __FILE__, __LINE__, _imapMessage.uid, _imapMessage.modSeqValue, _imapMessage.mainPart, _imapMessage.header, _imapMessage.attachments, _imapMessage.htmlInlineAttachments)

@implementation ADZStoreMsgToCoreData

- (ADZAllUids *)uids
{
    if (_uids) {
        return _uids;
    }
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"UIDS"];
    NSArray *aryFinds   = [_managedObjectContext executeFetchRequest:fetchRequest error:Nil];
    if (!aryFinds || !aryFinds.count) {
        _uids   = (ADZAllUids *)[NSEntityDescription insertNewObjectForEntityForName:@"UIDS" inManagedObjectContext:_managedObjectContext];
    }else{
        _uids   = aryFinds.firstObject;
    }
    return _uids;
}

- (NSMutableDictionary *)dicCached
{
    if (_dicCached) {
        if (_dicCached.count >10 ) {
            [_dicCached removeAllObjects];
            _dicCached  = NULL;
            _dicCached  = [NSMutableDictionary dictionary];
        }
        return _dicCached;
    }
    _dicCached  = [NSMutableDictionary dictionary];
    return _dicCached;
}

- (NSArray *)searchAllSummaryOfMsg
{

    NSSortDescriptor *sort  = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"SUMMARY"];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    NSArray *aryFinds  = [_managedObjectContext executeFetchRequest:fetchRequest
                                                              error:nil];
    NSMutableArray *ary = [NSMutableArray new];
    for (ADZMessageSummary *summary in aryFinds) {
        [ary addObject:@{@"szUid" : summary.szUid,
                         @"szSubject" : summary.szSubject,
                         @"szPlaintext" : summary.szPlaintext}];
    }
    NSArray *ary_   = [NSArray arrayWithArray:ary];
    ary = NULL;
    return ary_;
}

- (NSString *)searchPlaintextOfMsg:(MCOIMAPMessage *)imapMsg
{
    if (imapMsg == NULL) {
        return NULL;
    }

    ADZCached *item = NULL;
    NSString *szUid   = [NSString stringWithFormat:@"%d", imapMsg.uid];

    if (self.dicCached[szUid]) {
        item = _dicCached[szUid];
        if (!item.szPlaintext) {
            [_dicCached removeObjectForKey:szUid];
            return NULL;
        }
        return item.szPlaintext;
    }

    ADZMessageSummary *summary  = NULL;

    if ([self.uids.szUids rangeOfString:szUid].length > 0) {
        NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"SUMMARY"];
        NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"szUid == %@", szUid];
        fetchRequest.predicate  = predicate;
        NSArray *aryFinds   = [_managedObjectContext executeFetchRequest:fetchRequest error:Nil];

        if (!aryFinds || !aryFinds.count) {
            [_uids.szUids stringByReplacingOccurrencesOfString:szUid withString:@""];
            return NULL;
        }                                                     
        summary  = aryFinds.firstObject;
        if (!summary.szPlaintext) {
            [self setPlaintext:imapMsg summary:summary];
            return NULL;
        }
        item = [ADZCached new];
        item.szPlaintext    = summary.szPlaintext;
        _dicCached[szUid]   = item;
        NSString *szPlaintext = [NSString stringWithFormat:@"%@", item.szPlaintext];
        item    = NULL;
        return szPlaintext;
    }

    summary = (ADZMessageSummary *)[NSEntityDescription insertNewObjectForEntityForName:@"SUMMARY" inManagedObjectContext:_managedObjectContext];
    summary.szSubject   = imapMsg.header.subject;
    summary.szUid       = szUid;
    summary.date        = imapMsg.header.date;
    [self setPlaintext:imapMsg summary:summary];
    summary = NULL;
    return NULL;
}

- (NSString *)searchHtmlOfMsg:(id)msg
{
    if (msg == NULL) {
        return NULL;
    }

    NSString *szUid = NULL;

    if ([msg isKindOfClass:[MCOIMAPMessage class]]) {
        szUid   = [NSString stringWithFormat:@"%d", ((MCOIMAPMessage *)msg).uid];
    }else{
        szUid     = [msg objectForKey:@"szUid"];
    }

    ADZCached   *item   = _dicCached[szUid];
    if (item.szHtml) {
        return item.szHtml;
    }

    ADZHtml *html   = NULL;

    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"HTML"];
    NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"szUid == %@", szUid];
    fetchRequest.predicate  = predicate;
    NSArray *aryFinds   = [_managedObjectContext executeFetchRequest:fetchRequest error:Nil];
    if (aryFinds && aryFinds.count) {
        html   = aryFinds.firstObject;
        if (html.szHtml) {
            [_dicCached[szUid] setValue:html.szHtml forKey:@"szHtml"];
            return [NSString stringWithFormat:@"%@", html.szHtml];
        }
    }

    html    = (ADZHtml *)[NSEntityDescription insertNewObjectForEntityForName:@"HTML" inManagedObjectContext:_managedObjectContext];
    html.szUid       = szUid;
    [self setHtmlFromServer:(MCOIMAPMessage *)msg html:html];
    html    = NULL;
    return NULL;
}
- (NSData *)searchAttachmentOfMsg:(id)msg
                     fileName:(NSString *)name
{
    if (name == NULL || msg == NULL) {
        return NULL;
    }

    NSString *szUid = NULL;

    if (!msg && [msg isKindOfClass:[MCOIMAPMessage class]]) {
        szUid   = [NSString stringWithFormat:@"%d", ((MCOIMAPMessage *)msg).uid];
    }
    else
    {
        szUid     = [msg objectForKey:@"szUid"];
    }

    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:@"ATTACHMENT"];
    NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"szUid == %@", szUid];
    [fetchRequest setPredicate:predicate];
    NSArray *aryFinds  = [_managedObjectContext executeFetchRequest:fetchRequest
                                                            error:nil];
    NSPredicate *predicate_  = [NSPredicate predicateWithFormat:@"szFileName == %@", name];
    NSArray *aryFinds_  = [aryFinds filteredArrayUsingPredicate:predicate_];

    if (aryFinds_ != NULL && aryFinds_.count != 0) {
        ADZMessageAttachment *attachment    = aryFinds_.firstObject;
        if (attachment.dataContent) {
            [self.delegate attachmentHadFinishLoaded:self
                                   messageAttachment:attachment.dataContent];
            return attachment.dataContent;
        }
    }

    NSPredicate *predicate__  = [NSPredicate predicateWithFormat:@"filename == %@", name];
    NSArray *aryFinds__    = [((MCOIMAPMessage *)msg).attachments filteredArrayUsingPredicate:predicate__];

    if (aryFinds__ == NULL || aryFinds__.count == 0) {
        return NULL;
    }

    MCOIMAPPart *part   = (MCOIMAPPart *)aryFinds__.firstObject;

    ADZMessageAttachment *attachment    = [NSEntityDescription insertNewObjectForEntityForName:@"ATTACHMENT"
                                                                        inManagedObjectContext:_managedObjectContext];
    attachment.szFileName   = part.filename;
    attachment.szMimeType   = part.mimeType;
    attachment.szPartUid    = part.partID;
    attachment.szFileName   = part.filename;

    [self setAttachment:(MCOIMAPMessage *)msg
                   part:part
             attachment:attachment];
    return NULL;
}

-(void)setPlaintext:(MCOIMAPMessage *)imapMsg summary:(ADZMessageSummary *)summary
{
    if (imapMsg == NULL || summary == NULL) {
        return;
    }
    MCOIMAPMessageRenderingOperation *op    = [_imapSession plainTextBodyRenderingOperationWithMessage:imapMsg folder:@"INBOX"];
    [op start:^(NSString *plaintextBodyString, NSError *error) {
        summary.szPlaintext = plaintextBodyString;
        _uids.szUids    = [NSString stringWithFormat:@"%@, %@", _uids.szUids, summary.szUid];
        [_managedObjectContext save:NULL];
        ADZCached *item = [ADZCached new];
        item.szPlaintext    = summary.szPlaintext;
        _dicCached[summary.szUid] = item;
        item    = NULL;
    }];
};

-(void)setHtmlFromServer:(MCOIMAPMessage *)imapMsg html:(ADZHtml *)html_
{
    if (imapMsg == NULL || html_ == NULL) {
        return;
    }
    MCOIMAPMessageRenderingOperation *op    = [_imapSession htmlRenderingOperationWithMessage:imapMsg
                                                                                       folder:@"INBOX"];
    __weak  ADZStoreMsgToCoreData *weakSelf = self;

    [op start:^(NSString *htmlString, NSError * error) {
        html_.szHtml  = htmlString;
        [_managedObjectContext save:NULL];
        [_dicCached[html_.szUid] setValue:htmlString forKey:@"szHtml"];
        [weakSelf.delegate htmlHadFinishLoaded:weakSelf
                                          html:htmlString];
    }];
};

-(void)setAttachment:(MCOIMAPMessage *)imapMsg
                part:(MCOIMAPPart *)part
          attachment:(ADZMessageAttachment *)attachment
{
    if (imapMsg == NULL || part == NULL || attachment == NULL) {
        return;
    }
    __weak  ADZStoreMsgToCoreData *weakSelf = self;

    MCOIMAPFetchContentOperation *op    = [_imapSession fetchMessageAttachmentByUIDOperationWithFolder:@"INBOX"
                                                                                                   uid:[imapMsg uid]
                                                                                                partID:[part partID]
                                                                                              encoding:[part encoding]];
    [op start:^(NSError * error, NSData * data) {
        attachment.dataContent  = data;
        [_managedObjectContext save:NULL];
        [weakSelf.delegate attachmentHadFinishLoaded:weakSelf
                                   messageAttachment:data];
    }];
}
//#pragma mark - MCOHTMLRendererIMAPDelegate
//
//- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header
//{
//    return Nil;
//}
//
//- (NSDictionary *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part
//{
//    return Nil;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header
//{
//    return Nil;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header
//{
//    NSString *szTemplate    = @"<div id=\"{{CONTENTID}}\">\
//                                    <img src=\"{{URL}}\"/>\
//                                    </div>";
//    return szTemplate;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part
//{
//
//    NSString *szTemplate    = @"<div id=<div id=\"{{CONTENTID}}\">\
//                                    <div><img src=\"http://www.iconshock.com/img_jpg/OFFICE/general/jpg/128/attachment_icon.jpg\"/></div>\
//                                    {{#HASSIZE}}\
//                                    <div>- {{FILENAME}}, {{SIZE}}</div>\
//                                    {{/HASSIZE}}\
//                                    {{#NOSIZE}}\
//                                    <div>- {{FILENAME}}</div>\
//                                    {{/NOSIZE}}\
//                                    </div>";
//    return szTemplate;
//}
//
//- (NSString *)MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg
//{
//   NSString *szTemplate     = @"<div style=\"padding-bottom: 20px; font-family: Helvetica; font-size: 13px;\">{{HEADER}}</div>\
//                                <div>{{BODY}}</div>";
//    return szTemplate;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg
//       templateForEmbeddedMessage:(MCOAbstractMessagePart *)part
//{
//    return Nil;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg
// templateForEmbeddedMessageHeader:(MCOMessageHeader *)header
//{
//    return nil;
//}
//
//- (NSString *)MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg
//{
//    return nil;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg
//                filterHTMLForPart:(NSString *)html
//{
//    return nil;
//}
//
//- (NSString *)MCOAbstractMessage:(MCOAbstractMessage *)msg
//             filterHTMLForMessage:(NSString *)html
//{
//    return Nil;
//}
//
//- (NSData *)MCOAbstractMessage:(MCOAbstractMessage *)msg
//               dataForIMAPPart:(MCOIMAPPart *)part
//                        folder:(NSString *)folder
//{
//    return NULL;
//}
//
//- (void)MCOAbstractMessage:(MCOAbstractMessage *)msg
// prefetchAttachmentIMAPPart:(MCOIMAPPart *)part
//                     folder:(NSString *)folder
//{
//
//}
//
//- (void)MCOAbstractMessage:(MCOAbstractMessage *)msg
//      prefetchImageIMAPPart:(MCOIMAPPart *)part
//                     folder:(NSString *)folder
//{
//
//}

@end