# Load rjson package
library(rjson)
library(tidyverse)

file_names <- c('top_category', 'streamer_information','gambling_category', 'recomm_streams')

for (file_name in file_names) {
    file_path <- paste0(file_name, ".json")
    json_data_list <- fromJSON(file = file_path)
    df <- as.data.frame(do.call(rbind, json_data_list))
    assign(file_name, df)
}

library(tidyr)

# Loop through each data frame and unnest all columns
for (file_name in file_names) {
  # Get the dataframe by variable name
  df <- get(file_name)
  
  # Unnest all list columns
  for (col_name in colnames(df)) {
    if (is.list(df[[col_name]])) {
      df <- unnest(df, cols = !!sym(col_name))
    }
  }
  
  # Assign the modified dataframe back to the variable
  assign(file_name, df)
}


top_category <- top_category %>%
  rename(timestamp_of_extraction =`Timestamp of extraction`) 

# Loop through each data frame and format the timestamp column
for (file_name in file_names) {
  # Get the dataframe by variable name
  df <- get(file_name)
  
  # Check if the column is a character and convert it to POSIXct if necessary
  if ("timestamp_of_extraction" %in% colnames(df)) {
    df$timestamp_of_extraction <- as.POSIXct(df$timestamp_of_extraction, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  }
  
  # Assign the modified dataframe back to the variable
  assign(file_name, df)
}

# Loop through each data frame

gambling_category <- gambling_category %>%
  separate(Viewercount, into = c("Viewercount", "second_part"), sep = " ") %>%
  select(-second_part) %>%
  mutate(dummy = if_else(grepl("K", Viewercount), 1, 0)) %>%
  mutate(Viewercount = if_else(grepl("K", Viewercount), gsub("K", "", Viewercount), Viewercount)) %>%
  mutate(Viewercount = as.numeric(Viewercount),
         Viewercount = if_else(dummy == 1, Viewercount * 1000, Viewercount)) %>%
  select(-dummy)

top_category <- top_category %>%
  separate(Viewercount, into = c("Viewercount", "second_part"), sep = " ") %>%
  select(-second_part) %>%
  mutate(dummy = if_else(grepl("K", Viewercount), 1, 0)) %>%
  mutate(Viewercount = if_else(grepl("K", Viewercount), gsub("K", "", Viewercount), Viewercount)) %>%
  mutate(Viewercount = as.numeric(Viewercount),
         Viewercount = if_else(dummy == 1, Viewercount * 1000, Viewercount)) %>%
  select(-dummy)

recomm_streams <- recomm_streams %>%
  mutate(dummy = if_else(grepl("K", Viewercount), 1, 0)) %>%
  mutate(Viewercount = if_else(grepl("K", Viewercount), gsub("K", "", Viewercount), Viewercount)) %>%
  mutate(Viewercount = as.numeric(Viewercount),
         Viewercount = if_else(dummy == 1, Viewercount * 1000, Viewercount)) %>%
  select(-dummy)

streamer_information <- streamer_information %>%
  mutate(dummy = if_else(grepl("K", Viewercount), 1, 0)) %>%
  mutate(Viewercount = if_else(grepl("K", Viewercount), gsub("K", "", Viewercount), Viewercount)) %>%
  mutate(Viewercount = as.numeric(Viewercount),
         Viewercount = if_else(dummy == 1, Viewercount * 1000, Viewercount)) %>%
  select(-dummy)

gambling_category <- gambling_category %>%
  mutate(across(c(Subcategory), as.factor))

recomm_streams <- recomm_streams %>%
  mutate(across(c(Streamer_Secret,Category), as.factor))

streamer_information <- streamer_information %>%
  mutate(across(c(Streamer_Secret,Subcategory,Language),as.factor))

top_category <- top_category %>%
  mutate(across(c(Category,Subcategory),as.factor))

data_sets <- c('gambling_category', 'recomm_streams', 'streamer_information', 'top_category')

dir.create("../../data/data_cleaned.csv")

for (set in data_sets) {
  write_csv(get(set), paste0("../../data/data_cleaned.csv/", set, "_cleaned.csv"))
}