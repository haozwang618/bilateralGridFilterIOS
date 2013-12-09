//
//  ViewController.m
//  BilateralGridImageFilter
//
//  Created by Haozhu Wang on 12/8/13.
//  Copyright (c) 2013 Haozhu Wang. All rights reserved.
//

#import "ViewController.h"
#import "makeBilateralGridFilter.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize spaceSampleLabel = _spaceSampleLabel;
@synthesize rangeSampleLabel = _rangeSampleLabel;
@synthesize spaceSampleSlider = _spaceSampleSlider;
@synthesize rangeSampleSlider = _rangeSampleSlider;
@synthesize imagePickerController = _imagePickerController;
@synthesize original=_original;
@synthesize myImageView = _myImageView;
@synthesize filtered_img = _filtered_img;
    
int f=0;
int counter;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [_spaceSampleLabel setText:[NSString stringWithFormat:@"%d", (int)[_spaceSampleSlider value]]];
    [_rangeSampleLabel setText:[NSString stringWithFormat:@"%.1f", (double)[_rangeSampleSlider value]]];
    if (_imagePickerController == nil)
    {
        _imagePickerController = [[ UIImagePickerController alloc] init];
        [_imagePickerController setDelegate:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
-(IBAction)cameraAction:(id)sender
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [_imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:_imagePickerController animated:YES completion:nil];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"no camera detected!" message:@"no Camera found, please choose to pick from photo library!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];

    }
}
    
-(IBAction)photoSelectAction:(id)sender
{
    [_imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}
    
-(IBAction) spaceSampleSliderChange:(id)sender
{
    [_spaceSampleLabel setText:[NSString stringWithFormat:@"%d", (int)[_spaceSampleSlider value]]];

}

-(IBAction) rangeSampleSliderChange:(id)sender
{
    [_rangeSampleLabel setText:[NSString stringWithFormat:@"%.1f", (double)[_rangeSampleSlider value]]];

}

-(IBAction)toggleAction:(id)sender
{
    if (f > 0) {
        int choice = counter %2;
        if (choice == 0) {
            [_myImageView setImage:_original];
        }
        else
        {
            [_myImageView setImage:_filtered_img];
        }
        counter+=1;
    }
}
 
-(IBAction)filterAction:(id)sender
{
    if ([_myImageView image] != nil ) {
        _filtered_img=[makeBilateralGridFilter filterWithBilateralGrid:[_myImageView image] SpatialSample:(int)[_spaceSampleSlider value] RangeSample:(double)[_rangeSampleSlider value]];
        [_myImageView setImage:_filtered_img];
        ++f;
    }
}
    
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
    {
        _original = [info objectForKey:UIImagePickerControllerOriginalImage];
        [_myImageView setImage:_original];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        f = 0;
        counter =0;
    }
    


@end
