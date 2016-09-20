# Description
# -----------
# Project: Visualization Maps
#
# This script accesses the "westbrook" database on osensei along with a 
#   flowlines spatial layer created in accordance with the project description. 
#   Events tables are generated for mapping the sections in the spatial 
#   processing step.


# Libraries
# ---------
rm(list=ls())

# Libraries
library(dplyr)
library(rgdal)
library(RPostgreSQL)
library(lubridate)


# Specify inputs
# --------------
# Filepath to the GitHub directory
baseDir <- "C:/KPONEIL/visualizationMaps/westbrookSections"

# Database credentials
user <- "tom-bombadil"
password <- "oneringtorulethemall"


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


# Load data
# ---------
# Antennae deployment inforemation
antennae <- dbReadTable(wbConnect, "antenna_deployment") %>%
              mutate(deployed = as.Date(deployed),
                     removed = as.Date(removed)) %>%
              filter(section != "confluence") %>%   
              select(river, section, river_meter, deployed, removed)  

# Sample dates
samples <- dbReadTable(wbConnect, "data_seasonal_sampling") %>%
             filter(drainage == "west") %>%
             mutate(date = as.Date(median_date),
                    sample_name = as.numeric(sample_name)) %>%
             select(river, date, sample_name) %>%
             arrange(date)

# Downstream confluences
confluences <- dbReadTable(wbConnect, "data_sites") %>%
                 filter(drainage == "west" & section == "confluence") %>%
                 distinct(river, confluence_river_meter) %>%
                 select(river, confluence_river_meter)

# Stream segment lengths
flowlines <- readOGR(paste0(baseDir, "/spatial/source.gdb"), 
                     "flowlines")@data %>%
               mutate(river = as.character(river))

# Close the connection
dbDisconnect(wbConnect)


# Date Assigning
# --------------
antLocs <- left_join(antennae, samples, by = "river") %>%
             mutate(inside = date %within% interval(deployed, removed)) %>%
             filter(inside == TRUE)


# Sites Processing
# ----------------
# Index mainstem sections (ordered by confluence river meter)
wbCross <- filter(flowlines, river == "west brook") %>%
             arrange(desc(confluence_river_meter))

# Assign conlfuences
sections <- antLocs %>% 
              left_join(confluences, by = "river") %>%
              mutate(confluence_river_meter = ifelse(river == "west brook" & 
                       river_meter > wbCross$confluence_river_meter[1], 
                       wbCross$confluence_river_meter[1],
                     ifelse(river == "west brook" & 
                       river_meter > wbCross$confluence_river_meter[2] & 
                       river_meter < wbCross$confluence_river_meter[1], 
                       wbCross$confluence_river_meter[2],
                     ifelse(river == "west brook" & 
                       river_meter > wbCross$confluence_river_meter[3] & 
                       river_meter < wbCross$confluence_river_meter[2], 
                       wbCross$confluence_river_meter[3],
                     ifelse(river == "west brook" & 
                       river_meter < wbCross$confluence_river_meter[3], 
                       wbCross$confluence_river_meter[4], confluence_river_meter)
                     ))))

# Add information to sections and calculate positions along stream segments. 
#   The mouth segment of the westbrook is calculated differently.
#   Mainstem bank width is accounted for when calculating the tributary 
#   positions.
sites <- left_join(sections, 
                   flowlines[,c("id", 
                                "Shape_Length","river", 
                                "confluence_river_meter", 
                                "estimated_bank_offset")], 
                   by = c("river", "confluence_river_meter")) %>%
           mutate(line_meas = ifelse(river == "west brook" & 
                    river_meter < wbCross$confluence_river_meter[3],
                    wbCross$confluence_river_meter[3] - river_meter, 
                    Shape_Length - (river_meter - confluence_river_meter)),
                  line_meas = ifelse(river != "west brook",
                    line_meas - estimated_bank_offset, 
                    line_meas),
                  offset = 0)


# Output table
# ------------
outEvents <- select(sites, id, section, line_meas, sample_name, offset)

write.csv(outEvents, 
          paste0(eventsDir, "/antennae_locations.csv"),
          row.names = F)