//
//  SISendViewController.m
//  BarCodeScannerPOC
//
//  Created by Harmen ter Horst on 18-02-14.
//  Copyright (c) 2014 Solid Ingenuity. All rights reserved.
//

#import "SISendViewController.h"

@interface SISendViewController () <UIAlertViewDelegate>

@end

@implementation SISendViewController

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
    _textfield.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"previousSendURL"];
    [_textfield becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        [self performSegueWithIdentifier:@"unwindToViewControllerID" sender:self];
    } else {
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
    }
}

- (IBAction)tappedSendBtn:(UIButton *)sender
{
    if (_textfield.text == NULL || [_textfield.text isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@"Fout!" message:@"Geen URL ingevoerd. Voer URL in!" delegate:self cancelButtonTitle:@"Oké" otherButtonTitles:nil, nil] show];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:_textfield.text forKey:@"previousSendURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *barCoded = [_textfield.text stringByReplacingOccurrencesOfString:@"{0}" withString:_barCode];
    NSString *barCodedAndAmounted = [barCoded stringByReplacingOccurrencesOfString:@"{1}" withString:[NSString stringWithFormat:@"%li", _amount]];
    
    NSURL *url = [NSURL URLWithString:barCodedAndAmounted];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSError *error;
    NSURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Fout tijdens verzenden!" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Oké" otherButtonTitles:nil, nil];
        errorAlert.tag = 1;
        [errorAlert show];
    }
    
    UIAlertView *responseAlert = [[UIAlertView alloc] initWithTitle:@"Response" message:[NSString stringWithFormat:@"%@", response] delegate:self cancelButtonTitle:@"Oké" otherButtonTitles:nil, nil];
    responseAlert.tag = 2;
    [responseAlert show];
}
@end
