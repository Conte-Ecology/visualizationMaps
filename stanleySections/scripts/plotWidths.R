rm(list=ls())

library(dplyr)
library(ggplot2)

st <- read.csv("C:/KPONEIL/sideProjects/visualizationMaps/stanleySections/tables/wet_widths.csv")


head(st)
st <- st[,c("sample", "Branch", "Section", "mean.width")]

names(st) <- c("sample", "branch", "section", "width")

# Fix section numbers to be unique
st$section[which(st$branch == "EAST" & st$section == 34)] <- 51
st$section[which(st$branch == "EAST" & st$section == 35)] <- 52
st$section[which(st$branch == "EAST" & st$section == 36)] <- 53


# Add season
st$season <- NA
st$season[which(st$sample%%2==0)] <- "fall"
st$season[which(st$sample%%2!=0)] <- "spring"

spring <- st[which(st$season == "spring"),]
fall <- st[which(st$season == "fall"),]


# Summarise NAs
stSample <- group_by(st, sample) %>%
            summarise(count=n(),
                      na=sum(is.na(width)))

as.data.frame(stSample)


# Plot over sections
stSection <- group_by(st, section) %>%
             summarise(mean=mean(width,na.rm=T))

plot(st$section, st$width)
points(stSection$section, stSection$mean, pch = 19, col="red")



# Width in all samples by section
# -------------------------------
# All
boxplot(st$width ~ st$section, xlab = "section", ylab = "width")

# Spring
boxplot(spring$width ~ spring$section, xlab = "section", ylab = "width")

# Fall
boxplot(fall$width ~ fall$section, xlab = "section", ylab = "width")


# Width in all section by sample
# ------------------------------
# All
boxplot(st$width ~ st$sample, xlab = "sample", ylab = "width")

# Spring
boxplot(spring$width ~ spring$sample, xlab = "sample", ylab = "width")

# Fall
boxplot(fall$width ~ fall$sample, xlab = "sample", ylab = "width")


# Widths over time
# ----------------
# All
ggplot(st, aes(x=sample, y=width)) + 
  geom_line(aes(colour=section, group=section)) +
  geom_point(aes(colour=section), size=3) +
  scale_color_gradientn(colours = rainbow(5))

# Spring
ggplot(spring, aes(x=sample, y=width)) + 
  geom_line(aes(colour=section, group=section)) +
  geom_point(aes(colour=section), size=3) +
  scale_color_gradientn(colours = rainbow(5))

# Fall
ggplot(fall, aes(x=sample, y=width)) + 
  geom_line(aes(colour=section, group=section)) +
  geom_point(aes(colour=section), size=3) +
  scale_color_gradientn(colours = rainbow(5))





# Fall
section <- 1
record <- st[which(st$section == 1),]

ggplot(record, aes(x=sample, y=width)) + 
  geom_line(aes(colour=season, group=season)) +
  geom_point(aes(colour=season), size=3)











