
#import "ADZLoginViewController.h"
#import "FXKeychain.h"

//NSString * const UsernameKey = @"username";
//NSString * const PasswordKey = @"password";
//NSString * const HostnameKey = @"hostname";


@interface ADZLoginViewController ()

@end

@implementation ADZLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _account.text   = [[NSUserDefaults standardUserDefaults] stringForKey:UsernameKey];
    _password.text  = [[FXKeychain defaultKeychain] objectForKey:PasswordKey];
    _host.text  = [[NSUserDefaults standardUserDefaults] stringForKey:HostnameKey];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)doneEditing:(id)sender
{
    [sender resignFirstResponder];
}
- (IBAction)backUpTouch:(id)sender
{
    [_account resignFirstResponder];
    [_password resignFirstResponder];
    [_host resignFirstResponder];
}
- (IBAction)login:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:_account.text? :@""
                                              forKey:UsernameKey];
    [[NSUserDefaults standardUserDefaults] setObject:_host.text? :@""
                                              forKey:HostnameKey];
    [[FXKeychain defaultKeychain] setObject:_password.text? :@""
                                     forKey:PasswordKey];
    [self.delegate accountHasFinishSetting:self];
}
@end
