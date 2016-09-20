rm(list=ls())

library(dplyr)
library(readxl)

# Specify inputs
# --------------
baseDir <- "C:/KPONEIL/sideProjects/visualizationMaps/stanleySections"


# Process Raw
# -----------
raw <- read_excel(paste0(baseDir, "/tables/raw/wet widths.xls"), 
                    sheet = 1, 
                    col_names = TRUE, 
                    col_types = NULL, 
                    na = "", 
                    skip = 0)                            

st <- raw[,c("sample", "Branch", "Section", "mean width")]

names(st) <- c("sample", "branch", "section", "width")

# Fix section numbers to be unique
st$section[which(st$branch == "EAST" & st$section == 34)] <- 51
st$section[which(st$branch == "EAST" & st$section == 35)] <- 52
st$section[which(st$branch == "EAST" & st$section == 36)] <- 53

# Add season
st$season <- NA
st$season[which(st$sample%%2==0)] <- "fall"
st$season[which(st$sample%%2!=0)] <- "spring"


# Calculate Averages
# ------------------
# Annual
annual <- group_by(st, section) %>%
          summarise(width = mean(width, na.rm = T)) 

annual$season <- "annual"

# Spring/fall
seasonal <- group_by(st, section, season) %>%
           summarise(width = mean(width, na.rm = T))

widths <- reshape(as.data.frame(rbind(annual, seasonal)), 
                  idvar = "section", 
                  timevar = "season", 
                  direction = "wide")

names(widths) <- c("section", "annual", "fall", "spring")


# Output
# ------
write.csv(widths, 
          file = paste0(baseDir, "/tables/processed/averageWidths.csv"),
          row.names = F)