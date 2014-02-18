//
//  SIAmountViewController.h
//  BarCodeScannerPOC
//
//  Created by Harmen ter Horst on 18-02-14.
//  Copyright (c) 2014 Solid Ingenuity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIAmountViewController : UIViewController

@property (nonatomic, strong) NSString *barCode;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

- (IBAction)tappedNextBtn:(UIButton *)sender;

@end
