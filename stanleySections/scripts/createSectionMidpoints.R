# Description
# -----------
# Project: Visualization Maps

# This script accesses the "westbrook" database on osensei along with a 
#   flowlines spatial layer created in accordance with the project description. 
#   Events tables are generated for mapping the sections in the spatial 
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
# Sections
sections <- dbReadTable(wbConnect, "data_habitat") %>% 
  filter(drainage == "stanley") %>%
  distinct(river, section) %>% 
  select(river, sample_name, section)

# Streams
flowlines <- readOGR(paste0(baseDir, "/spatial/source.gdb"), 
                     "flowlines")@data %>% 
               mutate(river = as.character(river))

# Close the connection
dbDisconnect(wbConnect)


# Process
# -------
# Calculate the positions along the flowlines (determined by section length)
events <- left_join(sections, flowlines, by = "river") %>%
  group_by(river) %>%
  mutate(line_meas = Shape_Length - (section_length/2 + section_length*(section - min(section))),
         offset = 0) %>%
  ungroup() %>%
  select(id, section, line_meas, offset)


# Output
# ------
write.csv(events, 
          file = paste0(eventsDir, "/section_midpoints.csv"),
          row.names = F)