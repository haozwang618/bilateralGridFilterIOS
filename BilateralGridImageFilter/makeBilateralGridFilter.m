//
//  makeBilateralGridFilter.m
//  BilateralGridImageFilter
//
//  Created by Haozhu Wang on 12/8/13.
//  Copyright (c) 2013 Haozhu Wang. All rights reserved.
//

#import "makeBilateralGridFilter.h"
#import <math.h>

#ifndef MIN
#import <NSObjCRuntime.h>
#endif

@implementation makeBilateralGridFilter

const double PI= 3.1416;
typedef struct _gridCell
{
    double intensity;
    int count;
} gridCell;

int width;
int height;
    
int gridHeight;
int gridWidth;
    
int bytesPerPixel;
int bytesPerRow;
int bitsPerComponent;
    
int spaceSample;
double rangeSample;
+(UIImage *) filterWithBilateralGrid:(UIImage*) oldImage SpatialSample:(int)ss  RangeSample:(double) sr
{
    CGImageRef imageRef = [oldImage CGImage];
    spaceSample = ss;
    rangeSample = sr;
    
    width = CGImageGetWidth(imageRef);
    height =CGImageGetHeight(imageRef);
    gridHeight = ceil(height/(ss+0.0))+1;
    gridWidth = ceil(width/(ss+0.0))+1;

    double spactial_sig = (((double)MIN(width, height))/16.0);
    
    //drawing this in terms of raw data
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    bytesPerPixel = 4;
    bytesPerRow = bytesPerPixel * width;
    bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    //////////////////////////////////////
    double range_sig_0=(0.1*([self maxPixel:rawData channel:0]-[self minPixel:rawData channel:0]))/255.0;
    double range_sig_1=(0.1*([self maxPixel:rawData channel:0]-[self minPixel:rawData channel:1]))/255.0;
    double range_sig_2=(0.1*([self maxPixel:rawData channel:0]-[self minPixel:rawData channel:2]))/255.0;
    
    gridCell *** channel0 = [self makeGridChannel:rawData channel:0];
    gridCell *** channel1 = [self makeGridChannel:rawData channel:1];
    gridCell *** channel2 = [self makeGridChannel:rawData channel:2];
    
    gridCell *** newChannel0Grid = [self initGrid:rawData channel:0];
    gridCell *** newChannel1Grid = [self initGrid:rawData channel:1];
    gridCell *** newChannel2Grid = [self initGrid:rawData channel:2];
    
    int z0= ceil((([self maxPixel:rawData channel:0] - [self minPixel:rawData channel:0])/255.0)/rangeSample)+1;
    int z1= ceil((([self maxPixel:rawData channel:1] - [self minPixel:rawData channel:1])/255.0)/rangeSample)+1;
    int z2= ceil((([self maxPixel:rawData channel:2] - [self minPixel:rawData channel:2])/255.0)/rangeSample)+1;
    
    [self convolGrid:newChannel0Grid z:z0 oldGrid:channel0 sigmaSpatial:spactial_sig/spaceSample sigmaRange:range_sig_0/rangeSample];
    
    [self convolGrid:newChannel1Grid z:z1 oldGrid:channel1 sigmaSpatial:spactial_sig/spaceSample sigmaRange:range_sig_1/rangeSample];
    
    [self convolGrid:newChannel2Grid z:z2 oldGrid:channel2 sigmaSpatial:spactial_sig/spaceSample sigmaRange:range_sig_2/rangeSample];
    /////////////////////////////////////
    unsigned char * newData = [self interp_image:rawData channel0:newChannel0Grid channel1:newChannel1Grid channel2:newChannel2Grid];
    CGContextRef mContext = CGBitmapContextCreate(newData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef imRef = CGBitmapContextCreateImage(mContext);
    CGContextRelease(context);
    
    UIImage* newImage = [[UIImage alloc] initWithCGImage:imRef];
    return newImage;
}
    
+(unsigned char*) interp_image:(unsigned char*) rawData channel0:(gridCell***) cell0 channel1:(gridCell***) cell1 channel2:(gridCell***) cell2
{
    unsigned char *newData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    [self triLine_Interp:newData original:rawData grid:cell0 channel:0];
    [self triLine_Interp:newData original:rawData grid:cell1 channel:1];
    [self triLine_Interp:newData original:rawData grid:cell2 channel:2];
    
    for(int y=0; y<height; ++y)
    {
        unsigned char * row = &rawData[y*bytesPerRow];
        unsigned char * row1 = &newData[y*bytesPerRow];
        for (int x=0; x<width; ++x)
        {
            row1[bytesPerPixel*x+3] = row[bytesPerPixel*x+3];
        }
    }
    
    return newData;
}

+(void) triLine_Interp:(unsigned char *)newData original:(unsigned char *)rawData   grid:(gridCell ***) newGrid  channel:(int) channel
{
    double z_val;
    int grid_y_low, grid_y_high, grid_x_low,grid_x_high, grid_z_high, grid_z_low;
    double y_grid, x_grid,yd,xd,zd;
    double c00,c10,c01,c11,c0,c1,c;
    int minP= [self minPixel:rawData channel:channel];
    int maxP= [self maxPixel:rawData channel:channel];
    
    for(int y=0; y<height; ++y)
    {
        unsigned char * row = &rawData[y*bytesPerRow];
        unsigned char * row1 = &newData[y*bytesPerRow];
        y_grid = (y)/(spaceSample+0.0);
        grid_y_low = floor(y_grid);
        grid_y_high = ceil(y_grid);
        yd = (grid_y_low == grid_y_high)?0.0:(y_grid-grid_y_low)/(grid_y_high - grid_y_low);
        
        for(int x=0; x<width; ++x)
        {
            x_grid = (x)/(spaceSample+0.0);
            grid_x_low = floor(x_grid);
            grid_x_high = ceil(x_grid);
            xd =(grid_x_low == grid_x_high)?0.0:(x_grid-grid_x_low)/(grid_x_high-grid_x_low);
            
            z_val= ((row[bytesPerPixel*x+channel]-minP)/255.0)/rangeSample;
            grid_z_low = floor(z_val);
            grid_z_high = ceil(z_val);
            zd =(grid_z_low == grid_z_high)?0.0:(z_val-grid_z_low)/(grid_z_high-grid_z_low);
            
            c= newGrid[grid_y_low][grid_x_low][grid_z_low].intensity*(1-xd)*(1-yd)*(1-zd)+
                newGrid[grid_y_high][grid_x_low][grid_z_low].intensity*(1-xd)*yd*(1-zd)+
                newGrid[grid_y_low][grid_x_high][grid_z_low].intensity*(1-yd)*xd*(1-zd)+
                newGrid[grid_y_low][grid_x_low][grid_z_high].intensity*(1-yd)*(1-xd)*zd+
                newGrid[grid_y_high][grid_x_low][grid_z_high].intensity*yd*(1-xd)*zd+
                newGrid[grid_y_low][grid_x_high][grid_z_high].intensity*(1-yd)*xd*zd+
                newGrid[grid_y_high][grid_x_high][grid_z_low].intensity*yd*xd*(1-zd)+
                newGrid[grid_y_high][grid_x_high][grid_z_high].intensity*xd*yd*zd;
            
            row1[bytesPerPixel*x+channel]=floor(c*255.0)+minP;

        }
    }
}
    
//convolutions function
+(void) convolGrid:(gridCell***) newGrid  z:(int) z oldGrid:(gridCell ***)oldGrid sigmaSpatial:(double) sigmaSpatial sigmaRange:(double) sigmaRange
{
        double gaussian_val=0.0;
        double gaussian_weight=0.0;
        for(int i =0; i<gridHeight; ++i)
        {
            for(int j=0; j<gridWidth; ++j)
            {
                for(int k=0; k<z; ++k)
                {
                    gaussian_val=0.0;
                    gaussian_weight =0.0;
                    for(int dx =-1; dx<2 ; dx=dx+1)
                    {
                        if(!((i==0 && dx==-1)||(i==gridHeight-1 && dx==1)))
                        {
                            for(int dy =-1; dy<2; dy=dy+1)
                            {
                                if(!((j==0 && dy==-1)||(j==gridWidth-1 && dy==1)))
                                {
                                    for(int dz =-1; dz<2;++dz)
                                    {
                                        if(!((k==0 && dz==-1)||(k==z-1 && dz==1)))
                                        {
                                            double kernel = [self gaussianKernel:dx dy:dy dz:dz sigmaSpacial:sigmaSpatial sigmaRange:sigmaRange];
                                            gaussian_val += kernel * oldGrid[i+dx][j+dy][k+dz].intensity;
                                            
                                            gaussian_weight += kernel
                                             * ((double)oldGrid[i+dx][j+dy][k+dz].count);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    newGrid[i][j][k].intensity=gaussian_val/gaussian_weight;
                }
            }
        }
}
    
+(double) gaussianKernel:(int) dx dy:(int) dy dz:(int) dz sigmaSpacial:(double) sigmaSpacial sigmaRange: (double) sigmaRange
{
        double RSquared = ((dx*dx) + (dy*dy))/(sigmaSpacial*sigmaSpacial) + (dz*dz)/(sigmaRange* sigmaRange);
        return exp(-0.5*RSquared);
}

+(gridCell ***) makeGridChannel: (unsigned char*)rawData channel:(int) channel
{
    gridCell*** newGrid = [self initGrid:rawData channel:channel];
    double** normal = [self normalize:rawData channel:channel];
    double min = (double)[self minPixel:rawData channel:channel]/255.0;
    
    for(int i=0; i<height; ++i)
    {
        int row =(int)(round(i/(spaceSample+0.0)));
        for(int j=0; j<width; ++j)
        {
           
            int col = (int)(round(j/(spaceSample+0.0)));
            int z=(int)(round((normal[i][j]-min)/rangeSample));
            newGrid[row][col][z].intensity += normal[i][j];
            newGrid[row][col][z].count +=1;
            //NSLog([NSString stringWithFormat:@"placed values in %d, %d, %d\n", row, col, z]);
        }
    }
    return newGrid;
}

+(double **) normalize:(unsigned char*)rawData channel:(int) channel
{
    double** norm = (double**)(malloc(height*sizeof(double*)));
    for(int y=0; y<height; ++y)
    {
        unsigned char * row = &rawData[y*bytesPerRow];
        norm[y]=(double*)(malloc(width * sizeof(double)));
        for(int x=0; x<width;++x)
        {
            norm[y][x] = ((double)row[bytesPerPixel*x+channel])/255.0;
            //NSLog([NSString stringWithFormat:@"placed values in row: %d, col: %d, value: %0.3f, channel:%d\n", y, x, norm[y][x],channel]);
        }
    }
    
    return norm;
}

+(gridCell ***) initGrid: (unsigned char*)rawData channel:(int) channel
{
    gridCell*** bilate_grid = (gridCell***)(malloc(gridHeight * sizeof(gridCell**)));
    int E= ceil((([self maxPixel:rawData channel:channel] - [self minPixel:rawData channel:channel])/255.0)/rangeSample)+1;
    for (int y=0; y<gridHeight; ++y)
    {
        bilate_grid[y]=(gridCell**)(malloc(gridWidth * sizeof(gridCell*)));
        for(int x=0; x< gridWidth; ++x)
        {
            bilate_grid[y][x]=(gridCell*)(malloc(E* sizeof(gridCell)));
            for (int z=0; z<E; ++z)
            {
                bilate_grid[y][x][z].intensity=0.0f;
                bilate_grid[y][x][z].count=0;
                
            }
        }
    }
    return bilate_grid;
}

+(int) maxPixel:(unsigned char*)rawData channel:(int) channel
{
    int max = 0;
    for(int y=0; y<height; ++y)
    {
        unsigned char * row = &rawData[y*bytesPerRow];
        for (int x=0; x<width; ++x)
        {
            int temp_max = row[bytesPerPixel*x+channel];
            if (temp_max > max) {
                max = temp_max;
            }
        }
    }
    
    return max;
}
    
+(int) minPixel:(unsigned char*)rawData channel:(int) channel
    {
        int min = 255;
        for(int y=0; y<height; ++y)
        {
            unsigned char * row = &rawData[y*bytesPerRow];
            for (int x=0; x<width; ++x)
            {
                int temp_min = row[bytesPerPixel*x+channel];
                if (temp_min < min) {
                    min = temp_min;
                }
            }
        }
        
        return min;
    }
 
@end
