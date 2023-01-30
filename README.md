# biosensor
Code for image analysis of ratiometric biosensors

# This repository contains scripts to facilitate analysis of mitochondrially targeted biosensors using Fiji/ImageJ and R. (Manuscript in preparation, 2023)

# The workflow is:
1. Analyze cells using a biosensor script:
Option 1: Biosensor.ijm to correct for bacgrkund and noise using measured image areas or user-supplied fixed values, or no subtraction. Methods for background and noise can be seleced ndependently.
Option 2: Biosensor-image-subtraction.ijm where background and noise are both handled by one of the following methods: 
  a. A blank image
  b. A user-selected area within the image
  c. A fixed value
  d. No background or noise correction.
  
 2. Collate data from multiple cells using process_all_multiROI_tables.R. This script will vclulate pixelwise and regionwise ratios from results opbtained ins tep 1.
 
 3. Generate color images using colorize_ratio_image.ijm. This script will produce intensity-modulated or unmodulated images with calbration bars, using ratio images obtained in step 1.
 
  
