LIGHT_ORANGE <- "#E69F00"
LIGHT_BROWN <- "#B69070"
DARK_BLUE <- "#005EA2"
DARKEST_GREY <- "#444444"
LIGHTEST_YELLOW <- "#F0E442"
DARKEST_MAROON <- "#6A0000"
DARK_MAROON <- "#A44444"
LIGHTEST_GREEN <- "#C0D4A2"
LIGHTEST_BLUE <- "#BBDDF0"


plot_prevalence <- function(d, var_measure, var_group,
                            colour_palette,
                            var_measure_name=var_measure,
                            var_group_name=var_group,
                            point_size=2.0,
                            line_width=0.8,
                            ncol=NULL,
                            bins=31,
                            initial_plot=NULL) {
  d <- d[!is.na(d[[var_measure]]),]
  binwidth <- (max(d[[var_measure]]) - min(d[[var_measure]]))/bins
  if (is.null(initial_plot)) {
    p <- ggplot(d, aes_string(x=var_measure))
  } else {
    p <- initial_plot
  }
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="bar", lwd=0,
                    alpha=0.4, origin=(min(d[[var_measure]])-binwidth/2.0)) +
           aes_string(fill=var_group) +
           scale_fill_manual(values=colour_palette, name=var_group_name,
                      breaks=unique(d[[var_group]])) +
           scale_colour_manual(values=colour_palette,
                               name=var_group_name, breaks=unique(d[[var_group]]))     
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="line", colour="black",
                    lwd=line_width,
                    origin=(min(d[[var_measure]])-binwidth/2.0))
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="line", 
                    lwd=line_width*0.4,
                    origin=(min(d[[var_measure]])-binwidth/2.0))  
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="point", colour="black",
                    size=point_size*1.7,
                    origin=(min(d[[var_measure]])-binwidth/2.0))
  p <- p + stat_bin(aes(y=..ndensity..), binwidth=binwidth,
                    position='identity', geom="point", size=point_size*1.2,
                    origin=(min(d[[var_measure]])-binwidth/2.0)) +
           aes_string(colour=var_group, shape=var_group) +
           scale_shape(name=var_group_name, breaks=unique(d[[var_group]]))
  p <- p + 
    xlab(var_measure_name) + ylab("Normalized Empirical Density")
  return(p)
}

plot_prevalence_with_mean_facet <- function(d, var_measure, var_group,
                                            var_facet, colour_palette,
                                            var_measure_name=var_measure,
                                            var_group_name=var_group,
                                            var_facet_name=var_facet,
                                            mean_colored_lwd=3,
                                            point_size=2.0,
                                            text_size=24,
                                            hist_lwd=0.8, bins=31) {
  d_summ <- ddply(d, c(var_facet, var_group), function(dd)
    data.frame(measure_mean=mean(dd[[var_measure]])))
  p <- ggplot(d, aes_string(x=var_measure)) +
    geom_vline(data=d_summ,
               aes_string(xintercept="measure_mean", colour=var_group),
               lwd=mean_colored_lwd, alpha=0.8) +
    geom_vline(data=d_summ,
               aes_string(xintercept="measure_mean"), colour="black",
               lwd=mean_colored_lwd/4.0, alpha=1.0)
  q <- plot_prevalence(d, var_measure, var_group, colour_palette,
                       var_measure_name=var_measure_name,
                       var_group_name=var_group_name,
                       point_size=point_size, 
                       line_width=hist_lwd, bins=bins,
                       initial_plot=p)
  r <- q + facet_wrap(formula(paste0("~ ", var_facet)))
  return(r)
}