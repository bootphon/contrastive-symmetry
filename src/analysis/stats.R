library(parallel)

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