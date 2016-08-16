library(dplyr)
library(tidyr)
library(purrr)
library(feather)
library(rocauc)
library(foreach)
library(doParallel)
library(ggplot2)

registerDoParallel(cores=4)

inventories_summ <- read_feather("summary.feather")

# Table 1: Means

mean_table <- inventories_summ %>%
  group_by(inventory_type, segment_type) %>%
  summarize(mean_econ=mean(econ),
            mean_loc=mean(loc, na.rm=T),
            mean_glob=mean(glob, na.rm=T)) %>%
  ungroup()

# Table 1: AUC bootstrap intervals

bootstrap_auc <- function(d, measure_var, types) {
  d_types <- d %>% filter(inventory_type %in% types)
  result <- times(10000) %dopar%
    auc_by_df(d_types[sample(1:nrow(d_types), nrow(d_types), replace=T),],
              measure_var, "inventory_type", types[1])
  return(result)
}

all_bootstrap_auc_quantiles <- function(d) {
  all_comparisons <- list(
    c("econ", "Random segment (freq. matched)", "Natural"),
    c("loc", "Random segment (freq. matched)", "Natural"),
    c("glob", "Random segment (freq. matched)", "Natural"),
    c("econ", "Random segment", "Random segment (freq. matched)"),
    c("econ", "Random feature", "Random feature (freq. matched)"),
    c("econ", "Random segment", "Random feature"),
    c("loc", "Random segment", "Random segment (freq. matched)"),
    c("loc", "Random feature", "Random feature (freq. matched)"),
    c("loc", "Random segment", "Random feature"),
    c("glob", "Random segment", "Random segment (freq. matched)"),
    c("glob", "Random feature", "Random feature (freq. matched)"),
    c("glob", "Random segment", "Random feature")
  )
  all_results <- list()
  for (i in 1:length(all_comparisons)) {
    triplet <- all_comparisons[[i]]
    measure <- triplet[1]
    left_group <- triplet[2]
    right_group <- triplet[3]
    bootstrap_auc_sample <- bootstrap_auc(d, measure, c(left_group,right_group))
    all_results[[i]] <- data.frame(
      measure=measure, left_group=left_group, right_group=right_group,
      q025=quantile(bootstrap_auc_sample, 0.025),
      q975=quantile(bootstrap_auc_sample, 0.975)
    )
  }
  result <- do.call("rbind", all_results)
  return(tbl_df(result))
}

auc_table <- inventories_summ %>%
  group_by(segment_type) %>%
  do(bootstrap_auc_quantiles=all_bootstrap_auc_quantiles(.)) %>%
  unnest(bootstrap_auc_quantiles)

# Figure 6
violin <- function(p) {
  p +
  geom_vline(xintercept=-0.12, lwd=0.3, colour="#888888") +
  geom_vline(xintercept=0.36, lwd=0.3, colour="#888888") +
  geom_violin(position=position_dodge(width=1.2), colour="#000000",
              draw_quantiles=0.5, lwd=1, scale="width") +
  geom_violin(aes(group=inventory_type), fill=rgb(0,0,0,0),
              position=position_dodge(width=1.2), colour="#FFFFFF",
              draw_quantiles=0.5, lwd=0.3, scale="width") +
  guides(fill=guide_legend(title="")) + theme_bw() +
  theme(text=element_text(family="Times", size=24, colour="black"),
        axis.text=element_text(colour="black"),
        axis.title.x=element_blank(), axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        panel.grid.major.x=element_blank(),
        panel.grid.minor.x=element_blank(),
        legend.position="none")
}
LIGHTEST_TURQUOISE <- "#D1EBE9"
LIGHT_TURQUOISE <- "#28D1C1"
LIGHTEST_ORANGE <- "#FFD26C"
LIGHT_ORANGE <- "#E69F00"
DARK_BLUE <- "#005EA2"
palette_ <- c(`Random feature`=LIGHTEST_TURQUOISE,
              `Random feature (freq. matched)`=LIGHT_TURQUOISE,
              `Random segment`=LIGHTEST_ORANGE,
              `Random segment (freq. matched)`=LIGHT_ORANGE,
              Natural=DARK_BLUE)
inventories_summ$inventory_type <- factor(inventories_summ$inventory_type,
                                          levels=c("Random feature",
                                            "Random feature (freq. matched)",
                                            "Random segment",
                                            "Random segment (freq. matched)",
                                            "Natural"))
inventories_summ$segment_type <- factor(inventories_summ$segment_type,
                                        levels=c("Whole", "Consonant",
                                                 "Stop/affricate", "Vowel"))
fig6_econ <- violin(ggplot(inventories_summ,
                           aes(y=econ, x=0, fill=inventory_type))) +
  scale_fill_manual(values=palette_) +
  facet_wrap(~ segment_type, nrow=1) + ylab("Econ")
fig6_loc <- violin(ggplot(inventories_summ,
                           aes(y=loc, x=0, fill=inventory_type))) +
  scale_fill_manual(values=palette_) +
  facet_wrap(~ segment_type, nrow=1) + ylab("Loc")
fig6_glob <- violin(ggplot(inventories_summ,
                           aes(y=glob, x=0, fill=inventory_type))) +
  scale_fill_manual(values=palette_) +
  facet_wrap(~ segment_type, nrow=1) + ylab("Glob")
