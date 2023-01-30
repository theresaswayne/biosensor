# biosensor
Code for image analysis of ratiometric biosensors in yeast mitochondria

This repository contains scripts to facilitate analysis of mitochondrially targeted biosensors using Fiji/ImageJ and R. (Manuscript in preparation, 2023)

# Workflow
## 1. Pre-process, segment, and measure images.
Option 1: `biosensor.ijm`: Background and noise are corrected using measured image areas or user-supplied fixed values, or no subtraction. Methods for background and noise correction can be selected independently.

Option 2: `biosensor-image-subtraction.ijm` where background and noise are both handled by one of the following methods: 
  a. A blank image
  b. A user-selected area within the image
  c. A fixed value
  d. No background or noise correction.
  
## 2. Collate data from multiple cells.
The most versatile script is `process_all_multiROI_tables.R`. This R script will calculate both pixelwise and regionwise ratios from results obtained in step 1. The regionwise ratios are less sensitive to imaging noise.
 
## 3. Generate color images.
These images aid in the interpretation of ratio imaging results by converting ratio values to colors. Use the ImageJ script `colorize_ratio_image.ijm` to produce intensity-modulated or unmodulated images with calbration bars, using ratio images obtained in step 1.
  
