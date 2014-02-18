//
//  SISendViewController.h
//  BarCodeScannerPOC
//
//  Created by Harmen ter Horst on 18-02-14.
//  Copyright (c) 2014 Solid Ingenuity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SISendViewController : UIViewController

@property (nonatomic, strong) NSString *barCode;
@property (nonatomic, assign) NSInteger amount;
@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

- (IBAction)tappedSendBtn:(UIButton *)sender;

@end
