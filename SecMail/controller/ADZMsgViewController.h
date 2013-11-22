#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "ADZStoreMsgToCoreData.h"
@interface ADZMsgViewController : UIViewController
<UIWebViewDelegate, ADZStoreMsgToCoreDataDelagate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) id msg;
@property (strong, nonatomic) ADZStoreMsgToCoreData *storeMsg;

@end
