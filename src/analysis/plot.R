library(magrittr)
library(pryr)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
default_colour_palette <- c(Random="#E69F00", Natural="#56B4E9", 
                            Vowel="#009E73", "#F0E442",
                            Consonant="#0072B2", Stop="#D55E00",
                            RandomProp="#CC79A7")

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

do_rank_thing <- function(d, var, by, seed=1) {
  d_by1 <- d[d[[by]] == unique(d[[by]])[1],]
  d_by2 <- d[d[[by]] == unique(d[[by]])[2],]
  subsample <- min(c(nrow(d_by1), nrow(d_by2)))
  set.seed(seed)
  if (subsample == nrow(d_by1)) {
    d_by2 <- d_by2[sample(1:nrow(d_by2), subsample),]
  } else {
    d_by1 <- d_by1[sample(1:nrow(d_by1), subsample),]
  }
  set.seed(NULL)
  d_by1$rank <- rank(d_by1[[var]], ties.method="first")
  d_by2$rank <- rank(d_by2[[var]], ties.method="first")
  result <- merge(d_by1, d_by2, by="rank",
                  suffixes=as.character(unique(d[[by]]))[1:2])
  return(result)
}


relcount <- function(d, vars_of_interest, vars_by) {
  t <- count(d, vars=c(vars_of_interest, vars_by))
  t_total <- count(d, vars=vars_by)
  result <- merge(t, t_total, by=c(vars_by))
  result$freq <- result$freq.x/result$freq.y
  result <- result[,c(vars_of_interest, vars_by, "freq")]
  return(result)
}

plot_prevalence_conditional <- function(d, dep_measure, cond_factor, group,
                                        dep_measure_label=dep_measure,
                                        cond_factor_label=cond_factor,
                                        group_label=group,
                                        palette=default_colour_palette,
                                        point_size=1,
                                        text_size=NULL,
                                        ncol=NULL,
                                        drop=FALSE) {
  t <- relcount(d, dep_measure, c(cond_factor, group))
  t <- t[!(is.na(t[[1]]) | is.na(t[[2]])),]
  if (drop) {
    levs <- unique(d[[cond_factor]])
    for (g in unique(d[[group]])) {
      levs <- intersect(levs, d[d[[group]]==g,cond_factor])
    }
    t <- t[t[[cond_factor]] %in% levs,]
  }
  p <- ggplot(t, aes_string(x=dep_measure, y="freq")) +
    geom_bar(aes_string(fill=group), colour="black", alpha=0.4, 
                   position='identity', stat='identity') +    
    geom_line(aes_string(group=group), lwd=1.6,
             position='identity') +
    theme(text=element_text(size=text_size), legend.position="bottom") +
    scale_fill_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(t[[group]])) +    
    scale_colour_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(t[[group]])) +
    xlab(dep_measure_label) + ylab("Relative frequency") +
    labs(title=paste0(dep_measure_label, " by ", cond_factor_label))
  
  if (drop) {
    p <- p +facet_wrap(formula(paste("~", cond_factor)),
                       ncol=ncol, scales=c("free"))
  } else {
    p <- p + facet_wrap(formula(paste("~", cond_factor), scales=c("free_y")), ncol=ncol)
  }
  return(p)
}

cut2 <- function(x, breaks) {
  r <- range(x, na.rm=T)
  b <- seq(r[1], r[2], length=2*breaks+1)
  brk <- b[0:breaks*2+1]
  mid <- b[1:breaks*2]
  brk[1] <- brk[1]-0.01
  k <- cut(x, breaks=brk, labels=FALSE)
  mid[k]
}

plot_prevalence <- function(d, dep_measure, group,
                                        dep_measure_label=dep_measure,
                                        group_label=group,
                                        palette=default_colour_palette,
                                        point_size=4.0,
                                        line_width=2.2,
                                        text_size=NULL,
                                        ncol=NULL,
                                        bins=30) {
  d <- d[!is.na(d[[dep_measure]]),]
  binwidth <- (max(d[[dep_measure]]) - min(d[[dep_measure]]))/bins
  p <- ggplot(d, aes_string(x=dep_measure)) +
    stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="bar", colour="black", alpha=0.4) +
    aes_string(fill=group) +
    stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="line", colour="black", lwd=line_width) +
    stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point", colour="black", size=point_size*1.7) +
    stat_bin(aes(y=..ndensity..), binwidth=binwidth, position='identity',
             geom="point", size=point_size*1.2) +
    aes_string(colour=group) +
    theme(text=element_text(size=text_size), legend.position="bottom") +
    scale_fill_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(d[[group]])) +
    scale_colour_manual(values=palette, drop=F, name=group_label,
                        breaks=unique(d[[group]])) +
    xlab(dep_measure_label) + ylab("Relative Frequency") +
    labs(title=paste0(dep_measure_label))
  return(p)
}

plot_feature_ranks <- function(d, var, group,
                               var_label=var,
                               group_label=group,
                               palette=default_colour_palette,
                               point_size=1,
                               text_size=NULL) {
  p <- ggplot(d, aes_string(y=var, x="rank", colour=group)) +
    geom_line(lwd=2) + geom_point(size=point_size, colour="black") +
    xlab("Rank") + ylab(var_label) +
    theme(text=element_text(size=text_size), legend.position="bottom") +
    scale_colour_manual(values=palette, drop=F,name=group_label,
                        breaks=unique(d[[group]]))
  return(p)
}