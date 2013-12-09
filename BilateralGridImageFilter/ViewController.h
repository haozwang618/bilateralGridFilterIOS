//
//  ViewController.h
//  BilateralGridImageFilter
//
//  Created by Haozhu Wang on 12/8/13.
//  Copyright (c) 2013 Haozhu Wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, UIAlertViewDelegate>
    @property (strong, nonatomic) IBOutlet UILabel *spaceSampleLabel;
    @property (strong, nonatomic) IBOutlet UISlider *spaceSampleSlider;
    @property (strong, nonatomic) IBOutlet UILabel *rangeSampleLabel;
    @property (strong, nonatomic) IBOutlet UISlider *rangeSampleSlider;
    @property (strong, nonatomic) IBOutlet UIButton *filterButton;
    @property (strong, nonatomic) IBOutlet UIButton *ToggleButton;
    @property (strong, nonatomic) IBOutlet UIImageView *myImageView;
@property (strong, nonatomic) IBOutlet UIButton * cameraButton;
@property (strong, nonatomic) IBOutlet UIButton * photoButton;
    
    @property (strong, nonatomic) UIImagePickerController *imagePickerController;
    @property (strong,nonatomic) UIImage* original;
    @property (strong,nonatomic)UIImage* filtered_img;
    
    -(IBAction)cameraAction:(id)sender;
    -(IBAction)photoSelectAction:(id)sender;
    -(IBAction) spaceSampleSliderChange:(id)sender;
    -(IBAction) rangeSampleSliderChange:(id)sender;
    -(IBAction) toggleAction:(id)sender;
    -(IBAction)filterAction:(id)sender;
@end
