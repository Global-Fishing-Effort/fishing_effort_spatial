library(gfwr)
library(terra)
library(tidyverse)
library(here)
library(glue)
library(data.table)
library(sf)
library(fasterize)
library(raster)
library(qs)

source(here("R/dir.R"))
## need to get a raster with EEZ names, so we can group by EEZ, flag country, vessel length, gear type 

# Define the extent for the raster (for example, global extent)
xmin <- -180
xmax <- 180
ymin <- -90
ymax <- 90

# Create an empty SpatRaster with 0.1-degree resolution
raster_empty <- rast(
  ncol = 3600, 
  nrow = 1800, 
  xmin = xmin, xmax = xmax, 
  ymin = ymin, ymax = ymax
  #, 
  # crs = "EPSG:4326"
)

# Initialize the raster values to NA (or 0 if you prefer)
values(raster_empty) <- NA

writeRaster(raster_empty, here("raw/spatial/empty_rast_0.1.tif"), overwrite = TRUE)

## 0.1 res 

## read in shapefile

# World polygons from the maps package
world_shp <- sf::st_as_sf(maps::map("world", plot = FALSE, fill = TRUE))

# Load EEZ polygons
eezs <- st_read(file.path(rdsi_raw_dir, "marine_regions/World_EEZ_v12_20231025"), layer = 'eez_v12') #%>% 
#  filter(POL_TYPE == '200NM') %>% # select the 200 nautical mile polygon layer
# vect()

test <- st_as_sf(eezs) %>% st_drop_geometry() %>%
  dplyr::select(MRGID, MRGID_SOV1, TERRITORY1, ISO_TER1, SOVEREIGN1, ISO_SOV1, GEONAME) %>%
  add_row(MRGID = 99999, MRGID_SOV1 = 99999, TERRITORY1 = NA, ISO_TER1 = NA, SOVEREIGN1 = "High seas", ISO_SOV1 = "HSX", GEONAME = "High seas region") %>%
  add_row(MRGID = 999999, MRGID_SOV1 = 999999, TERRITORY1 = NA, ISO_TER1 = NA, SOVEREIGN1 = "Land", ISO_SOV1 = "LND", GEONAME = "Land region")

write.csv(test, here("raw/spatial/eez_lookup.csv"), row.names = FALSE)

## get regions IDs

## rasterize to 0.1 by 0.1, using MRGID column (this is the ID for territory EEZs)

eez_rast <- fasterize::fasterize(eezs, raster(raster_empty), field = "MRGID")
eez_rast

eez_rast[is.na(eez_rast)] <- 99999 # save a value high seas, not if rousseau has that in there..
eez_rast <- mask(rast(eez_rast), vect(world_shp), inverse = TRUE) # mask out any land 
eez_rast[is.na(eez_rast)] <- 999999 # save a value land, not if rousseau has that in there..


writeRaster(eez_rast, here("raw/spatial/eez_id_rast.tif"), overwrite = TRUE)


## get x, y lookup table so we can join to the raw mmsi data when saving and have the EEZ id already saved in the csv 

eez_lookup <- eez_rast %>%
  as.data.frame(xy = TRUE) %>%
  rename(mrgid = layer) %>%
  # mutate(x = round(x, 1), y = round(y, 1))
  mutate(x = ifelse(x > 0, ceiling(x * 10) / 10, floor(x * 10) / 10),
         y = ifelse(y > 0, ceiling(y * 10) / 10, floor(y * 10) / 10))

eez_check <- eez_lookup %>%
  mutate(x_int = floor(x), y_int = floor(y)) %>%  # extract integer part of x and y
  group_by(x_int, y_int) %>%
  summarise(x_unique_decimals = n_distinct(x), 
            y_unique_decimals = n_distinct(y)) %>%
  ungroup()

# Check for any integers that do not have exactly 10 decimal versions
missing_decimals <- eez_check %>%
  filter(x_unique_decimals != 10 | y_unique_decimals != 10) # 0 rows - perfect! 

test <- eez_lookup %>%
  filter(is.na(mrgid)) # ok no NAs in mrgid that's good
# is it really supposed to have 6.4 million cells? Yes. 

test_flk <- eez_lookup %>%
  filter(mrgid == 8389)

qs::qsave(eez_lookup, here("raw/spatial/eez_rast_csv.qs"))
## every point i've looked up seems right... 