#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ADZMessageAttachment;
@class ADZHtml;

@interface ADZMessageSummary : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * szPlaintext;
@property (nonatomic, retain) NSString * szSubject;
@property (nonatomic, retain) NSString * szUid;
@property (nonatomic, retain) ADZHtml * html;
@property (nonatomic, retain) NSSet *attachment;

@end


