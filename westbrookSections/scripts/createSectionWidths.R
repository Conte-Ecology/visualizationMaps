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

# Libraries
library(dplyr)
library(rgdal)
library(RPostgreSQL)


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


# Load Data
# ---------
# Widths
rawWidths <- dbReadTable(wbConnect, "data_habitat") %>% 
               filter(drainage == "west" & is.na(quarter)) %>%
               select(river, sample_name, section, width) %>%
               mutate(sample_name = as.numeric(sample_name))

# Sample dates
samples <- dbReadTable(wbConnect, "data_seasonal_sampling") %>%
             filter(drainage == "west") %>%
             mutate(date = as.Date(median_date)) %>%
             mutate(sample_name = as.numeric(sample_name)) %>%
             select(river, date, sample_name) %>%
             arrange(date)

# Streamflow record
flow <- dbReadTable(wbConnect, "data_daily_discharge") %>%
          filter(date %in% samples$date) %>%
          select(date, river, discharge)

# Section locations      
rawSites <- dbReadTable(wbConnect, "data_sites") %>% 
              filter(drainage == "west" & 
                     area %in% c("trib", "inside") & 
                     is.na(quarter)) %>%
              select(river, section, river_meter, confluence_river_meter)

# Stream segment lengths
flowlines <- readOGR(paste0(baseDir, "/spatial/source.gdb"), 
                     "flowlines")@data %>%
               mutate(river = as.character(river))

# Close the connection
dbDisconnect(wbConnect)


# Flow/width model
# ----------------
# Link streamflow to width measurements
allWidths <- left_join(rawWidths, samples, by = c("river", "sample_name")) %>%
               left_join(., flow, by = c("date", "river")) %>%
               filter(!is.na(section))

# River-section combinations
combos <- unique(allWidths[,c("river", "section")])

# Loop through individual sections
for (i in 1:nrow(combos)){

  # Index section
  riverSection <- filter(allWidths, river == combos$river[i] & 
                    section == combos$section[i])

  # River-section model
  model <- lm(width ~ discharge, riverSection)
  
  riverSection$widthPred <- predict(model, riverSection)
  
  # Output prediction 
  if(!exists("predWidths")){ 
    predWidths <- riverSection
  }else{predWidths <- rbind(predWidths, riverSection)}
}

# Fill in missing widths
widths <- mutate(predWidths,
            width = ifelse(is.na(width), widthPred, width))


# Sites Processing
# ----------------
# Index confluences
confluences <- filter(rawSites, section == "confluence")

# Index numbered sections
sections <- rawSites %>%
              mutate(section = as.numeric(section)) %>%
              filter(section > 0)

# Index mainstem sections (ordered by confluence river meter)
wbCross <- filter(flowlines, river == "west brook") %>%
             arrange(desc(confluence_river_meter))

# Assign conlfuences
sections <- mutate(sections, 
                   confluence_river_meter = ifelse(river == "west brook" & 
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
                    line_meas))


# Finalize Tables
# ---------------
# Master table (drop missing)
main <- left_join(widths, sites, by = c("river", "section")) %>%
          na.omit()

# Loop through samples
for (s in unique(main$sample_name)){
  
  # Index sample
  currentSample <- main %>%
                     filter(sample_name == s) %>%
                     select(id, section, line_meas, sample_name, width)
  
  # Calculate offsets
  outPos <- currentSample %>%
              mutate(offset = width/2) %>%
              select(id, section, line_meas, sample_name, offset)
  
  outNeg <- currentSample %>%
              mutate(offset = - width/2) %>%
              select(id, section, line_meas, sample_name, offset)
  
  # Write out positive and negative offset tables
  write.csv(outPos, 
            file = paste0(eventsDir, "/sample_", s, "_widths_pos.csv"),
            row.names = F)
  
  write.csv(outNeg, 
            file = paste0(eventsDir, "/sample_", s, "_widths_neg.csv"),
            row.names = F)
}
