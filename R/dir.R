## Create filepaths for common directories
library(here)


git_prep <- here("prep")

rdsi_dir <- file.path("/home/ubuntu/data_storage")

imas_effort_dir <- file.path(rdsi_dir, "global_effort_data")

rdsi_raw_dir <- file.path(rdsi_dir, "raw_data")
