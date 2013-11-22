#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

#import "ADZAllUids.h"
#import "ADZMessageSummary.h"
#import "ADZHtml.h"
#import "ADZMessageAttachment.h"
#import "ADZCached.h"

@class ADZStoreMsgToCoreData;
@protocol ADZStoreMsgToCoreDataDelagate <NSObject>

- (void)htmlHadFinishLoaded:(ADZStoreMsgToCoreData *)storeMsgToCoreDataDelagate
                       html:(NSString *)szHtml;

@optional
- (void)attachmentHadFinishLoaded:(ADZStoreMsgToCoreData *)storeMsgToCoreDataDelagate
                messageAttachment:(NSData *)data;

@end

@interface ADZStoreMsgToCoreData : NSObject <MCOHTMLRendererIMAPDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableDictionary *dicCached;

@property (strong, nonatomic) ADZAllUids *uids;
@property (weak, nonatomic) id<ADZStoreMsgToCoreDataDelagate> delegate;

@property (strong, nonatomic) MCOIMAPSession *imapSession;

- (NSArray *)searchAllSummaryOfMsg;

- (NSString *)searchPlaintextOfMsg:(MCOIMAPMessage *)imapMsg;
- (NSString *)searchHtmlOfMsg:(id)msg;
- (NSData *)searchAttachmentOfMsg:(id)msg
                         fileName:(NSString *)name;



@end
