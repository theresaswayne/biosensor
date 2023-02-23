# biosensor
Code for image analysis of ratiometric biosensors

## Purpose

This repository contains scripts to facilitate analysis of mitochondrially targeted ratiometric biosensors using Fiji/ImageJ and R. (Manuscript in preparation, JoVE, 2023)

## ImageJ macros for biosensor ratio image calculation and analysis

The biosensor macros take a Z-stack multichannel image as input, and produce a background-corrected, masked ratio image, as well as measurements of user-selected areas and a log file. There are 2 macros with different options for correction of noise nad background. Noise calculation is used to supplement the thresholding step.

### biosensor.ijm
Macro with basic background and noise correction. Background and noise are corrected using measured image areas, user-supplied fixed values, or no subtraction. Methods for background and noise correction can be selected independently.

### biosensor-image-subtraction.ijm
ImageJ macro supporting the following methods for background and noise correction:
  1. Blank image
  1. User-selected area within the image
  1. Fixed value
  1. No correction.
In this macro, background and noise are both handled by the same user-selected method.

## Supporting scripts

### colorize_ratio_image.ijm

This ImageJ macro takes a masked ratio image as input, and generates a colorized image with calibration bar for easier interpretation of the values. The user can set the intensity range for optimal contrast and accurate comparison of images.

Two options are available for colorization: 
* Unmodulated image. In this case, the color image intensity is at the maximum for each pixel, and the color scheme can be chosen by the user.
* Intensity-modulated image. In this case, the user also supplies the original fluorescence image, and the colorized image intensity is set from the intensities in the original image. This cam produce a more appealing result, because pixels with less signal in the original image are less prominent in the colorized image.

### process_multiROI_tables.R

This R script will calculate both pixelwise and regionwise ratios from results obtained in step 1. The regionwise ratios are less sensitive to imaging noise.

### bleaching_analysis.ijm

This ImageJ macro measures change in biosensor intensity over time. It can be used to help optimize imaging conditions to avoid photobleaching. The input is a multichannel time-lapse image (Z stack or single slice). The output is a table of measurements of each channel over time.

### bleaching_calculation.R

This R script will 

## Sample data

For each script, sample input files and output files are supplied.
