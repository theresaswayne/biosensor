# process_multiROI_tables.R
# calculate data from multimeasure tables

# ---- Setup ----

require(tidyverse) # for reading and parsing, lead/lag
require(tcltk) # for file choosing

# ---- User opens a single results file ----

datafile <- file.choose() # opens a file chooser window

# read the data into a file
meas <- read_csv(file.path(datafile)) # errors result, but seems ok

# Assumptions:
# 4 measurements (area, mean, intden, raw intden)
# Measure all slices, One row per slice
# Save row numbers (same as slice number)
# Therefore the number of ROIs is (cols - 2)/4

# find how many ROIs there are
numROIs <- (ncol(meas) - 2)/4
print(numROIs)

# get the sums of all the ROI columns

meas_sums <- meas %>%
  summarise(across(contains("ROI"), 
                   list(sum = sum), na.rm=TRUE))

# TODO: Collect the sums of relevant columns into rows
# Cols: Label, ROI, Area sum, IntDen sum

# Then compute a new column with the ratio
# Then save the new table

# Then adapt the same idea to take 2 inputs (Num and Denom)
# Calculate appropriately



