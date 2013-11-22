//
//  ADZMsgViewController.m
//  SecMail
//
//  Created by Andy_Zhang on 13-11-19.
//  Copyright (c) 2013年 CandZen Co., Ltd. All rights reserved.
//

#import "ADZMsgViewController.h"

@interface ADZMsgViewController ()

@end

@implementation ADZMsgViewController

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
    _storeMsg.delegate  = self;
    NSString *szHtml    = [_storeMsg searchHtmlOfMsg:_msg];

    if (szHtml == NULL) {
        //

    }else{
        [_webView loadHTMLString:szHtml baseURL:NULL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseAttachment:(id)sender
{
    

}

#pragma mark - ADZStoreMsgToCoreDataDelagate
- (void)attachmentHadFinishLoaded:(ADZStoreMsgToCoreData *)storeMsgToCoreDataDelagate
                messageAttachment:(NSData *)data
{

}
- (void)htmlHadFinishLoaded:(ADZStoreMsgToCoreData *)storeMsgToCoreDataDelagate html:(NSString *)szHtml
{
    [_webView loadHTMLString:szHtml baseURL:NULL];
}
@end
