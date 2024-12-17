# README

Repository for spatialising country-level fishing effort data from
[Rousseau et al.,
2024](https://metadata.imas.utas.edu.au/geonetwork/srv/eng/catalog.search#/metadata/1241a51d-c8c2-4432-aa68-3d2bae142794)
to grid cells, based on [observed Global Fishing Watch
data](https://globalfishingwatch.org/data-download/datasets/public-fishing-effort)
(a top-down approach).


In this repository we spatialise country-level fishing effort data to
grid cells, based on real data from Global Fishing Watch. To do this, we
will explore two approaches, and **ultimately choose the methodology of
approach 2**.

Please read this file before trying to reproduce the output from this research project. Below you will find information on the publication associated with this repository, contact information for the lead author, and a description of the repository structure with each section explained.

## Approach one

Allocate country-level fishing effort to cells based on proportion of
fishing effort represented in each cell in global fishing watch data. -
We have IMAS country data with effort for year (1950-2017), flag
country, gear type, and vessel length -We have Global fishing watch
spatialised effort for year (2012-2023), flag country, gear type, and
vessel length - Group by year, flag country, gear type, and vessel
length and calculate in each cell the proportion of that categories
effort represented - Join the grouped global fishing watch data to the
IMAS effort data - Multiply the total effort from IMAS by the
proportions in each cell from GFW - This results in a dataframe that
shows the effort from IMAS allocated to GFW cells, proportionally.

However, this methodology does not comprehensively map the IMAS effort
data. There are some country, gear, and vessel length categories that
are represented in the IMAS data that are not in the GFW data, so these aren't 
represented in this allocation. 

## Approach two

This model predicts the spatial distribution of fishing effort globally,
using environmental, spatial, and fleet-specific predictors to
distribute country-level fishing effort data across a global grid, using
a beta regression model (this is the model which is most appropriate for
predicting proportions).

### Model Structure

The model predicts the **proportion of fishing effort** in each grid
cell based on:

#### Categorical Predictors

-   Flag state (flag_fin)
-   Gear type (gear)
-   Sector
-   Vessel length category (length_category)
-   Mesopelagic zone (33 distinct regions) ([Sutton et al
    2017](<https://www.sciencedirect.com/science/article/pii/S0967063717301437>))
-   Exclusive Economic Zone (EEZ)
-   FAO major fishing area

#### Continuous Predictors

-   Total fishing hours (log-transformed?) for each
    flag/gear/sector/length combination
-   Location (longitude, latitude)
-   Distance measures:
    -   Distance from port (m)
    -   Distance from shore (m)
-   Environmental variables:
    -   Chlorophyll-A concentration (mean, sd) in mg/m³
    -   Sea surface temperature (mean, sd) in °C
    -   Wind speed (mean, sd) in m/s
-   Bathymetry (depth in m)
-   Year (ideally 1950-2017, however GFW data is only reliable from
    2015-2017, so we will train the model on that)

We estimate the amount of fishing effort in each cell by multplying the
total amount (per flag, gear, sector, and vessel length) by the
proportion in each cell (per those same categories).

### **Historical Predictions**

\
The model can be used to predict historical fishing effort distributions
under the following assumptions:

#### Key Assumptions: 

1.  The relationships between environmental conditions and fishing
    effort distribution are relatively stable over time

2.  The influence of total fishing effort on spatial distribution
    patterns remains consistent

3.  The basic responses of fish and fishers to environmental conditions
    are similar across decades

#### **Implementation Details**

-   Model is trained on 2015-2017 data (period of most reliable GFW
    data)

-   For historical predictions:

    -   Uses environmental data from the target year

    -   Uses IMAS total fishing effort from the target year

    -   Maintains the learned relationships between predictors and
        effort distribution

-   The total amount of fishing effort in each flag country is allocated
    to the proportional contribution as modeled. I.e., we estimate the
    amount of fishing effort in each cell by multiplying the total
    amount by the proportion value in each cell.

####  **Limitations**

Users should be aware that historical predictions may not capture:

-   Technological changes in fishing capabilities

-   Evolution of fishing strategies and practices

-   Changes in management regulations

-   Shifts in target species or fishing grounds due to socio-economic
    factors

## File structure

### 'prep' folder

The prep folder contains all code necessary to run the models and
generate the spatialised fishing effort data.

All scripts are numbered by the order in which they should be run.
Within the prep folder, there are multiple folders, which have their own
descriptions. Note: you can skip `02_approach_1_proportions` if you
don't want to run approach 1.

### 'R' folder

Contains reference scripts 'dir.R', 'api_keys.R', and 'spatial_files.R',
which hold regularly used directory file paths and functions. These are
sourced within markdown scripts when needed. `spatial_files.R` mostly
creates reference spatial files that are used throughout the analysis.

### 'data' folder

The data folder is divided into a number of subfolders, each with their
own sub directories. The main sub directories within the data folder are
listed below.

| Folder         | Description                                                                                                                                                         |
|:------------------------------|:---------------------------------------|
| raw_data       | This folder contains a number of sources of raw data needed for the analysis. This often not the raw product per se, it may be tidied, but it is not a data product |
| int            | This folder contains a number of intermediate data products that are used in the markdown files, and are necessary for reproduction                                 |
| model_features | Processed versions of raw data sets we will use for the model. All data stored here are processed to 0.5 by 0.5 degree cell sizes.                                  |


## Contact

Please direct any correspondence to Gage Clawson at `gage.clawson@utas.edu.au`

## Reproducibility

We strongly advocate for open and reproducible science. The code in this repository enables a use to recreate the results outlined in the above publication. There are a few important points to know/adhere to for the code to run smoothly:

 - The code must be run as an R project (unless you would like to recreate it in another language) - the code within relies on relative file paths from the project home folder. 
 - There is large data required throughout, that we do not include in this repository due to GitHub's large file size limits. Please follow any instructions to download this data that is contained in the scripts within the `prep` folder. All data used is freely accessible online. 

## Data sources

**Reference** [McDonald et al., 2024: Global expansion of marine
protected areas and the redistribution of fishing
effort](https://www.pnas.org/doi/10.1073/pnas.2400592121#data-availability) -
<https://zenodo.org/records/11625791> -
<https://github.com/emlab-ucsb/mpa-fishing-effort-redistribution/tree/v1.0>

**Downloaded**: October 1, 2024

**Description**: All code and data necessary to reproduce the study
linked above.

-   They provide all of the necessary R code AND pre-processed spatial
    files for the model! This means we don't necessarily need to
    download and rerun all of the model features they include. The
    github repository linked has an extensive README describing how to
    use their data for reproduction.
-   We can use all of this information to run the same (or a similar)
    model to predict fishing effort.

### Global Fishing Watch

**Reference**: 1. Global Fishing Watch. [2024].
www.globalfishingwatch.org\
2. [`gfwr` API](https://github.com/GlobalFishingWatch/gfwr)

**Downloaded**: October 1, 2024

**Description**: API to extract apparent fishing effort within global
EEZ's. We extract by vessel ID so that we can get the vessel
characteristics gear type and length.

**Native data resolution**: 0.01 degree

**Time range**: 2012 - 2023

**Format**: API version 3
