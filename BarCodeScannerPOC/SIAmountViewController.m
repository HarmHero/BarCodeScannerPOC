//
//  SIAmountViewController.m
//  BarCodeScannerPOC
//
//  Created by Harmen ter Horst on 18-02-14.
//  Copyright (c) 2014 Solid Ingenuity. All rights reserved.
//

#import "SIAmountViewController.h"
#import "SISendViewController.h"

@interface SIAmountViewController ()

@end

@implementation SIAmountViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	_label.text = [NSString stringWithFormat:@"Voer het aantal items in voor barcode %@", _barCode];
    _textField.placeholder = [NSString stringWithFormat:@"%i", 0];
    _textField.textAlignment = NSTextAlignmentRight;
    [_textField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tappedNextBtn:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"toSend" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toSend"]) {
        NSInteger amount;
        if ([_textField.text isEqualToString:@""] || _textField.text == NULL) {
            amount = 0;
        } else {
            amount = [_textField.text integerValue];
        }
        SISendViewController *sendVC = (SISendViewController *)segue.destinationViewController;
        sendVC.barCode = _barCode;
        sendVC.amount = amount;
    }
}
@end
