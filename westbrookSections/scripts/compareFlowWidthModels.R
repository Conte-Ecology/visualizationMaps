rm(list = ls())

library(RPostgreSQL)
library(readxl)
library(dplyr)



rawFolder <- "C:/KPONEIL/visualizationMaps/westbrookSections/tables/raw"

user <- "tom-bombadil"
password <- "oneringtorulethemall"


# Connect to the database
wbConnect <- dbConnect(dbDriver("PostgreSQL"), 
                 dbname = "westbrook",
                 host = "osensei.cns.umass.edu", 
                 port = 5432,
                 user = user, 
                 password = password)

# Clear password
rm(password)



data_sites
data_habitat



# ------
# Widths
# ------
#allWidths <- dbReadTable(wbConnect, "data_habitat") %>% 
#               filter(drainage == "west") %>%
#               select(river, sample_name, section, width)


# This will get dropped in favor of database read:
# ------------------------------------------------
# Westbrook
wbRaw <- read_excel(paste0(rawFolder, "/Habitat West Brook Edited.xlsx"), 
                          sheet = 1, 
                          col_names = TRUE, 
                          col_types = NULL, 
                          na = "", 
                          skip = 4)

wb <- filter(wbRaw, Location == -9999) %>%
      select(drainage = `Drainage`,
             river = `River`,
             sample_name = `Sample Num`,
             section = `Section`,
             width = `Quart Width`)

# Tributaries
tribsRaw <- read_excel(paste0(rawFolder, "/Habitat West Brook Edited.xlsx"), 
                         sheet = 2, 
                         col_names = TRUE, 
                         col_types = NULL, 
                         na = "", 
                         skip = 0)

tribs <- select(tribsRaw, drainage = `Drainage`,
         river = `River`,
         sample_name = `Sample Num`,
         section = `Section`,
         width = `Quart Width`)


allWidths <- rbind(wb, tribs)

# For joining purposes
allWidths$river <- tolower(allWidths$river)
allWidths$sample_name <- as.numeric(allWidths$sample_name)


# --------------
# Sampling Dates
# --------------
samples <- dbReadTable(wbConnect, "data_seasonal_sampling") %>%
  filter(drainage == "west") %>%
  mutate(date = as.Date(median_date)) %>%
  mutate(sample_name = as.numeric(sample_name)) %>%
  select(river, date, sample_name) %>%
  arrange(date)


# ----
# Flow
# ----
flowDis <- dbReadTable(wbConnect, "data_daily_discharge") %>%
             filter(date %in% samples$date) %>%
             select(date, river, discharge)

# Prediction (only for westbrook so use for all)
flowExt <- dbReadTable(wbConnect, "data_flow_extension") %>%
  mutate(date = as.Date(date)) %>%
  filter(date %in% samples$date) %>%
  select(date, qPredicted)



# Intitially, the "data_tagged_captures" table would be used to assign a date to 
#   the section sampled. This table however showed some different dates for 
#   identical sections. Upon discussing this with Matt, it was revealed that in 
#   some samples early on, the widths were all taken on the last day of the 
#   sample. In more recent samples, the widths are taken on the day that the 
#   particular section is sampled. For now, in order to avoid a complicated 
#   process of determining the sample date, the 

widths <- left_join(allWidths, samples, by = c("river", "sample_name")) %>%
               left_join(., flowDis, by = c("date", "river")) %>%
               left_join(., flowExt, by = c("date")) %>%
               filter(!is.na(section))


# Flow/width model
# ----------------

# River-section combinations
combos <- unique(widths[,c("river", "section")])

for (i in 1:nrow(combos)){

  # Index section
  riverSection <- filter(widths, river == combos$river[i] & 
                    section == combos$section[i])

  # River-section model
  modelDis <- lm(width ~ discharge, riverSection)
  modelExt <- lm(width ~ qPredicted, riverSection)
  
  riverSection$widthDis <- predict(modelDis, riverSection)
  riverSection$widthExt <- predict(modelExt, riverSection)
  
  
  # Output prediction 
  if(!exists("widthPreds")){ 
    widthPreds <- riverSection
  }else{widthPreds <- rbind(widthPreds, riverSection)}
}


# ------------------
# Comparison Metrics
# ------------------
library(hydroGOF)


metrics <- widthPreds %>%
  summarise(rmseDis = sqrt( sum( (widthDis - width)^2 , na.rm = TRUE ) / n() ),
            rmseExt = sqrt( sum( (widthExt - width)^2 , na.rm = TRUE ) / n() ), 
            nashDis = NSE(widthDis, width),
            nashExt = NSE(widthExt, width))

metricsGrouped <- widthPreds %>%
                   group_by(river, section) %>%
                   summarise(rmseDis = sqrt( sum( (widthDis - width)^2 , na.rm = TRUE ) / n() ),
                             rmseExt = sqrt( sum( (widthExt - width)^2 , na.rm = TRUE ) / n() ), 
                             nashDis = NSE(widthDis, width),
                             nashExt = NSE(widthExt, width),
                             rmseComp = rmseDis - rmseExt,
                             nashComp = nashDis - nashExt)


length(which(metricsGrouped$rmseDis < metricsGrouped$rmseExt))
length(which(metricsGrouped$nashDis > metricsGrouped$nashExt))
length(which(metricsGrouped$nashComp < 0))
length(which(metricsGrouped$nashComp > 0))

metrics




as.data.frame(metricsGrouped)


mutate(fullRMSE = sqrt(mean (width-widthDis)^2), na.rm=T) %>%
  




widthPreds %>%
  summarise(sqrt( sum( (p_width - width)^2 , na.rm = TRUE ) / n() ))
  










#
## Calculate statistics for evaluation (compare to other flow method)
#








mods <- widths %>%
    group_by(river, section) %>%
    do(mod = lm(width ~ discharge, data = .)) 

dfHourCoef = tidy(mods, mod)


dfHourPred = augment(mods, mod)

as.data.frame(dfHourPred

%>%
    mutate(p_width = predict(model, widths))

p_width = predict(mods[1], widths[1,])




library(broom)

tidy(mods)


countNA <- widths %>%
  group_by(river, section) %>%
  summarise(countNA = sum(is.na(width)),
            count = n())


as.data.frame(widths[which(is.na(widths$width)),])



unique(flow$river)

unique(widths$river)



#
## Loop through all samples creating events table for each
#




# ---------------------------
# Date Retrieval - Tag Method
# ---------------------------
tags <- dbReadTable(wbConnect, "data_tagged_captures")

sel <- tags %>%
  filter(drainage == "west" & 
           area %in% c("trib", "inside")) %>%
  mutate(date = as.Date(trunc(detection_date, units = "days"))) %>%
  select(river, 
         sample = `sample_number`, 
         section,
         date) %>% 
  distinct() %>%
  na.omit() %>%
  arrange(river, sample, section)

# Duplicates with different dates
ind <- duplicated(sel[,c("river", "sample", "section")])
dups <- sel[ind,]




numrow <- 6

filter(tags, river == dups$river[numrow] & 
         sample_number == dups$sample[numrow] & 
         section == dups$section[numrow]) %>%
  arrange(detection_date)

dups[numrow,]
# For duplicate dates
# correct the date by being within the range of the bounding sections
# if 1 day apart, use later of the 2 dates
# if > 1 day apart, use the date in the majority of entries























set_config( config( ssl.verifypeer = 0L ) )

devtools::install_github("Conte-Ecology/westBrookData/getWBData")

reconnect()

