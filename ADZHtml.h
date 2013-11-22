#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ADZMessageSummary;

@interface ADZHtml : NSManagedObject

@property (nonatomic, retain) NSString * szHtml;
@property (nonatomic, retain) NSString * szUid;
@property (nonatomic, retain) ADZMessageSummary *summary;
@end
