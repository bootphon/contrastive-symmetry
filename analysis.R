library(ggplot2)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
color_palette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                   "#0072B2", "#D55E00", "#CC79A7")

sample_rows <- function(d, var, v, n, replace=F) {
  rows_v <- (rownames(d))[as.character(d[[var]]) == v]
  set.seed(1)
  result <- sample(rows_v, n, replace)
  set.seed(NULL)
  return(result)
}

subsample_by_language <- function(d, var, props) {
  d_by_language <- unique(d[,c("Language_Name", var)])
  var_full_vals <- unique(c(as.character(d[[var]]), names(props)))
  props_full <- rep(0, length(var_full_vals))
  names(props_full) <- var_full_vals
  props_full[names(props)] <- props
  n_by_var <- floor(nrow(d_by_language)*props_full)
  rows <- unlist(sapply(names(props_full), function(v)
                              sample_rows(d_by_language,
                                          var,
                                          v,
                                          n_by_var[v],
                                          replace=T))) # FIXME - bigger random
  languages <- d_by_language[rows,"Language_Name"]
  result <- d[d$Language_Name %in% languages,]
  return(result)
}

norm_by <- function(d, var, by_names, type) {
  agg_vars <- d[,c(by_names, var)]
  counts <- aggregate(rownames(d), agg_vars, FUN=length)
  names(counts)[3] <- "Count" # FIXME - [3]
  totals <- aggregate(rownames(d), d[,by_names,drop=F], FUN=length)
  names(totals)[2] <- "Total"
  result <- merge(counts, totals)
  result$Relative_Frequency <- result$Count/result$Total
  result$Inventory_Type <- type
  return(result)
}

norm <- function(d, var, type) {
  result <- aggregate(rownames(d), d[,var,drop=F], FUN=length)
  names(result)[2] <- "Count"
  result$Relative_Frequency <- result$Count/nrow(d)
  result$Inventory_Type <- type
  return(result)
}


min_by_language_nf <- function(d, var, type) {
  agg_vars <- d[,c("Language_Name", "Num_Segments")]
  result <- aggregate(d[[var]], agg_vars, FUN=min)
  names(result)[3] <- paste0("Min", "_", var)
  result$Inventory_Type <- type
  return(result)
}

# Plot stats conditional on number of features
plot_cond <- function(d, var, cond_on, ncol=NULL) {
  d$Inventory_Type <- factor(d$Inventory_Type, levels=c("Random", "Plosives",
                                              "Vowels", "Whole Inventory"))
  ggplot(d, aes_string(x=var, y="Relative_Frequency")) +
    geom_line(aes(colour=Inventory_Type), lwd=2) +
    geom_point(size=3.6) +
    geom_point(aes(colour=Inventory_Type), size=3) +
    facet_wrap(formula(paste("~", cond_on)), ncol=ncol) +
    theme(axis.text.x = element_text(size=40),
        axis.text.y = element_text(size=40),
        legend.title = element_text(size=36),
        axis.title.x = element_text(size=36),
        axis.title.y = element_text(size=36),
        legend.text = element_text(size=36),
        strip.text.x = element_text(size=36),
        legend.position="bottom") +
    scale_colour_manual(values=color_palette, drop=F,
                        breaks=unique(d$Inventory_Type))
}

plot_feature_ranks <- function(d, var) {
  d$Inventory_Type <- factor(d$Inventory_Type, levels=c("Random", "Plosives",
                                              "Vowels", "Whole Inventory"))  
  ggplot(d, aes_string(y=var, x="Rank",
                       colour="Inventory_Type")) +
    geom_line(lwd=2) + geom_point(size=3.6, colour="black") +
    scale_colour_manual(values=color_palette, drop=F,
                        breaks=unique(d$Inventory_Type))
}

ranked_stats <- function(d, var, stat, stat_name, type, only_first=F) {
  var_cols <- grep(paste0("^", var), names(d))
  stat_result <- apply(d[,var_cols], 2, stat, na.rm=T)
  stat_result <- stat_result[!is.na(stat_result) & is.finite(stat_result)]
  if (only_first) {
    stat_result <- stat_result[!duplicated(stat_result)]
  }
  var_col_names <- names(stat_result)
  dec_order <- order(stat_result, decreasing=T)
  stat_result_sorted <- stat_result[dec_order]
  feature_names <- substr(var_col_names,
                          nchar(var)+1, nchar(var_col_names))
  result <- data.frame(Feature_Name=feature_names[dec_order],
                       Rank=(1:length(stat_result_sorted)),
                       Inventory_Type=type)
  result[[paste0(stat_name, "_", var)]] <- stat_result_sorted
  return(result)
}

plot_one <- function(d, var) {
  d$Inventory_Type <- factor(d$Inventory_Type, levels=c("Random", "Plosives",
                                              "Vowels", "Whole Inventory"))
  ggplot(d, aes_string(x=var, y="Relative_Frequency")) +
    geom_line(aes(colour=Inventory_Type), lwd=2) +
    geom_point(size=3.6) +
    geom_point(aes(colour=Inventory_Type), size=3) +
    theme(axis.text.x = element_text(size=40),
        axis.text.y = element_text(size=40),
        legend.title = element_text(size=36),
        axis.title.x = element_text(size=36),
        axis.title.y = element_text(size=36),
        legend.text = element_text(size=36),
        legend.position="bottom") +
    scale_colour_manual(values=color_palette, drop=F,
                        breaks=unique(d$Inventory_Type))
}

kld <- function(p_dist, q_dist) {
  p_log_p <- rep(0, length(p_dist))
  p_log_q <- rep(0, length(p_dist))
  p_log_p[p_dist > 0] <- p_dist[p_dist > 0]*log(p_dist[p_dist > 0])
  p_log_q[p_dist > 0 | q_dist > 0] <- p_dist[p_dist > 0 | q_dist > 0] *
                                      log(q_dist[p_dist > 0 | q_dist > 0])
  return(sum(p_log_p - p_log_q))
}

jsd <- function(p_dist, q_dist) {
  m_dist <- 0.5*(p_dist + q_dist)
  return(mean(c(kld(p_dist, m_dist), kld(q_dist, m_dist))))
}

js_missing_levels <- function(d1, d2, var, union=T) {
  if (union) {
    var_levels <- unique(c(d1[[var]], d2[[var]]))
  } else {
    var_levels <- intersect(d1[[var]], d2[[var]])
  }
  p_dist <- rep(0.0, max(var_levels) + 1)
  names(p_dist) <- as.character(0:max(var_levels))
  q_dist <- rep(0.0, max(var_levels) + 1)
  names(q_dist) <- as.character(0:max(var_levels))      
  if (!union) {
    d1 <- d1[d1[[var]] %in% var_levels,]
    d2 <- d2[d2[[var]] %in% var_levels,]
  }
  p_dist[as.character(d1[[var]])] <- d1$Relative_Frequency
  q_dist[as.character(d2[[var]])] <- d2$Relative_Frequency
  return(jsd(p_dist, q_dist))
}

js_by_nf <- function(d1, d2, var) {
  union_nf_levels <- unique(c(d1$Num_Contrastive_Features,
                              d2$Num_Contrastive_Features)) # or intersection?
  intersect_nf_levels <- intersect(unique(d1$Num_Contrastive_Features),
                                   unique(d2$Num_Contrastive_Features))  
  out_nf_levels <- setdiff(union_nf_levels, intersect_nf_levels)
  js_pq_intersect_l <- lapply(intersect_nf_levels, function(l)
                                cbind(js_missing_levels(
                                d1[d1$Num_Contrastive_Features==l,],
                                d2[d2$Num_Contrastive_Features==l,], var), l))  
  js_pq <- as.data.frame(do.call("rbind", js_pq_intersect_l))
  names(js_pq) <- c("JSD", "Num_Contrastive_Features")
  if (length(out_nf_levels) > 0) { # what is this?
    js_pq_out <- cbind(data.frame(out_nf_levels), NA)
    names(js_pq_out) <- c("Num_Contrastive_Features", "JSD")
    js_pq <- rbind(js_pq, js_pq_out)      
  }
  return(js_pq)
}

unifstat <- function(outcomes, n_samples, var) {
  trials <- sample(outcomes, n_samples, replace=T)
  dist <- xtabs(~ trials)
  dist_d <- data.frame(Relative_Frequency=as.vector(dist)/sum(as.vector(dist)))
  dist_d[[var]] <- as.numeric(names(dist))
  return(dist_d)
}

unifstat_by_nf <- function(seed, var) {
  nf <- seed$Num_Contrastive_Features
  nf_levels <- unique(nf)
  result_l <- lapply(nf_levels,
                     function(l) cbind(unifstat(seed[[var]][nf==l],
                                                sum(seed$Count[nf==l]),
                                                var),
                                       Num_Contrastive_Features=l))
  result <- do.call("rbind", result_l)
  return(result)
}

js_boot_by_nf <- function(d1, d2, var, N_boot, seed=d1) {
  r1 <- function(x) x
  r2 <- function(x) x
  if (is.null(d1)) {
    r1 <- function(x) unifstat_by_nf(seed, var)
  }
  if (is.null(d2)) {
    r2 <- function(x) unifstat_by_nf(seed, var)
  }
  samples <- mclapply(1:N_boot, function(i) js_by_nf(r1(d1), r2(d2), var))
  samples_d <- do.call("rbind", samples)
  return(samples_d)
}

# Read pre-computed statistics tables
plosive <- read.csv("plosive_stats.txt")
vowel <- read.csv("vowel_stats.txt")
random <- read.csv("random_stats.txt")
plosive_3 <- plosive[plosive$Num_Segments >= 3,]

# Add two statistics
plosive_3$Sum_Balance_Per_Segment <- with(plosive_3, Sum_Balance/Num_Segments)
vowel$Sum_Balance_Per_Segment <- with(vowel, Sum_Balance/Num_Segments)
random$Sum_Balance_Per_Segment <- with(random, Sum_Balance/Num_Segments)
plosive_3$Num_Segments_By_Num_Contrastive_Features <- with(plosive_3,
                                  Num_Segments/Num_Contrastive_Features)
vowel$Num_Segments_By_Num_Contrastive_Features <- with(vowel,
                                  Num_Segments/Num_Contrastive_Features)
random$Num_Segments_By_Num_Contrastive_Features <- with(random,
                                  Num_Segments/Num_Contrastive_Features)

# Construct SB stats conditional on number of features
plosive3_norm_sb <- norm_by(plosive_3, "Sum_Balance", 
                           "Num_Contrastive_Features",
                           "Plosives")
vowel_norm_sb <- norm_by(vowel, "Sum_Balance", 
                          "Num_Contrastive_Features",
                          "Vowels")
random_norm_sb <- norm_by(random, "Sum_Balance",
                           "Num_Contrastive_Features",
                           "Random")
  
# Plot of SB conditional on number of features
# Vowels versus random
d <- rbind(random_norm_sb, vowel_norm_sb)
d <- d[d$Num_Contrastive_Features < 7,]
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)

# Plosive versus random
d <- rbind(random_norm_sb, plosive3_norm_sb)
d <- d[d$Num_Contrastive_Features < 6,]
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)

# Now do the same plots with number of segments

plosive3_norm_nseg <- norm_by(plosive_3, "Num_Segments",
                              "Num_Contrastive_Features",
                              "Plosives")
vowel_norm_nseg <- norm_by(vowel, "Num_Segments",
                            "Num_Contrastive_Features",
                            "Vowels")
random_norm_nseg <- norm_by(random, "Num_Segments",
                            "Num_Contrastive_Features",
                            "Random")
  
# Vowels - number of segments
d <- rbind(random_norm_nseg, vowel_norm_nseg)
d <- d[d$Num_Contrastive_Features < 7,]
plot_cond(d, "Num_Segments", "Num_Contrastive_Features", 6)

# Plosives - number of segments
d <- rbind(random_norm_nseg, plosive3_norm_nseg)
d <- d[d$Num_Contrastive_Features < 6,]
plot_cond(d, "Num_Segments", "Num_Contrastive_Features", 6)


# Now do the same plots with minimum number of features
plosive3_min <- min_by_language_nf(plosive_3, "Num_Contrastive_Features",
                                           "Plosives")
vowel_min <- min_by_language_nf(vowel, "Num_Contrastive_Features",
                                           "Vowels")
random_min <- min_by_language_nf(random, "Num_Contrastive_Features",
                                        "Random")
plosive3_norm_minnseg <- norm_by(plosive3_min, "Num_Segments",
                                "Min_Num_Contrastive_Features",
                                "Plosives")
vowel_norm_minnseg <- norm_by(vowel_min, "Num_Segments",
                               "Min_Num_Contrastive_Features",
                               "Vowels")
random_norm_minnseg <- norm_by(random_min, "Num_Segments",
                                "Min_Num_Contrastive_Features",
                                "Random")  
# Vowels - number of segments
d <- rbind(random_norm_minnseg, vowel_norm_minnseg)
d <- d[d$Min_Num_Contrastive_Features < 7,]
plot_cond(d, "Num_Segments", "Min_Num_Contrastive_Features", 6)

# Plosives - number of segments
d <- rbind(random_norm_minnseg, plosive3_norm_minnseg)
d <- d[d$Min_Num_Contrastive_Features < 6,]
plot_cond(d, "Num_Segments", "Min_Num_Contrastive_Features", 6)


# 
plosive3_norm_sbps <- norm_by(plosive_3, "Sum_Balance_Per_Segment", 
                           "Num_Contrastive_Features",
                           "Plosives")
vowel_norm_sbps <- norm_by(vowel, "Sum_Balance_Per_Segment", 
                          "Num_Contrastive_Features",
                          "Vowels")
random_norm_sbps <- norm_by(random, "Sum_Balance_Per_Segment",
                           "Num_Contrastive_Features",
                           "Random")
  
# Vowels versus random
d <- rbind(random_norm_sbps, vowel_norm_sbps)
d <- d[d$Num_Contrastive_Features < 7,]
png(file="plots/sbps_cond_nf_vowels_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance_Per_Segment", "Num_Contrastive_Features", 6)
dev.off()

# Plosive versus random
d <- rbind(random_norm_sbps, plosive3_norm_sbps)
d <- d[d$Num_Contrastive_Features < 6,]
png(file="plots/sbps_cond_nf_plosives_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance_Per_Segment", "Num_Contrastive_Features", 6)
dev.off()


# Random size-matched subsamples
vowprops <- summary(factor(vowel$Num_Segments))/nrow(vowel)
randvow <- subsample_by_language(random, "Num_Segments", vowprops)
plosprops <- summary(factor(plosive_3$Num_Segments))/nrow(plosive_3)
randplos <- subsample_by_language(random, "Num_Segments", plosprops)

randvow_norm_sb <- norm_by(randvow, "Sum_Balance",
                                "Num_Contrastive_Features",
                                "Random")    
d <- rbind(randvow_norm_sb, vowel_norm_sb)
d <- d[d$Num_Contrastive_Features < 7,]
png(file="plots/sb_cond_nf_vowels_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)
dev.off()
randplos_norm_sb <- norm_by(randplos, "Sum_Balance",
                                "Num_Contrastive_Features",
                                "Random")
d <- rbind(randplos_norm_sb, plosive3_norm_sb)
d <- d[d$Num_Contrastive_Features < 6,]
png(file="plots/sb_cond_nf_plosives_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)
dev.off()

# Plot num segments per num contrastive features
randvow_norm_nseg <- norm_by(randvow, "Num_Segments",
                                "Num_Contrastive_Features",
                                "Random")    
randplos_norm_nseg <- norm_by(randplos, "Num_Segments",
                                "Num_Contrastive_Features",
                                "Random")
# Vowels
d <- rbind(randvow_norm_nseg, vowel_norm_nseg)
d <- d[d$Num_Contrastive_Features < 7,]
png(file="plots/ns_cond_nf_vowels_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Num_Segments", "Num_Contrastive_Features", 6)
dev.off()
# Plosives
d <- rbind(randplos_norm_nseg, plosive3_norm_nseg)
d <- d[d$Num_Contrastive_Features < 6,]
png(file="plots/ns_cond_nf_plosives_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Num_Segments", "Num_Contrastive_Features", 6)
dev.off()

# Plot num segments per min num contrastive features
randvow_min <- min_by_language_nf(randvow, "Num_Contrastive_Features",
                                        "Random")
randplos_min <- min_by_language_nf(randplos, "Num_Contrastive_Features",
                                        "Random")
randvow_norm_minnseg <- norm_by(randvow_min, "Num_Segments",
                                "Min_Num_Contrastive_Features",
                                "Random")    
randplos_norm_minnseg <- norm_by(randplos_min, "Num_Segments",
                                "Min_Num_Contrastive_Features",
                                "Random")
# Vowels
d <- rbind(randvow_norm_minnseg, vowel_norm_minnseg)
d <- d[d$Min_Num_Contrastive_Features < 7,]
plot_cond(d, "Num_Segments", "Min_Num_Contrastive_Features", 6)
# Plosives
d <- rbind(randplos_norm_minnseg, plosive3_norm_minnseg)
d <- d[d$Min_Num_Contrastive_Features < 6,]
plot_cond(d, "Num_Segments", "Min_Num_Contrastive_Features", 6)

# Plot histogram of S/(min)F
vowel_norm_sf <- norm(vowel,
                      "Num_Segments_By_Num_Contrastive_Features",
                      "Vowels")
plosive3_norm_sf <- norm(plosive_3,
                        "Num_Segments_By_Num_Contrastive_Features",
                        "Plosives")
randvow_norm_sf <- norm(randvow,
                      "Num_Segments_By_Num_Contrastive_Features",
                      "Random")
randplos_norm_sf <- norm(randplos, 
                      "Num_Segments_By_Num_Contrastive_Features",
                      "Random")

png(file="plots/sf_vowels_vs_random.png", width=1600, height=800,
    bg="transparent")
plot_one(rbind(randvow_norm_sf, vowel_norm_sf),
          "Num_Segments_By_Num_Contrastive_Features")
dev.off()
png(file="plots/sf_plosives_vs_random.png", width=1600, height=800,
    bg="transparent")
plot_one(rbind(randplos_norm_sf, plosive3_norm_sf),
          "Num_Segments_By_Num_Contrastive_Features")
dev.off()


# Without unique
plosive_feature_sb <- rbind(ranked_stats(plosive_3,
                   "Sum_Balance_By_Feature_Height",
                   max, "Max", "Plosives"),
                ranked_stats(randplos,
                   "Sum_Balance_By_Feature_Height",
                   max, "Max", "Random"))
vowel_feature_sb <- rbind(ranked_stats(vowel,
                   "Sum_Balance_By_Feature_Height",
                   max, "Max", "Vowels"),
                ranked_stats(randvow,
                   "Sum_Balance_By_Feature_Height",
                   max, "Max", "Random"))
png(file="plots/sb_by_feature_vowels_vs_random.png", width=400, height=400,
    bg="transparent")
plot_feature_ranks(vowel_feature_sb,
                  "Max_Sum_Balance_By_Feature_Height")
dev.off()
png(file="plots/sb_by_feature_plosives_vs_random.png", width=400, height=400,
    bg="transparent")
plot_feature_ranks(plosive_feature_sb,
                  "Max_Sum_Balance_By_Feature_Height")
dev.off()


# Do statistics
N_boot <- 1000
# For number of segments
null_dist <- js_boot_by_nf(NULL, NULL, "Num_Segments", N_boot, random_norm_nseg)
vowel_vs_null_nseg_js_sample <- js_boot_by_nf(vowel_norm_nseg, NULL,
                                              "Num_Segments",
                                              N_boot)
plosive3_vs_null_nseg_js_sample <- js_boot_by_nf(plosive3_norm_nseg,
                                              NULL, "Num_Segments",
                                              N_boot)
vowel_vs_randvow_nseg_js <- js_by_nf(vowel_norm_nseg, randvow_norm_nseg,
                                        "Num_Segments")
plosive3_vs_randplos_nseg_js <- js_by_nf(plosive3_norm_nseg, randplos_norm_nseg,
                                        "Num_Segments")


vowel_vs_randvow_sb_js <- js_by_nf(vowel_norm_sb, randvow_norm_sb,
                                     "Sum_Balance")
plosive3_vs_randplos_sb_js <- js_by_nf(plosive3_norm_sb, randplos_norm_sb,
                                         "Sum_Balance")

