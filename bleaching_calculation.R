# input: numerator, denominator, and pixelwise ratio csvs from the bleaching analysis macro
# output: 2 csvs: Absolute and Normalized (to t0) mean intensity and ratio over time. Column added for # exposures. 
# Assumptions:
# There are 3 CSV files, Results plus numerator and denominator, with Num and Denom in their names
# The files are in the same subdirectory
# 4 measurements (area, mean, intden, raw intden)
# Measure all slices, One row per slice
# Save row numbers (same as frame number)

# ---- Setup ----

require(tidyverse) # for data processing
require(stringr) # for string harvesting
require(tcltk) # for directory choosing

ZSteps <- 13 # replace with the # of z steps in each timepoint. Used to calculate # exposures

# ---- User opens the three results files ----

datafiles <- tk_choose.files(default = "", caption = "Use Ctrl-click to select ALL THREE results files",
                             multi = TRUE, filters = NULL, index = 1)
datadir <- dirname(datafiles)[1] # IMPORTANT select just one of the directories (they are the same)
# note if datadir was not reduced to 1 element, it would read the table multiple times into the same dataframe!

datanames <- basename(file.path(datafiles)) # file names without directory names

# read the files

measfile <- datanames[grepl("_Results", datanames)]
meas <- read_csv(file.path(datadir, measfile))

numfile <- datanames[grepl("Num", datanames)]
nummeas <- read_csv(file.path(datadir,numfile)) 

denomfile <- datanames[grepl("Denom", datanames)]
denommeas <- read_csv(file.path(datadir,denomfile)) 

# ---- Get data info ----

# based on our data assumptions, the number of ROIs is (cols - 2)/4
numROIs <- (ncol(nummeas) - 2)/4

# ---- Select the columns containing image name, mean intensity ----

meas <- meas %>% select(1,contains("Mean"))
nummeas <- nummeas %>% select(1,2,contains("Mean"))
denommeas <- denommeas %>% select(1,contains("Mean"))

# ---- Rename the columns to match the type of source image ----
# preserve label in numerator table only

meas <- meas %>% rename_with( ~ paste0("Ratio_", .x), contains("Cell"))
nummeas <- nummeas %>% rename_with( ~ paste0("Num_", .x), contains("Cell"))
denommeas <-denommeas %>% rename_with( ~ paste0("Denom_", .x), contains("Cell"))

# ---- Create a column for the # of exposures 

expos <- seq(1, nrow(meas)*ZSteps, ZSteps)
nummeas <- nummeas %>% mutate(exposures = expos) %>% relocate(exposures, .after = Label)

# ---- Collect the absolute values in one table
# ---- First ratio, then num, then denom for all cells in sequence within each type of value

numdenommeas <- inner_join(nummeas, denommeas, by=NULL)
allmeas <- inner_join(numdenommeas, meas, by=NULL)

# ---- Calculate the values normalized to time 0 ----

normalize <- function(x, na.rm = FALSE) (x/x[1])
allmeas_norm <- allmeas %>% mutate_at(vars(matches("Cell")), normalize)

# ---- Save CSVs ----

# User selects the output directory

# ---- User chooses the output folder ----
outputDir <- tk_choose.dir(default = "", caption = "Please OPEN the output folder") # prompt user
nameLength <- nchar(basename(measfile)) - 4
outputRaw = paste(substring(basename(measfile),1,nameLength),"_Raw.csv")
outputNorm = paste(substring(basename(measfile),1,nameLength),"_Norm.csv")
write_csv(allmeas,file.path(outputDir, outputRaw))
write_csv(allmeas_norm,file.path(outputDir, outputNorm))



