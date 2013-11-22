#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ADZMessageSummary;

@interface ADZMessageAttachment : NSManagedObject

@property (nonatomic, retain) NSString * szUid;
@property (nonatomic, retain) NSData * dataContent;
@property (nonatomic, retain) NSString * szFileName;
@property (nonatomic, retain) NSString * szPartUid;
@property (nonatomic, retain) NSString * szMimeType;
@property (nonatomic, retain) ADZMessageSummary *summary;

@end
