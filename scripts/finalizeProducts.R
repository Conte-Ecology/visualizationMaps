# Description
# -----------
# Project: Visualization Maps

# This script formats the output tables from the "linearReferencing.py" into 
#   one CSV file.


# Libraries
# ---------
rm(list=ls())

# Libraries
library(foreign)


# Specify inputs
# --------------
# Filepath to the project directory
baseDir <- "C:/KPONEIL/visualizationMaps/stanleySections"

# Output ID
projectID <- "stanley"


# Define directories
# ------------------
# Linear referencing tables
spatialDir <- paste0(baseDir, "/spatial/linearReferencing.gdb")

# Output directory
productDir <- paste0(baseDir, "/products")
if (!file.exists(productDir)){
  dir.create(file.path(productDir))  
}


# Process files
# -------------
allFiles <- ogrListLayers(spatialDir)

files <- allFiles[ -which(allFiles == "routes")]

for (i in seq_along(files)){
    
  inTable <- readOGR(spatialDir,files[i])@data
    
  if(!"sample_name" %in% colnames(inTable)){
    inTable$sample_name <- NA
  }
  
  inTable <- inTable %>%
    select(id, 
           section = `section_`, 
           latitude, 
           longitude, 
           line_meas, 
           sample_name, 
           offset)%>%
    mutate(section = as.character(section))
   
  inTable$description <- files[i]

  if(!exists("outTable")){
    outTable <- inTable
  }else{
    outTable <- rbind(outTable, inTable)
  }
}


# Output
# ------
write.csv(outTable, 
          file = paste0(productDir, "/", projectID, "_section_locations.csv"), 
          row.names = F)

