library(ggplot2)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
color_palette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                   "#0072B2", "#D55E00", "#CC79A7")

sample_rows <- function(d, var, v, n, replace=F) {
  rows_v <- (rownames(d))[as.character(d[[var]]) == v]
  result <- sample(rows_v, n, replace)
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


# Read pre-computed statistics tables
whole <- read.csv("whole_inventory_stats.txt")
plosive <- read.csv("plosive_inventory_stats.txt")
vowel <- read.csv("vowel_inventory_stats.txt")
random <- read.csv("random_inventory_stats.txt")
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
plosive_norm_sb <- norm_by(plosive, "Sum_Balance", 
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
png(file="plots/sb_cond_nf_vowels_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)
dev.off()

# Plosive versus random
d <- rbind(random_norm_sb, plosive_norm_sb)
d <- d[d$Num_Contrastive_Features < 6,]
png(file="plots/sb_cond_nf_plosives_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance", "Num_Contrastive_Features", 6)
dev.off()

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
plosive_norm_sbps <- norm_by(plosive, "Sum_Balance_Per_Segment", 
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
png(file="plots/sb_cond_nf_vowels_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance_Per_Segment", "Num_Contrastive_Features", 6)
dev.off()

# Plosive versus random
d <- rbind(random_norm_sbps, plosive_norm_sbps)
d <- d[d$Num_Contrastive_Features < 6,]
png(file="plots/sb_cond_nf_plosives_vs_random.png", width=1600, height=600,
    bg="transparent")
plot_cond(d, "Sum_Balance_Per_Segment", "Num_Contrastive_Features", 6)
dev.off()


# Random size-matched subsamples
vowprops <- summary(factor(vowel$Num_Segments))/nrow(vowel)
randvow <- subsample_by_language(random, "Num_Segments", vowprops)
plosprops <- summary(factor(plosive_3$Num_Segments))/nrow(plosive_3)
randplos <- subsample_by_language(random, "Num_Segments", plosprops)

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

# Do statistics