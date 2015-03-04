library(magrittr)
library(pryr)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
default_colour_palette <- c(Random="#E69F00", Natural="#56B4E9") 
random_types_palette <- c("#E69F00", "#56B4E9", "#CC79A7",
                          "#D55E00")
names(random_types_palette) <- c("Random Segment", "Natural",
                                 "Random Feature", "Random Matrix")
default_text_colour <- "#535353"

RANDOM_TYPES <- c("Random Matrix", "Random Segment", "Random Feature")
ONE_RANDOM <- "Random"

one_random <- function(d, random_type) {
  random <- as.character(d$inventory_type) %in% RANDOM_TYPES
  this_random_type <- partial(equals, random_type)
  right_random <- d$inventory_type %>%
                    as.character %>%
                    this_random_type
  d <- d[!random | right_random,]
  d$inventory_type <- as.character(d$inventory_type)
  d$inventory_type[this_random_type(d$inventory_type)] <- ONE_RANDOM
  d$inventory_type <- factor(d$inventory_type)
  return(d)
}

multi_random <- function(d) {
  result <- c()
  d$inventory_type <- as.character(d$inventory_type)
  for (r in RANDOM_TYPES) {
    d_r <- d[d$inventory_type == r,]
    d_r$inventory_type <- ONE_RANDOM
    d_nr <- d[!(d$inventory_type %in% RANDOM_TYPES),]
    d_both <- rbind(d_r, d_nr)
    d_both$random_type <- r
    result <- rbind(result, d_both)
  }
  result$random_type <- factor(result$random_type,
        levels = c("Random Matrix", "Random Feature", "Random Segment"))
  return(result)
}

plot_prevalence <- function(d, dep_measure, group,
                                        dep_measure_label=dep_measure,
                                        group_label=group,
                                        colour_palette=default_colour_palette,
                                        point_size=7.0,
                                        line_width=4.0,
                                        text_size=48,
                                        text_colour=default_text_colour,
                                        ncol=NULL,
                                        bins=30,
                                        binwidth=NULL) {
  d <- d[!is.na(d[[dep_measure]]),]
  if (is.null(binwidth)) {
    binwidth <- (max(d[[dep_measure]]) - min(d[[dep_measure]]))/bins
  }
  p <- ggplot(d, aes_string(x=dep_measure))
  if (!is.null(group)) {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                      position='identity', geom="bar", colour="black",
                      alpha=0.4) +
             aes_string(fill=group) +
             scale_fill_manual(values=colour_palette, drop=F, name=group_label,
                        breaks=unique(d[[group]])) +
             scale_colour_manual(values=colour_palette, drop=F,
                                 name=group_label, breaks=unique(d[[group]]))     
  } else {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                      position='identity', geom="bar", colour="black",
                      alpha=0.4, fill=colour_palette[1])     
  }
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="line", colour="black",
                    lwd=line_width) +
           stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="point", colour="black",
                    size=point_size*1.7)
  if (!is.null(group)) {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point", size=point_size*1.2) +
             aes_string(colour=group)
  } else {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point", size=point_size*1.2, colour=colour_palette[1])
  }
  p <- p +
    theme(text=element_text(size=text_size, colour=text_colour),
          legend.position="bottom") +
    xlab(dep_measure_label) + ylab("Normalized Empirical Density")
  return(p)
}

plot_means <- function(d, dep_measure, group,
                                        dep_measure_label=dep_measure,
                                        group_label=group,
                                        second_group=NULL,
                                        second_group_label=second_group,
                                        x_var=NULL,
                                        x_var_label=x_var,
                                        palette=default_colour_palette,
                                        point_size=7.0,
                                        line_width=7.0,
                                        text_size=48,
                                        text_colour=default_text_colour,
                                        ncol=NULL,
                                        bins=30) {
  d <- d[!is.na(d[[dep_measure]]),]
  p <- ggplot(d, aes_string(y=dep_measure))
  if (!is.null(second_group)) {
    p <- p + geom_bar(aes_string(x=second_group, fill=group),
                        position="dodge", stat="summary",
                        fun.y="mean", colour="black", alpha=0.4)
    p <- p + xlab(second_group_label)
  } else if (!is.null(x_var)) {
      p <- p + geom_point(aes_string(x=x_var), stat="summary", colour="black",
                      fun.y="mean", size=point_size, alpha=0) +
               geom_line(aes_string(x=x_var, colour=group), stat="summary",
                     fun.y="mean", lwd=line_width, alpha=0.6) +
               geom_line(aes_string(x=x_var, group=group), stat="summary",
                         colour="black",
                     fun.y="mean", lwd=0.2*line_width, alpha=0.8) +
               geom_point(aes_string(x=x_var, group=group), stat="summary",
                          colour="black",
                     fun.y="mean", lwd=0.4*line_width, alpha=0.8)
      p <- p + xlab(x_var_label)
  } else {
    p <- p + geom_bar(aes_string(x=group, fill=group), stat="summary",
                        fun.y="mean", colour="black", alpha=0.4)
    p <- p + xlab(group_label)    
  }
  p <- p +
    theme(text=element_text(size=text_size, colour=text_colour),
          legend.position="bottom") +
    scale_fill_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(d[[group]])) +
    scale_colour_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(d[[group]])) +
    ylab(dep_measure_label)    
  return(p)
}
