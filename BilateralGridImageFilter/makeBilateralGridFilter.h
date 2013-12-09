//
//  makeBilateralGridFilter.h
//  BilateralGridImageFilter
//
//  Created by Haozhu Wang on 12/8/13.
//  Copyright (c) 2013 Haozhu Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface makeBilateralGridFilter : NSObject
    +(UIImage *) filterWithBilateralGrid:(UIImage*) oldImage SpatialSample:(int)ss  RangeSample:(double) sr;
@end
