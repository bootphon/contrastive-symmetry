library(magrittr)
library(pryr)
library(scatterplot3d)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
default_colour_palette <- c(Random="#E69F00", Natural="#56B4E9") 
random_types_palette <- c("#E69F00", "#56B4E9", "#CC79A7", "#0072B2",
                          "#D55E00")
names(random_types_palette) <- c("Random (Study 1)", "Natural",
                                 "Random Feature", "Random Beta-binomial", "Random Matrix")
default_text_colour <- "#535353"
segment_types_palette <- c("#009E73", "#56B4E9", "#0072B2", 
                          "#D55E00")
names(segment_types_palette) <- c("Stop", "Whole", "Vowel", "Consonant")


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
                                        binwidth=NULL,
                                        change_font=TRUE,
                                        initial_plot=NULL) {
  d <- d[!is.na(d[[dep_measure]]),]
  if (is.null(binwidth)) {
    binwidth <- (max(d[[dep_measure]]) - min(d[[dep_measure]]))/bins
  }
  if (is.null(initial_plot)) {
    p <- ggplot(d, aes_string(x=dep_measure))
  } else {
    p <- initial_plot
  }
  if (!is.null(group)) {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                      position='identity', geom="bar", colour="black",
                      alpha=0.4, origin=(min(d[[dep_measure]])-binwidth/2.0)) +
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
                    lwd=line_width,  origin=(min(d[[dep_measure]])-binwidth/2.0)) +
           stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="point", colour="black",
                    size=point_size*1.7,  origin=(min(d[[dep_measure]])-binwidth/2.0))
  if (!is.null(group)) {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point",  origin=(min(d[[dep_measure]])-binwidth/2.0)) +
             aes_string(colour=group)
  } else {
    p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point", size=point_size*1.2, colour=colour_palette[1],
              origin=(min(d[[dep_measure]])-binwidth/2.0))
  }
  if (change_font) {
    p <- p +
    theme(text=element_text(size=text_size, colour=text_colour))
  }
  p <- p + theme(legend.position="bottom")
  p <- p + 
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
                       bins=30,
                       change_font=T) {
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
  if (change_font) {
    p <- p +
    theme(text=element_text(size=text_size, colour=text_colour))
  }
  p <- p + theme(legend.position="bottom") +
    scale_fill_manual(values=palette, drop=F, name=group_label,
                        breaks=levels(d[[group]])) +
    scale_colour_manual(values=palette, drop=F, name=group_label,
                        breaks=levels(d[[group]])) +
    ylab(dep_measure_label)    
  return(p)
}

cube <- function(x, y, z, two=T, corner_text_outside=NULL,
                 corner_text_inside=NULL, corner_text_cex=1.0, 
                 point_cex=1.0, square=F, ...) {
  p <- scatterplot3d(x, y, z, grid=F, box=F, axis=F,
                     xlim=c(0,1), ylim=c(0,1), zlim=c(-0.11,1.11),
                     cex.symbols=point_cex, ...)
  p$points3d(c(0,1),c(0,0),c(0,0), type="l", col="darkgrey")
  p$points3d(c(0,0),c(0,0),c(0,1), type="l", col="darkgrey")
  p$points3d(c(1,1),c(0,0),c(0,1), type="l", col="darkgrey")
  p$points3d(c(1,1),c(0,0),c(0,1), type="l", col="darkgrey")
  p$points3d(c(0,1),c(0,0),c(1,1), type="l", col="darkgrey")
  if (!square) {
    p$points3d(c(0,1),c(1,1),c(0,0), type="l", col="darkgrey")
    p$points3d(c(0,1),c(1,1),c(1,1), type="l", col="darkgrey")
    p$points3d(c(0,0),c(1,1),c(0,1), type="l", col="darkgrey")
    p$points3d(c(1,1),c(1,1),c(0,1), type="l", col="darkgrey")
    p$points3d(c(1,1),c(0,1),c(0,0), type="l", col="darkgrey")
    p$points3d(c(0,0),c(0,1),c(1,1), type="l", col="darkgrey")
    p$points3d(c(1,1),c(0,1),c(1,1), type="l", col="darkgrey")
    p$points3d(c(0,0),c(0,1),c(0,0), type="l", col="darkgrey")
  }
  if (two) {
    p$points3d(c(1/4,3/4),c(1/4,1/4),c(1/4,1/4), type="l", col="darkgrey")
    p$points3d(c(1/4,1/4),c(1/4,3/4),c(1/4,1/4), type="l", col="darkgrey")
    p$points3d(c(1/4,1/4),c(1/4,1/4),c(1/4,3/4), type="l", col="darkgrey")
    p$points3d(c(3/4,3/4),c(1/4,3/4),c(1/4,1/4), type="l", col="darkgrey")
    p$points3d(c(3/4,3/4),c(1/4,1/4),c(1/4,3/4), type="l", col="darkgrey")
    p$points3d(c(3/4,3/4),c(1/4,1/4),c(1/4,3/4), type="l", col="darkgrey")
    p$points3d(c(1/4,3/4),c(1/4,1/4),c(3/4,3/4), type="l", col="darkgrey")
    p$points3d(c(1/4,3/4),c(3/4,3/4),c(1/4,1/4), type="l", col="darkgrey")
    p$points3d(c(1/4,3/4),c(3/4,3/4),c(3/4,3/4), type="l", col="darkgrey")
    p$points3d(c(1/4,1/4),c(3/4,3/4),c(1/4,3/4), type="l", col="darkgrey")
    p$points3d(c(3/4,3/4),c(3/4,3/4),c(1/4,3/4), type="l", col="darkgrey")
    p$points3d(c(1/4,1/4),c(1/4,3/4),c(3/4,3/4), type="l", col="darkgrey")
    p$points3d(c(3/4,3/4),c(1/4,3/4),c(3/4,3/4), type="l", col="darkgrey")    
  }
  p$points3d(x, y, z, cex=point_cex, ...)
  if (!is.null(corner_text_outside)) {
    corners <- list(c(0,0,-0.11), c(0,0,1.11),
                            c(1,0,-0.11), c(1,0,1.11),
                            c(0,1,-0.11), c(0,1,1.11),
                            c(1,1,-0.11), c(1,1,1.11))
    for (i in 1:min(length(corners), length(corner_text_outside))) {
      text(p$xyz.convert(corners[[i]][1], corners[[i]][2],
                         corners[[i]][3]),
           labels=corner_text_outside[i], cex=corner_text_cex)
    }
  }
  if (!is.null(corner_text_inside)) {
    corners <- list(c(1/4,1/4,1/4-0.11), c(1/4,1/4,3/4+.11),
                    c(3/4,1/4,1/4-0.11), c(3/4,1/4,3/4+.11),
                    c(1/4,3/4,1/4-0.11), c(1/4,3/4,3/4+.11),
                    c(3/4,3/4,1/4-0.11), c(3/4,3/4,3/4+.11))
    for (i in 1:min(length(corners), length(corner_text_inside))) {
      text(p$xyz.convert(corners[[i]][1], corners[[i]][2],
                         corners[[i]][3]),
           labels=corner_text_inside[i], cex=corner_text_cex)
    }
  }  
}