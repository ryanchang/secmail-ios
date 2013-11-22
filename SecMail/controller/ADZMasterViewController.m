
#import "ADZMasterViewController.h"

static NSString *CellIdentifierMsg = @"Msg";
static NSString *CellIdentifierMore = @"More";

@interface ADZMasterViewController ()

@end

@implementation ADZMasterViewController

- (void)dealloc
{
    _storeMsg   = NULL;
    _imapSession    = NULL;
}

- (ADZStoreMsgToCoreData *)storeMsg
{
    if (_storeMsg) {
        return _storeMsg;
    }else{
        self.storeMsg   = [[ADZStoreMsgToCoreData alloc] init];
        _storeMsg.managedObjectContext  = _managedObjectContext;
        _storeMsg.imapSession   = _imapSession;
    }
    return _storeMsg;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _accoutIsValid  = NO;

    self.loadMoreActivityView   = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    NSString *szUsername = [[NSUserDefaults standardUserDefaults] objectForKey:UsernameKey];
	NSString *szPassword = [[FXKeychain defaultKeychain] objectForKey:PasswordKey];
	NSString *szHostname = [[NSUserDefaults standardUserDefaults] objectForKey:HostnameKey];

    if (!szUsername.length || !szPassword.length || !szHostname.length ) {
        [self performSelector:@selector(setAccount:)
                   withObject:NULL
                   afterDelay:1];
        return;
    }
    [self connectToServerWithUsername:szUsername
                             password:szPassword
                             hostname:szHostname];
}
- (void) connectToServerWithUsername:szUsername
                            password:szPassword
                            hostname:szHostname
{
    self.imapSession    = [[MCOIMAPSession alloc] init];
    _imapSession.hostname   = szHostname;
	_imapSession.username   = szUsername;
	_imapSession.password   = szPassword;
    _imapSession.port   = 993;
    _imapSession.connectionType = MCOConnectionTypeTLS;

//	_imapSession.connectionLogger = ^(void * connectionID, MCOConnectionLogType type, NSData * data){
//        @synchronized(weakSelf) {
//            if (type != MCOConnectionLogTypeSentPrivate) {
//                //NSLog(@"event logged:%p %i withData: %@", connectionID, type, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//            }
//        }
//    };

    self.storeMsg.imapSession   = _imapSession;

	MCOIMAPOperation *imapCheckOp   = [_imapSession checkAccountOperation];

	[imapCheckOp start:^(NSError *error) {
		if (error == nil) {
            NSLog(@"account is valid");
            _accoutIsValid  = YES;
            [self loadMsg:10];
		} else {
			NSLog(@"account is not valid");
            _accoutIsValid  = NO;
            _imapSession    = NULL;
            self.aryMsgs    = [self.storeMsg searchAllSummaryOfMsg];
            [self.tableView reloadData];
		}
	}];
}
- (void)loadMsg:(NSUInteger)number
{
    __weak ADZMasterViewController *weakSelf   = self;

    _isLoading = YES;

    MCOIMAPFolderInfoOperation *inboxFolderInfo    = [_imapSession folderInfoOperation:@"INBOX"];

    MCOIMAPMessagesRequestKind requestKind  = (MCOIMAPMessagesRequestKind)(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject | MCOIMAPMessagesRequestKindFlags);

    [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderInfo *info){
        BOOL totalNumberOfMsgDidChange     = (_countOfMsgInServer != [info messageCount]);
        _countOfMsgInServer = [info messageCount];

        NSUInteger numberOfMsgToLoad   = MIN(_countOfMsgInServer, number);
        if (numberOfMsgToLoad == 0) {
            _isLoading = NO;
            return ;
        }

        MCORange fetchRange;

        if (!totalNumberOfMsgDidChange && _aryMsgs.count ) {
            fetchRange  = MCORangeMake(_countOfMsgInServer - numberOfMsgToLoad + 1, (numberOfMsgToLoad - _aryMsgs.count - 1));
        }else{
            self.aryMsgs    = NULL;
            fetchRange  = MCORangeMake(_countOfMsgInServer - numberOfMsgToLoad + 1, (numberOfMsgToLoad - 1));
        }

        self.imapMsgFetchOp   = [_imapSession fetchMessagesByNumberOperationWithFolder:@"INBOX"
                                                                      requestKind:requestKind
                                                                          numbers:[MCOIndexSet indexSetWithRange:fetchRange]];
        [_imapMsgFetchOp setProgress:^(unsigned int progress) {
            NSLog(@"Progress: %u of %u", progress, numberOfMsgToLoad);
        }];

        [_imapMsgFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){
            if (error || messages == NULL || messages.count == 0) {
                self.isLoading = NO;
                weakSelf.imapMsgFetchOp = NULL;
                return ;
            }

            self.isLoading = NO;

            NSSortDescriptor *sort  = [NSSortDescriptor sortDescriptorWithKey:@"header.date"
                                                                    ascending:NO];
            NSMutableArray *combinedMessages    = [NSMutableArray arrayWithArray:messages];
            [combinedMessages addObjectsFromArray:_aryMsgs];
            self.aryMsgs    =[combinedMessages sortedArrayUsingDescriptors:@[sort]];
           [self.tableView reloadData];
            weakSelf.imapMsgFetchOp = NULL;
        }];
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setAccount:(id)sender
{
    [_imapMsgFetchOp cancel];_imapMsgFetchOp    = NULL;
    ADZLoginViewController *loginVC = [[ADZLoginViewController alloc] initWithNibName:@"ADZLoginViewController" bundle:NULL];
    loginVC.delegate    = self;
    [self presentViewController:loginVC
                       animated:YES
                     completion:NULL];
}
#pragma mark - ADZLoginViewControllerDelagate

- (void)accountHasFinishSetting:(ADZLoginViewController *)loginVC
{
    [self dismissViewControllerAnimated:YES
                             completion:NULL];

    NSString *szUsername = [[NSUserDefaults standardUserDefaults] objectForKey:UsernameKey];
	NSString *szPassword = [[FXKeychain defaultKeychain] objectForKey:PasswordKey];
	NSString *szHostname = [[NSUserDefaults standardUserDefaults] objectForKey:HostnameKey];

    if (![szUsername isEqualToString:_imapSession.username] ||
        ![szPassword isEqualToString:_imapSession.password] ||
        ![szHostname isEqualToString:_imapSession.hostname]) {
        _imapSession    = NULL;
        [self connectToServerWithUsername:szUsername
                             password:szPassword
                             hostname:szHostname];
    }
}
#pragma mark - UITableViewDataSource And UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return _aryMsgs.count;
    }else{
        if (_countOfMsgInServer <= _aryMsgs.count) {
            return 0;
        }
        return 1;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell   = NULL;

    if (indexPath.section == 0) {
        cell= [tableView dequeueReusableCellWithIdentifier:CellIdentifierMsg];

        if (!cell) {
            cell    = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:CellIdentifierMsg];
        }

        if (_accoutIsValid) {
            MCOIMAPMessage *imapMsg = _aryMsgs[indexPath.row];
            cell.textLabel.text = imapMsg.header.subject;
            NSString * szPlaintextBodyString  = [self.storeMsg searchPlaintextOfMsg:imapMsg];
            cell.detailTextLabel.text   = szPlaintextBodyString;
        }else{
            cell.textLabel.text = [_aryMsgs[indexPath.row] objectForKey:@"szSubject"];
            cell.detailTextLabel.text   = [_aryMsgs[indexPath.row] objectForKey:@"szPlaintext"];
        }
        return cell;
    }
    if (indexPath.section == 1) {
        cell= [tableView dequeueReusableCellWithIdentifier:CellIdentifierMore];

        if (!cell) {
            cell    = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:CellIdentifierMore];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        }

        if (_countOfMsgInServer <= _aryMsgs.count) {
            cell.textLabel.text   = NULL;
        }else{
            cell.textLabel.text = [NSString stringWithFormat:@"Load %d more", MIN(_countOfMsgInServer - _aryMsgs.count, 10)];
        }

        cell.detailTextLabel.text   = [NSString stringWithFormat:@"%d message(s)", _countOfMsgInServer];

        cell.accessoryView = _loadMoreActivityView;

        if (_isLoading)
            [_loadMoreActivityView startAnimating];
        else
            [_loadMoreActivityView stopAnimating];
        
        return cell;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:{
            ADZMsgViewController *msgVC = [[ADZMsgViewController alloc] initWithNibName:@"ADZMsgViewController" bundle:NULL];
            msgVC.storeMsg  = _storeMsg;
            msgVC.msg   = _aryMsgs[indexPath.row];
            [self.navigationController pushViewController:msgVC
                                                 animated:YES];
        }
            break;
        case 1:{
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

			if (!_isLoading &&
				_aryMsgs.count < _countOfMsgInServer)
			{
				[self loadMsg:_aryMsgs.count + 10];
				cell.accessoryView = _loadMoreActivityView;
				[_loadMoreActivityView startAnimating];
			}
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
    }
}
@end
