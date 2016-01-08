binary_factor_as_logical <- function(x) {
  return(as.logical(as.numeric(x) - 1))
}

positive_prediction_stats_linear_classifier_by_rank <- function(x, y_true, extend=T) {
  x_orig <- x
  y_true_orig <- y_true
  x <- x[!is.na(x_orig) & !is.na(y_true_orig)]
  y_true <- y_true[!is.na(x_orig) & !is.na(y_true_orig)]
  n <- length(x)
  y_true_bool <- binary_factor_as_logical(y_true)
  y_true_bool_ordered <- y_true_bool[order(x)]
  descending_tp <- cumsum(rev(y_true_bool_ordered))
  descending_fp <- 1:n - descending_tp
  all_pos <- sum(y_true_bool_ordered)
  all_neg <- n - all_pos
  if (all_pos==0) {
    descending_tpr <- rep(0., n)
  } else {
    descending_tpr <- descending_tp/all_pos
  }
  if (all_neg==0) {
    descending_fpr <- rep(1., n)
  } else {
    descending_fpr <- descending_fp/all_neg
  }
  last_entry <- rev(!duplicated(x[order(x)]))
  tpr_by_rank <- descending_tpr[last_entry]
  fpr_by_rank <- descending_fpr[last_entry]
  if (extend) {
    tpr_by_rank <- c(0.0, tpr_by_rank)
    fpr_by_rank <- c(0.0, fpr_by_rank)
  }
  result <- data.frame(tpr=tpr_by_rank, fpr=fpr_by_rank)
  return(result)
}

pred_stats <- function(sim, same) {
    pred_stats <- positive_prediction_stats_linear_classifier_by_rank(sim, same)
    pred_stats_above_zero <- pred_stats[pred_stats$tpr > 0 |
                                        pred_stats$fpr > 0,,drop=F]
    pred_stats_above_zero <- with(pred_stats_above_zero,
                                  aggregate(tpr, by=list(fpr=fpr), FUN=max))
    names(pred_stats_above_zero)[2] <- "tpr"
    pred_stats_zero <- pred_stats[pred_stats$tpr <= 0 &
                                  pred_stats$fpr <= 0,c("tpr","fpr"),drop=F]
    pred_stats <- rbind(pred_stats_zero, pred_stats_above_zero)
    return(pred_stats)
}


integrate_finite <- function(x, y) {
  x <- x[!is.na(x) & !is.na(y)]
  y <- y[!is.na(x) & !is.na(y)]
  x_vals <- x[order(x)]
  y_vals <- y[order(x)]
  deltas <- x_vals[2:length(x_vals)] - x_vals[1:(length(x_vals) - 1)]
  heights <- (y_vals[2:length(y_vals)] + y_vals[1:(length(y_vals) - 1)])/2.
  return(sum(heights*deltas))
}

auc <- function(tpr, fpr) {
  auc_partial <- integrate_finite(fpr, tpr)
  box_area <- (max(fpr, na.rm=T)-min(fpr, na.rm=T))*
    (max(tpr, na.rm=T)-min(tpr, na.rm=T))
  if (box_area > 0.0 & box_area < 1.0)  {
    warning(paste0("Only partial ROC was calculated (area ", box_area, ")"))
    browser()
    return(auc_partial/box_area)
  }
  return(auc_partial)
}

auc_by <- function(d, measure, classes, goldleft) {
  if (!(length(unique(d[[classes]])) == 2)) {
    stop("need exactly two classes")
  }
  if (!(goldleft %in% unique(d[[classes]]))) {
    stop("need gold left class in the class list")
  }
  classes_f <- factor(d[[classes]])
  if (goldleft != levels(classes_f)[1]) {
    classes_f <- relevel(classes_f, goldleft)
  }
  return(with(pred_stats(d[[measure]], classes_f), auc(tpr, fpr)))
}
