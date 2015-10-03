rm(list=ls())  # fresh workspace

## Load relevant libaries
suppressMessages(library(lubridate))  # datetime processing

## Read in data provided by data.nasa.gov
message("Loading raw EVA data...")
eva <- read.csv("Extra-vehicular_Activity__EVA__-_US_and_Russia.csv", header=TRUE, stringsAsFactors=FALSE)
colnames(eva) <- c("ID", "Country", "Crew", "Vehicle", "Date", "Duration", "Purpose")
## Append EVA data since Aug 2013 & China's EVA in 2008
## (Don't worry about the strange ID ordering, this will be fixed later)
message("Loading manual additions to EVA data...")
eva.additional <- read.csv("additions.csv", header=TRUE, stringsAsFactors=FALSE)
eva <- rbind(eva, eva.additional)
rm(eva.additional)

## Must perform three primary processing tasks:
## 1. Correct name misspellings of crew members and ensure each
##    member is separated by two whitespaces for later processing
## 2. Process inconsistent date formats (mm/dd/yyyy, Mo. dd, yyyy, etc.)
##    to common datetime type using lubridate package. Also, if date
##    covers a range of days, collapse to take the first day.
## 3. Convert duration format (hh:mm) to floating point hour
##    (e.g., 08:15 --> 8.25)

## Compile a list of name changes to make
corrected <- vector("list")
corrected["Thuot/Hieb/Akers"] <- "Pierre Thuot  Richard Hieb  Thomas Akers"
corrected["Doug Wheellock "] <- "Doug Wheelock  "
corrected["Clay Anderson"] <- "Clayton Anderson"
corrected["Anatoli Solovyov"] <- "Anatoly Solovyev"
corrected["Yri Onufrienko"] <- "Yuri Onufrienko"
corrected["Yuri Onufrenko"] <- "Yuri Onufrienko"
corrected["Mike Lopez-Alegria"] <- "Michael Lopez-Alegria"
corrected["Fyodor Yurchikin"] <- "Fyodor Yurchikhin"
corrected["Bob Curbeam"] <- "Robert Curbeam"
corrected["Christer Fugelsang"] <- "Christer Fuglesang"
corrected["Alexander Samokutyaev"] <- "Aleksandr Samokutyayev"
current.spellings <- names(corrected)

message("Processing...")

datetime <- rep(mdy("01/01/1960"), nrow(eva))
hours <- rep(0, nrow(eva))
for (i in 1:nrow(eva)) {
  # correct name spellings
  is.incorrect <- sapply(current.spellings, grepl, x = eva$Crew[i])
  if (any(is.incorrect)) {
    spelling <- current.spellings[is.incorrect]
    eva$Crew[i] <- gsub(spelling, corrected[spelling][[1]], eva$Crew[i])
  }
  
  # parse dates to consistent datetime type
  if (grepl("-", eva$Date[i])) {
    # eva may be spread over two or three days
    # In this case, take the first day of the eva.
    mon.days.year <- strsplit(eva$Date[i], ' ')[[1]]
    eva$Date[i] <- paste(mon.days.year[1], 
                         strsplit(mon.days.year[2], "-")[[1]][1], # take first day
                         mon.days.year[3])
  }
  if (grepl("Sept", eva$Date[i])) {
    # lubridate doesn't recognize "Sept" as abbrev for "September"
    # so change to "Sep"
    eva$Date[i] <- gsub("Sept", "Sep", eva$Date[i])
  }
  # parse two formats, e.g. "12/20/1988" or "Dec. 20, 1988"
  datetime[i] <- parse_date_time(eva$Date[i], c("%m%d%y", "%b%d%y"))
  
  # obtain number of hours from duration
  if (eva$Duration[i] == "") {
    eva$Duration[i] <- "0:00"
  }
  hour.and.min <- strsplit(eva$Duration[i], ":")[[1]]
  hours[i] <- as.numeric(hour.and.min[1]) + as.numeric(hour.and.min[2]) / 60
}

eva$Date <- datetime
eva$Duration <- round(hours, 5)
eva <- eva[eva$Duration > 0, ]  # only retain EVAs w/ positive duration

## Next, we deal with whitespace issues:
## 1. Some Vehicle names have excessive whitespace, so remove it
## 2. Rather than keep Crew column as "Jane Doe  John Doe"
##    we will create new columns for crewmember 1, 2, ...

trim <- function(str) {  # remove trailing whitespace from left & right sides
  gsub("^\\s+|\\s+$", "", str)
}

extract_content <- function(v) {  # remove all "" values from character vector
  v <- trim(v)
  v <- v[v != ""]
  return(v)
}

split_and_remove_excessive_whitespace <- function(x) { # split on "  " and remove whitesapce 
  messy.list <- strsplit(trim(x), "  ")
  return(lapply(messy.list, extract_content))
}

# Manage vehicles...
eva$Vehicle <- sapply(split_and_remove_excessive_whitespace(eva$Vehicle), paste, collapse=" ")
# ... and crew!
crews <- split_and_remove_excessive_whitespace(eva$Crew)
max.crew.size <- max(unlist(lapply(crews, length)))
## For each EVA, supplement crews with less than max.crew.size members
## with whitespace values for easy creation of new columns
for (i in 1:length(crews)) {
  crew.size <- length(crews[[i]])
  if (crew.size < max.crew.size) {
    crews[[i]] <- append(crews[[i]], rep("", max.crew.size - crew.size))
  }
}
members <- data.frame(do.call(rbind, crews))
names(members) <- paste0("Member", 1:max.crew.size)

## Make final modifications to the data
eva <- cbind(eva, members) # include member columns in dataframe
eva <- eva[order(eva$Date), ]  # sort data by date (earliest to latest)
eva$ID <- 1:nrow(eva)  # renumber IDs by date
eva <- eva[, c("ID", "Date", "Duration", "Country", "Vehicle", "Member1", "Member2", "Member3", "Purpose")]
rownames(eva) <- NULL

# Finally, save processed data as new csv
# Retain quotes around values in the final column, as they may contain commas
# but do not place quotes around any other values
filename <- "spacewalks.csv"
write.csv(eva, filename, quote = ncol(eva), row.names = FALSE)
message(paste("Done! Processed data saved as", filename))