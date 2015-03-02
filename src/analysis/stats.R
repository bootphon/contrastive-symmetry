library(parallel)
library(foreach)
library(doParallel)
library(pryr)
library(magrittr)
library(reshape)

opt_id_cols <- c("language", "segment_type", "inventory_type")
feature_id_cols <- c("language")

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

js_from_random <- function(n1, n2, set) {
  s1 <- sample(set, n1, replace=T)
  s2 <- sample(set, n2, replace=T)
  ct1 <- complete_distribution(summary(factor(s1)), as.character(set))
  ct2 <- complete_distribution(summary(factor(s2)), as.character(set))
  p1 <- ct1/n1
  p2 <- ct2/n2
  return(jsd(p1, p2))
}

complete_distribution <- function(ct, all_levels) {
  result <- rep(0.0, length(all_levels))
  names(result) <- all_levels
  result[names(ct)] <- ct
  return(result)
}

js_test <- function(ct1, ct2, nboot=1000) {
  all_levels <- unique(c(names(ct1), names(ct2)))
  ct1 <- complete_distribution(ct1, all_levels)
  ct2 <- complete_distribution(ct2, all_levels)
  n1 <- sum(ct1)
  n2 <- sum(ct2)
  p1 <- ct1/n1
  p2 <- ct2/n2
  test_stat <- jsd(p1, p2)
  null_dist <- mclapply(1:nboot, function(i) js_from_random(n1, n2, all_levels))
  pval <- sum(null_dist<=test_stat)/nboot
  return(list(jsd=test_stat, pval=pval))
}

without_na <- function(f, x) {
  x <- na.omit(x)
  if (length(x) == 0) {
    return(NA)
  } else {
    return(f(x))
  }
}
best_sb <- partial(without_na, min)

nseg_by_ncfeat <- function(nseg, ncfeat) {
  return(nseg/ncfeat)
}
best_nseg_by_ncfeat <- partial(without_na, max)

nseg_by_2_ncfeat <- function(nseg, ncfeat) {
  return(nseg/(2^ncfeat))
}
best_nseg_by_2_ncfeat <- partial(without_na, max)

sb_norm <- function(sb, ncfeat) {
  norm <- ifelse(ncfeat==1,
                 1.0, (ncfeat)*(ncfeat-1)/2.0)
  return(sb/norm)
}
best_sb_norm <- partial(without_na, min)


add_cstats <- function(d) {
  result <- d
  result$nseg_by_ncfeat <- result %$% nseg_by_ncfeat(nseg, ncfeat)
  result$nseg_by_2_ncfeat <- result %$% nseg_by_2_ncfeat(nseg, ncfeat)
  result$sb_norm <- result %$% sb_norm(sb, ncfeat)
  return(result)
}

add_opt_cstats <- function(d) {
  result <- ddply(d, opt_id_cols, .fun=function(d) d %$% data.frame(
               best_nseg_by_ncfeat=best_nseg_by_ncfeat(nseg_by_ncfeat),
               best_nseg_by_2_ncfeat=best_nseg_by_2_ncfeat(nseg_by_2_ncfeat),
               best_sb=best_sb(sb),
               best_sb_norm=best_sb_norm(sb_norm)
            ))
  return(result)
}

# FIXME
inventory_id_cols <- c("language", "label")
get_features <- function(x) {
  feature_cols <- -which(names(x) %in% inventory_id_cols)
  result <- as.matrix(x[,feature_cols])
  return(result)
}
# FIXME

feature_abscors <- function(x) {
  cors <- suppressWarnings(cor(x))
  cors[is.na(cors)] <- 1.0
  cors[lower.tri(cors, diag = TRUE)] <- NA
  abscors <- abs(cors)
  result <- melt(abscors)
  names(result) <- c("feature_1", "feature_2", "abscor")
  result <- result[!is.na(result$abscor),]
  return(result)
}

compute_fstats <- function(inventories) {
  registerDoParallel()
  result <- ddply(inventories, feature_id_cols, .parallel=TRUE,
                  .fun=function(d) d %>% get_features %>% feature_abscors)
  return(result)
}