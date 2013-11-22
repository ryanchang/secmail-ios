
#import <UIKit/UIKit.h>
#import "FXKeychain.h"
#import "ADZStoreMsgToCoreData.h"
#import "ADZMessageSummary.h"
#import "ADZLoginViewController.h"
#import "ADZMsgViewController.h"
#import "SettingsViewController.h"

@interface ADZMasterViewController : UITableViewController
<ADZLoginViewControllerDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *loadMoreActivityView;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *aryMsgs;

@property (assign, nonatomic) NSInteger countOfMsgInServer;
@property (assign, nonatomic) BOOL accoutIsValid;
@property (assign, nonatomic) BOOL isLoading;

@property (strong, nonatomic) ADZStoreMsgToCoreData *storeMsg;

@property (strong, nonatomic) MCOIMAPSession *imapSession;
@property (strong, nonatomic) MCOIMAPFetchMessagesOperation *imapMsgFetchOp;;

- (IBAction)setAccount:(id)sender;

@end
