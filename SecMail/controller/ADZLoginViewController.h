
#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

//extern NSString * const UsernameKey;
//extern NSString * const PasswordKey;
//extern NSString * const HostnameKey;

@class ADZLoginViewController;

@protocol ADZLoginViewControllerDelegate <NSObject>
@optional
- (void)accountHasFinishSetting:(ADZLoginViewController *)loginVC;

@end

@interface ADZLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *account;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *host;
@property (weak, nonatomic) id<ADZLoginViewControllerDelegate> delegate;

- (IBAction)doneEditing:(id)sender;
- (IBAction)backUpTouch:(id)sender;
- (IBAction)login:(id)sender;

@end
