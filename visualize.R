rm(list=ls())  # fresh workspace

message("Loading processed data...")

## Load processed data and relevant packages
eva <- read.csv("spacewalks.csv", header=TRUE, stringsAsFactors = FALSE)
suppressMessages(library(lubridate))  # datetime objects in Plot 2
eva$Date <- ymd(eva$Date)  # convert dates to datetime objects
library(reshape2)   # to "melt" data from wide to long format
library(ggplot2)    # for single plots
library(gridExtra)  # necessary for arranging multiple ggplots
library(grid)       # for textGrob (adds text to plots)

# > sessionInfo()
# R version 3.2.0 (2015-04-16)
# Platform: x86_64-apple-darwin13.4.0 (64-bit)
# Running under: OS X 10.10.5 (Yosemite)
# 
# locale:
#   [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
# 
# attached base packages:
#   [1] grid      stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#   [1] gridExtra_2.0.0 ggplot2_1.0.1   reshape2_1.4.1  lubridate_1.3.3
# 
# loaded via a namespace (and not attached):
#   [1] Rcpp_0.12.1      digest_0.6.8     MASS_7.3-40      plyr_1.8.3.9000 
# [5] gtable_0.1.2     magrittr_1.5     scales_0.2.4     stringi_0.4-1   
# [9] proto_0.3-10     tools_3.2.0      stringr_1.0.0    munsell_0.4.2   
# [13] colorspace_1.2-6 memoise_0.2.1   


## Plot 1
## EVA duration by *naut (* = astro, cosmo, taiko, etc.)
message("Building plot of EVA duration by individual...")

eva.long <- eva[, c("ID", "Date", "Duration", "Country", "Member1", "Member2", "Member3")]
eva.long <- melt(eva.long, id = c("ID", "Date", "Duration", "Country"))
# remove empty crew members
eva.long <- eva.long[eva.long$value != "", ]
# re-sort data by Date so "blocks" in resulting plot
# are in the correct order for each *naut
eva.long <- eva.long[order(eva.long$Date), ]  

# Rank *nauts by total EVA time
all.nauts <- unique(eva.long$value)
total.duration <- rep(list(0), length(all.nauts))
names(total.duration) <- all.nauts
for (naut in all.nauts) {
  total.duration[naut][[1]] <- with(eva.long, sum(Duration[value == naut]))
}
total.duration <- sort(unlist(total.duration))
eva.long$value <- factor(eva.long$value, levels = names(total.duration))

p1 <- ggplot(eva.long, aes(x=value, y=Duration, fill=factor(Country, levels=c("Russia", "USA", "China")))) + 
  scale_fill_manual(values=c("#FF6666", "#7094FF", "#EBC633")) + 
  scale_x_discrete(name="", labels=paste0(names(total.duration), sprintf("%4d", rev(1:length(total.duration))))) +
  scale_y_continuous(name="Duration (hours)", breaks=seq(0, 80, by=10)) +
  geom_bar(stat="identity", width=0.6, color="white") + 
  guides(fill=FALSE) +
  ggtitle("Spacewalks by individual\n") +
  coord_flip()

## Plot 2
## EVA duration by mission over time
message("Building plot of EVA duration by mission...")

# Retaining vehicle name per EVA produces a very cluttered plot.
# To rectify this, only retain Vehicle name with the EVA of longest duration.
reduced.vehicles <- rep("", nrow(eva))
for (v in unique(eva$Vehicle)) {
  is.vehicle <- eva$Vehicle == v
  longest.eva.in.vehicle <- which.max(eva$Duration[is.vehicle])
  reduced.vehicles[is.vehicle][longest.eva.in.vehicle] <- v
}
eva$Vehicle <- reduced.vehicles

p2 <- ggplot(eva) + 
  geom_bar(aes(x=Date, y=Duration, fill=factor(Country, levels=c("Russia", "USA", "China"))), 
           stat = "identity", position="dodge", width=1000000) + 
  geom_text(aes(x=Date, y=Duration, label=Vehicle), size=2.5, alpha=0.7, hjust=-0.05) + 
  scale_x_datetime(name="", breaks=mdy(paste0("01/01/", 1965:2015)), labels=1965:2015, lim=mdy(paste0("06/01/", c(1966, 2013)))) +
  scale_y_continuous(breaks=0:9, lim=c(0, 9.5)) + 
  scale_fill_manual(name="Space program responsible for spacewalk",
                    labels=c("Russian Federal Space Agency (RKA) / Soviet space program", 
                             "National Aeronautics & Space Administration (NASA)",
                             "China National Space Administration (CNSA)"), 
                    values=c("#FF6666", "#7094FF", "#EBC633")) +
  theme(legend.position="right") +
  ggtitle("Spacewalks by mission\n") + 
  labs(x = "Date", y = "Duration (hours)") +
  coord_flip()

## Full plot
## Produce final graphic with Plot 1 and Plot 2 together with
## title, legend, description and credits

message("Combining plots into full graphic...")

grab_legend <- function(p) {
  tmp <- ggplot_gtable(ggplot_build(p))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

splitString <- function(text, width) {
  # Created by Baptiste Auguie:
  # https://groups.google.com/forum/#!msg/ggplot2/sg9jA-FeQls/i3GPoiNUzN8J
  if(is.null(text)) return(NULL)
  strings <- strsplit(text, " ")[[1]]
  newstring <- strings[1]
  linewidth <- stringWidth(newstring)
  gapwidth <- stringWidth(" ")
  availwidth <- convertWidth(width, "inches", valueOnly = TRUE)
  for (i in 2:length(strings)) {
    width <- stringWidth(strings[i])
    if (convertWidth(linewidth + gapwidth + width, "inches",
                     valueOnly = TRUE) < availwidth) {
      sep <- " "
      linewidth <- linewidth + gapwidth + width
    }
    else {
      sep <- "\n"
      linewidth <- width
    }
    newstring <- paste(newstring, strings[i], sep = sep)
  }
  newstring
}

title <- "Spacewalks: A Fifty-Year History"
description <- "The first ever spacewalk was performed by cosmonaut Alexei Leonov on March 18, 1965. Since then, humankind has logged over 2,000 hours of extravehicular activity (EVA) beyond Earth's appreciable atmosphere. Three nations have led spacewalks: Russia, USA, and China, following the success of Shenzhou 7 on September 28, 2008." 
credits <- "Raw data from data.nasa.gov. GitHub repo at github.com/nsgrantham/spacewalks. Data visualization by Neal Grantham (@nsgrantham)."
legend <- suppressWarnings(grab_legend(p2))

title.grob <- grid::textGrob(title, gp=gpar(fontsize=32, fontface="bold"), vjust=1)
description.grob <- grid::textGrob(splitString(description, unit(0.8, "npc")), gp=gpar(fontsize=15), vjust=1)
credits.grob <- grid::textGrob(credits, gp=gpar(fontsize=8, fontface="italic"), vjust=6)
g1 <- grid.arrange(title.grob, description.grob, legend, credits.grob, ncol=2)
g2 <- suppressWarnings(grid.arrange(p1 + theme(legend.position="none"), p2 + theme(legend.position="none"), ncol = 2))

filename <- "spacewalks.png"
png(filename, width=2000, height=4000, res=120)
grid.arrange(g1, g2, nrow=2, heights=c(1, 13))
dev.off()
# This final command will print "pdf\n 2" to the console
# and save an empty Rplots.pdf to the directory
# if run from the command line, i.e., Rscript visualize.R
# The best option for living with this side effect is to
# destroy the empty Rplots.pdf immediately after it's created.
# This is accomplished in the Makefile.
# For more on this annoying feature of R, see the following:
# https://github.com/STAT545-UBC/Discussion/issues/59
message(paste("Done! Full graphic saved as", filename))
