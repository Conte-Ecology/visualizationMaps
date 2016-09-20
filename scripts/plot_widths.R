# Description
# -----------



# Libraries
# ---------
rm(list = ls())

library(dplyr)
library(readxl)


# Specify inputs
# --------------
# Filepath to the project directory
baseDir <- "C:/KPONEIL/sideProjects/visualizationMaps/westbrookSections"


# Read inputs
# -----------
# Section width records
raw <- read_excel(paste0(baseDir,"/tables/raw/Habitat West Brook.xlsx"), 
                  sheet = 6, 
                  col_names = TRUE, 
                  col_types = NULL, 
                  na = "", 
                  skip = 0)    


wb <- raw[,c("Sample Num", "Section", "Average Section Width")]

names(wb) <- c("sample", "section", "width")

wb$section <- as.numeric(wb$section)

length(which(is.na(wb$width)))


wbSample <- group_by(wb, sample) %>%
            summarise(count=n(),
                      na=sum(is.na(width)))

as.data.frame(wbSample)

wbSection <- group_by(wb, section) %>%
              summarise(mean=mean(width,na.rm=T))
  
plot(wb$section, wb$width)
#points(wbSection$section, wbSection$mean, pch = 19, col="red")



# Width in all samples by section
boxplot(wb$width ~ wb$section, xlab = "section", ylab = "width")


## Width in all section by sample
#boxplot(wb$width ~ wb$sample, xlab = "sample", ylab = "width")


require ("ggplot2")

# Widths over time
ggplot(wb, aes(x=sample, y=width)) + 
  geom_line(aes(colour=section, group=section)) +
  geom_point(aes(colour=section), size=3) +
  scale_color_gradientn(colours = rainbow(5))




# Flow Duration Curve Method
# --------------------------
sectionNumber <= 1


sec <- filter(wb, section == sectionNumber) %>% 
          na.omit() %>%
          arrange(desc(width)) %>%
          mutate(rank = rank(desc(width), ties.method = "random"))

sec$P = 100*(sec$rank/(nrow(sec)+1))


plot(sec$P, 
       sec$width, 
       xlab = "Exceedance", 
       ylab = "Width")


# Questions
# ---------
# Where in the section is the "average width"



