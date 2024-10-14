## Summary

Repository for spatializing country-level fishing effort data from [Rousseau et al., 2024](https://metadata.imas.utas.edu.au/geonetwork/srv/eng/catalog.search#/metadata/1241a51d-c8c2-4432-aa68-3d2bae142794) to grid cells, based on [observed Global Fishing Watch data](https://globalfishingwatch.org/data-download/datasets/public-fishing-effort) (a top-down approach). 

In this repository we spatialise country-level fishing effort data to grid cells, based on real data from Global Fishing Watch. To do this, we will adopt two approahces: 

### Approach one 

Allocate country-level fishing effort to cells based on proportion of fishing effort represented in each cell in global fishing watch data. 
 - We have IMAS country data with effort for year (1950-2017), flag country, gear type, and vessel length 
 -We have  Global fishing watch spatialised effort for year (2012-2023), flag country, gear type, and vessel length
     - Group by year, flag country, gear type, and vessel length and calculate in each cell the proportion of that categories effort represented
 - Join the grouped global fishing watch data to the IMAS effort data
 - Multiply the total effort from IMAS by the proportions in each cell from GFW
 - This results in a dataframe that shows the effort from IMAS allocated to GFW cells, proportionally. 

However, this methodology does not comprehensively map the IMAS effort data. There are some country, gear, and vessel length categories that are represented in the IMAS data that are not in the GFW data, and this method really only works "well" for the industrial sector, as the GFW data mostly has coverage from AIS reporting vessels, which are predominately industrial vessels. Given this, we will need to apply an additional gap-filling step.

We could use the model developed in [McDonald et al., 2024](https://www.pnas.org/doi/10.1073/pnas.2400592121) to fill in any missing effort AFTER applying the proportional allocation methodology. We will have to adjust the model to be split by gear and vessel length. 


### Approach two

Instead of first applying the proportional allocation approach, we just simply apply the model from McDonald et al., 2024 from the start to spatilise the country-level effort. 



## Data sources 

**Reference**
[McDonald et al., 2024: Global expansion of marine protected areas and the redistribution of fishing effort](https://www.pnas.org/doi/10.1073/pnas.2400592121#data-availability)
 - https://zenodo.org/records/11625791
 - https://github.com/emlab-ucsb/mpa-fishing-effort-redistribution/tree/v1.0
 
 **Downloaded**: October 1, 2024
 
 **Description**: All code and data necessary to reproduce the study linked above. 

 - They provide all of the necessary R code AND pre-processed spatial files for the model! This means we don't necessarily need to download and rerun all of the model features they include. The github repository linked has an extensive README describing how to use their data for reproduction. 
 - We can use all of this information to run the same (or a similar) model to predict fishing effort.
 
 
### Global Fishing Watch

**Reference**:
1. Global Fishing Watch. [2024]. www.globalfishingwatch.org\
2. [`gfwr` API](https://github.com/GlobalFishingWatch/gfwr)

**Downloaded**: October 1, 2024

**Description**: API to extract apparent fishing effort within global EEZ's. We extract by vessel ID so that we can get the vessel characteristics gear type and length. 

**Native data resolution**: 0.01 degree

**Time range**: 2012 - 2023

**Format**:  API version 3


## File structure

### 'prep' folder

The prep folder contains all code necessary to generate the newly spatialised fishing effort database.

All scripts are numbered by the order in which they should be run. Within the prep folder, there are multiple folders, which have their own descriptions. 

### 'R' folder

Contains reference scripts 'dir.R', 'api_keys.R', and 'spatial_files.R', which hold regularly used directory file paths and functions. These are sourced within markdown scripts when needed. `spatial_files.R` mostly creates reference spatial files that are used throughout the analysis. 

### 'data' folder

The data folder is divided into a number of subfolders, each with their own sub directories. The main sub directories within the data folder are listed below.
 
| Folder | Description|
|:---------|:------------|
| raw_data | This folder contains a number of sources of raw data needed for the analysis. This often not the raw product per se, it may be tidied, but it is not a data product |
| int | This folder contains a number of intermediate data products that are used in the markdown files, and are necessary for reproduction |
| model_features | Processed versions of raw data sets used in McDonald et al., 2024 |


