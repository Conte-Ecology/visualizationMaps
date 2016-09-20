# Description
# -----------
# Project: Visualization Maps

# This script accesses the "westbrook" database on osensei along with a 
#   flowlines spatial layer created in accordance with the project description. 
#   Events tables are generated for mapping the section widths in the spatial 
#   processing step.


# Libraries
# ---------
rm(list=ls())

library(dplyr)
library(rgdal)
library(RPostgreSQL)


# Specify inputs
# --------------
# Filepath to the project directory
baseDir <- "C:/KPONEIL/visualizationMaps/stanleySections"


# Database credentials
user <- "tom-bombadil"
password <- "oneringtorulethemall"
user <- "kyle"
password <- "ironcurtainsalamander"

# Define directories
# ------------------
# Tables directory
tablesDir <- paste0(baseDir, "/tables")
if (!file.exists(tablesDir)){
  dir.create(file.path(tablesDir))  
}

# Output directory
eventsDir <- paste0(tablesDir, "/events")
if (!file.exists(eventsDir)){
  dir.create(file.path(eventsDir))  
}


# Database connection
# -------------------
wbConnect <- dbConnect(dbDriver("PostgreSQL"), 
                       dbname = "westbrook",
                       host = "osensei.cns.umass.edu", 
                       port = 5432,
                       user = user, 
                       password = password)

# Clear password
rm(password)


# Load Data
# ---------
# Width data
rawWidths <- dbReadTable(wbConnect, "data_habitat") %>% 
  filter(drainage == "stanley") %>%
  mutate(sample_name = as.numeric(sample_name)) %>%
  select(river, sample_name, section, width) 

# Streams
flowlines <- readOGR(paste0(baseDir, "/spatial/source.gdb"), 
                     "flowlines")@data %>% 
               mutate(river = as.character(river))

# Close the connection
dbDisconnect(wbConnect)


# Process data
# ------------
# Widths are measured at the start of each section, so the mean of the current 
#   and next up is taken to get the midpoint width. The width of the last 
#   section of each reach is taken directly.
main <- left_join(rawWidths, flowlines, by = "river") %>%
  group_by(river) %>%
  mutate(line_meas = 
    Shape_Length - (section_length/2 + section_length*(section - min(section)))
    ) %>%
  group_by(sample_name, river) %>%
  arrange(section) %>%
  mutate(lead = lead(width),
         mean_width = ifelse(is.na(lead), width, (width + lead)/2)) %>%
  ungroup()


# Process and output
# ------------------
for (s in unique(main$sample_name)){

  # Positive offset
  outPos <- main %>%
    filter(sample_name == s) %>%
    mutate(offset = mean_width/2) %>%
    select(id, section, line_meas, sample_name, offset) %>%
    na.omit()

  # Negative offset
  outNeg <- main %>%
    filter(sample_name == s) %>%
    mutate(offset = - mean_width/2) %>%
    select(id, section, line_meas, sample_name, offset) %>%
    na.omit()
  
  # Write out positive and negative offset tables
  write.csv(outPos, 
            file = paste0(eventsDir, "/sample_", s, "_widths_pos.csv"),
            row.names = F)
  
  write.csv(outNeg, 
            file = paste0(eventsDir, "/sample_", s, "_widths_neg.csv"),
            row.names = F)
}
