## read gfw api key

gfw_api_key <- read.delim("/home/ubuntu/data_storage/raw_data/global_fishing_watch/gfw_api_key.txt") %>%
  colnames() %>%
  unique()


# usethis::edit_r_environ()