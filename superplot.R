# superplot.R
# template for generating a superplot 
# based on Lord (2020) doi: 10/1083/jcb.202001064

# Generates a superplot with t-test from a dataset containing replicates and 2 treatments.
# To use: 
# 1. Create a CSV file with a format following the sample data in the reference.
#   Each row is an observation (e.g. a cell measurement)
#   Columns are Replicate, Treatment (experimental groups), and your measurement of interest. Additional columns will be ignored.
#   The Treatment column might be given another name depending on the experiment -- e.g. Genotype
# 2. Substitute your own column and experimental group names within the script

# ---- Setup ----
require(ggplot2)
require(dplyr)
require(ggpubr) # for comparing means
require(ggbeeswarm)
require(tcltk) # for directory choosing

# ---- User selects the data file ----
datafile <- tk_choose.files(default = "", caption = "Select the data file",
                             multi = FALSE, filters = NULL, index = 1)
combined <- read.csv(datafile)

# ---- Calculate the average of each replicate within each treatment (these will be the big dots) ----

ReplicateAverages <- combined %>% 
  group_by(Treatment, Replicate) %>% 
  summarise(across(everything(), list(mean = mean))) %>% # each column name XYZ will become XYZ_mean 
  mutate(PixelRatio = PixelRatio_mean, .keep="unused") # substitute your measurement column name here
  #  mutate(Speed = Speed_mean, .keep="unused")

# ---- Create the plot ----

# For aes(), x is the column containing the experimental groups, and y is the measurement column
# stat_compare_means can be added to compute p values and show them on the plot.
# Methods are described in the documentation for ggpubr:compare_means


super <- ggplot(combined, aes(x=Treatment, y=PixelRatio, color=factor(Replicate))) + # y = your measurement column
  geom_beeswarm(cex=3) + scale_colour_brewer(palette = "Set1") +
  geom_beeswarm(data=ReplicateAverages, size=8) +
  #stat_compare_means(data=ReplicateAverages, 
  #                   comparisons = list(c("Control", "Drug")), 
  #                   method="t.test", paired=FALSE) +
  theme(legend.position="none")

# Show the plot on the plot window
print(super)

