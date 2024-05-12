library(tidyr)
library(tidyverse)
library(dplyr)

# Load the data
streamer = read.csv("streamer_information_cleaned.csv")
recomm = read.csv("recomm_streams_cleaned.csv")
top = read.csv("top_category_cleaned.csv")
gambling = read.csv("gambling_category_cleaned.csv")

# Summarizing the data
# Streamer information
summary(streamer)
colSums(is.na(streamer))
sd(streamer$Viewercount)

streamers = sort(table(streamer$Streamer_Secret), decreasing = TRUE)
length(streamers)

languages = sort(table(streamer$Language), decreasing = TRUE)
languages

category = sort(table(streamer$Subcategory), decreasing = TRUE)
category

mean_viewercount <- aggregate(Viewercount ~ Streamer_Secret, data = streamer, FUN = mean)
mean(mean_viewercount$Viewercount)
sd(mean_viewercount$Viewercount)

mean_category <- aggregate(Viewercount ~ Subcategory, data = streamer, FUN = mean)
View(mean_category)
mean(mean_category$Viewercount)
sd(mean_category$Viewercount)

# Recommended streams
summary(recomm)
colSums(is.na(recomm))
sd(recomm$Viewercount)

streamers = sort(table(recomm$Streamer_Secret), decreasing = TRUE)
length(streamers)

category = sort(table(recomm$Category), decreasing = TRUE)
category

mean_viewercount <- aggregate(Viewercount ~ Streamer_Secret, data = recomm, FUN = mean)
mean(mean_viewercount$Viewercount)
sd(mean_viewercount$Viewercount)

mean_category <- aggregate(Viewercount ~ Category, data = recomm, FUN = mean)
View(mean_category)
mean(mean_category$Viewercount)
sd(mean_category$Viewercount)

# Top category
summary(top)
colSums(is.na(top))
sd(top$Viewercount)

category = sort(table(top$Category), decreasing = TRUE)
category

subcategory = sort(table(top$Subcategory), decreasing = TRUE)
subcategory

mean_category <- aggregate(Viewercount ~ Category, data = top, FUN = mean)
View(mean_category)
mean(mean_category$Viewercount)
sd(mean_category$Viewercount)

mean_subcategory <- aggregate(Viewercount ~ Subcategory, data = top, FUN = mean)
View(mean_subcategory)
mean(mean_subcategory$Viewercount)
sd(mean_subcategory$Viewercount)

# Gambling category
summary(gambling)
colSums(is.na(gambling))
sd(gambling$Viewercount)

category = sort(table(gambling$Subcategory), decreasing = TRUE)
category

mean_category <- aggregate(Viewercount ~ Subcategory, data = gambling, FUN = mean)
View(mean_category)
mean(mean_category$Viewercount)
sd(mean_category$Viewercount)

#graph for missing observations in streamer_info
collection_frequency <- streamer %>%
  group_by(timestamp_of_extraction) %>%
  mutate(group_numeric = group_indices()) %>%
  ungroup() %>%
  count(group_numeric, timestamp_of_extraction) %>%
  rename(count_group_numeric = n)


ggplot(collection_frequency, aes(x = group_numeric, y = count_group_numeric, fill = cut(count_group_numeric, breaks = c(-Inf, 9, 24, Inf), labels = c("Red", "Orange", "Green")))) +
  geom_col() + 
  scale_fill_manual(values = c("Red" = "red", "Orange" = "orange", "Green" = "green")) +
  theme(legend.position = "none", panel.grid = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x = "Timestamp of Extraction", y = "Count of group_numeric")

#graph for gambling category viewer patterns

ggplot(data = gambling, aes(x = timestamp_of_extraction, y = Viewercount, color = as.factor(Subcategory))) + 
  geom_col() +  # Use geom_col() for bar chart
  theme_minimal() +
  theme(legend.position = "none", panel.grid = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1)) +  # Rotate x-axis labels
  labs(x = "Timestamp of Extraction", y = "Viewercount") +  # Adjust axis labels 
  facet_wrap(~as.factor(Subcategory), scales ="free", ncol = 5)

#for all the other plots please see the shinny web application.
