//
//  SIViewController.m
//  BarCodeScannerPOC
//
//  Created by Harmen ter Horst on 18-02-14.
//  Copyright (c) 2014 Solid Ingenuity. All rights reserved.
//

#import "SIViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "SIAmountViewController.h"

#define kMetadataOutputKey "metaDataQueueZSS"

#pragma mark - @Barcode

@interface Barcode : NSObject

@property (nonatomic, strong) AVMetadataMachineReadableCodeObject *metadataObject;
@property (nonatomic, strong) UIBezierPath *cornersPath;
@property (nonatomic, strong) UIBezierPath *boundingBoxPath;

@end

@implementation Barcode

@end

@interface SIViewController () <AVCaptureMetadataOutputObjectsDelegate>

@end

@implementation SIViewController {
    BOOL _running;
    NSMutableDictionary *_barcodes;
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_videoDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureMetadataOutput *_metadataOutput;
    NSString *_barCode;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _barCode = [NSString new];
    [self startScanner];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toAmount"]) {
        SIAmountViewController *amountVC = (SIAmountViewController *)segue.destinationViewController;
        amountVC.barCode = _barCode;
    }
}

- (void)startScanner
{
    if (_running) {
        [self stopRunning];
    } else {
        [self createScanView];
    }
}

- (void)setupCaptureSession
{
    if (_captureSession) {
        [self startRunning];
        return;
    };
    
    _videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!_videoDevice) {
        NSLog(@"No video camera on this device!");
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:nil];
    
    if ([_captureSession canAddInput:_videoInput])
        [_captureSession addInput:_videoInput];
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    _previewLayer.connection.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    dispatch_queue_t metadataQueue = dispatch_queue_create(kMetadataOutputKey, 0);
    [_metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
    
    if ([_captureSession canAddOutput:_metadataOutput])
        [_captureSession addOutput:_metadataOutput];
}

- (void)createScanView
{
    [self setupCaptureSession];
    
    _previewLayer.frame = _scanView.bounds;
    
    [_scanView.layer addSublayer:_previewLayer];
    
    _barcodes = [NSMutableDictionary new];
    
    [self startRunning];
}

- (void)startRunning
{
    if (_running) return;
    [_captureSession startRunning];
    _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code];
    _running = YES;
}

- (void)stopRunning
{
    if (!_running) return;
    [_captureSession stopRunning];
    _running = NO;
    [self performSelector:@selector(removeAllSubs) withObject:NULL afterDelay:1.5];
}

- (void)removeAllSubs
{
    [[_scanView.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    _previewLayer = nil;
    _captureSession = nil;
    _videoDevice = nil;
    _videoInput = nil;
    _metadataOutput = nil;
    _barcodes = nil;
    [self performSegueWithIdentifier:@"toAmount" sender:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)note
{
    [self stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSSet *originalBarcodes = [NSSet setWithArray:_barcodes.allValues];
    
    NSMutableSet *foundBarcodes = [NSMutableSet new];
    
    [metadataObjects enumerateObjectsUsingBlock:^(AVMetadataObject *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject *)[_previewLayer transformedMetadataObjectForMetadataObject:obj];
            Barcode *barcode = [self processMetadataObject:code];
            [foundBarcodes addObject:barcode];
        }
    }];
    
    NSMutableSet *newBarcodes = [foundBarcodes mutableCopy];
    [newBarcodes minusSet:originalBarcodes];
    
    NSMutableSet *goneBarcodes = [originalBarcodes mutableCopy];
    [goneBarcodes minusSet:foundBarcodes];
    
    [goneBarcodes enumerateObjectsUsingBlock:^(Barcode *barcode, BOOL *stop) {
        [_barcodes removeObjectForKey:barcode.metadataObject.stringValue];
    }];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSArray *allSublayers = [_scanView.layer.sublayers copy];
        [allSublayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
            if (layer != _previewLayer)
                [layer removeFromSuperlayer];
        }];
        
        [foundBarcodes enumerateObjectsUsingBlock:^(Barcode *barcode, BOOL *stop) {
            CAShapeLayer *cornersPathLayer = [CAShapeLayer new];
            cornersPathLayer.path = barcode.cornersPath.CGPath;
            cornersPathLayer.lineWidth = 2.0;
            cornersPathLayer.strokeColor = [UIColor greenColor].CGColor;
            cornersPathLayer.fillColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.4].CGColor;
            [_scanView.layer addSublayer:cornersPathLayer];
        }];
        
        [newBarcodes enumerateObjectsUsingBlock:^(Barcode *barcode, BOOL *stop) {
            if (barcode.metadataObject.type == AVMetadataObjectTypeEAN13Code || barcode.metadataObject.type == AVMetadataObjectTypeEAN8Code) {
                _barCode = barcode.metadataObject.stringValue;
                [self stopRunning];
            }
        }];
    });
}

- (Barcode *)processMetadataObject:(AVMetadataMachineReadableCodeObject *)code
{
    Barcode *barcode = _barcodes[code.stringValue];
    
    if (!barcode) {
        barcode = [Barcode new];
        _barcodes[code.stringValue] = barcode;
    }
    
    barcode.metadataObject = code;
    
    CGMutablePathRef cornersPath = CGPathCreateMutable();
    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)code.corners[0], &point);
    CGPathMoveToPoint(cornersPath, nil, point.x, point.y);
    
    for (NSInteger i = 1; i < code.corners.count; i++) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)code.corners[i], &point);
        CGPathAddLineToPoint(cornersPath, nil, point.x, point.y);
    }
    
    CGPathCloseSubpath(cornersPath);
    
    barcode.cornersPath = [UIBezierPath bezierPathWithCGPath:cornersPath];
    CGPathRelease(cornersPath);
    
    barcode.boundingBoxPath = [UIBezierPath bezierPathWithRect:code.bounds];
    
    return barcode;
}

- (IBAction)unwindToViewController:(UIStoryboardSegue *)unwindSegue
{
    [self startScanner];
}


@end
