library(magrittr)
library(pryr)
library(scatterplot3d)

# palette from http://jfly.iam.u-tokyo.ac.jp/color/
default_colour_palette <- c(Random="#E69F00", Natural="#56B4E9") 
random_types_palette <- c("#E69F00", "#56B4E9", "#CC79A7", "#0072B2",
                          "#D55E00")
names(random_types_palette) <- c("Control",
                                 "Natural",
                                 "Asymmetrical",
                                 "deBoer", "Uniform")
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
                                        initial_plot=NULL,
                                        legend="bottom") {
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
  p <- p + theme(legend.position=legend)
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
                       legend="bottom",
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
  p <- p + theme(legend.position=legend) +
    scale_fill_manual(values=palette, drop=F, name=group_label,
                        breaks=levels(d[[group]])) +
    scale_colour_manual(values=palette, drop=F, name=group_label,
                        breaks=levels(d[[group]])) +
    ylab(dep_measure_label)    
  return(p)
}

cube <- function(x, y, z, two=T, corner_text_outside=NULL,
                 corner_text_inside=NULL, corner_text_cex=1.0, 
                 point_cex=1.0, square=F, 
                 xlab_text=NULL, zlab_text=NULL, ylab_text=NULL, ...) {
  TXTO <- 0.17
  AXTXCX <- 0.6*corner_text_cex
  p <- scatterplot3d(x, y, z, grid=F, box=F, axis=F,
                     xlim=c(0,1), ylim=c(0,1), zlim=c(-TXTO,1+TXTO),
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
    corners <- list(c(0,0,-TXTO), c(0,0,1+TXTO),
                            c(1,0,-TXTO), c(1,0,1+TXTO),
                            c(0,1,-TXTO), c(0,1,1+TXTO),
                            c(1,1,-TXTO), c(1,1,1+TXTO))
    for (i in 1:min(length(corners), length(corner_text_outside))) {
      text(p$xyz.convert(corners[[i]][1], corners[[i]][2],
                         corners[[i]][3]),
           labels=corner_text_outside[i], cex=corner_text_cex)
    }
  }
  if (!is.null(corner_text_inside)) {
    corners <- list(c(1/4,1/4,1/4-TXTO), c(1/4,1/4,3/4+TXTO),
                    c(3/4,1/4,1/4-TXTO), c(3/4,1/4,3/4+TXTO),
                    c(1/4,3/4,1/4-TXTO), c(1/4,3/4,3/4+TXTO),
                    c(3/4,3/4,1/4-TXTO), c(3/4,3/4,3/4+TXTO))
    for (i in 1:min(length(corners), length(corner_text_inside))) {
      text(p$xyz.convert(corners[[i]][1], corners[[i]][2],
                         corners[[i]][3]),
           labels=corner_text_inside[i], cex=corner_text_cex)
    }
  }  
  if (!is.null(xlab_text)) {
    text(p$xyz.convert(1/2, 0, -TXTO), labels=xlab_text,
         cex=AXTXCX)
  }
  if (!is.null(ylab_text)) {
    text(p$xyz.convert(1.2+TXTO, 0.19, 0), labels=ylab_text,
         cex=AXTXCX)
  }  
   if (!is.null(zlab_text)) {
    text(p$xyz.convert(1.2, TXTO, 0.5), labels=zlab_text,
         cex=AXTXCX)
  }   
}

thickline3d <- function(along, to, other1, other2,
                        npoints=1000, thickness=0.005,
                        smoothness=100, color="black", ...) {
  pointseq <- seq(0, to, length.out=npoints)
  if (along == "x") {
    pointmat <- cbind(pointseq, other1, other2)
  } else if (along == "y") {
    pointmat <- cbind(other1, pointseq, other2)
  } else if (along == "z") {
    pointmat <- cbind(other1, other2, pointseq)
  }
  shade3d(cylinder3d(pointmat, radius=thickness, sides=smoothness),
          col=color, lit=F, ...)
}


points3d <- function (x, y, z,
                      xlab = deparse(substitute(x)),
                      ylab = deparse(substitute(y)), 
                      zlab = deparse(substitute(z)),
                      axis.scales = TRUE, labels = as.character(seq(along = x)),
                      point.col = "yellow", axis.col=c("black","black", "black"),
                      text.col = axis.col,  surface.col="yellow",
                      fill = TRUE, grid = TRUE, 
                      sphere.size = 1, threshold = 0.01, 
                      groups = NULL,  ellipsoid = FALSE,
                      level = 0.5, ellipsoid.alpha = 0.1, linewidth=0.02,
                      linealpha=1.0,
                      minx=NULL, maxx=NULL, miny=NULL, maxy=NULL, minz=NULL, maxz=NULL,
                      xlabx=0.6, xlaby=0, xlabz=1.5,
                      ylabx=0, ylaby=0.38, ylabz=1.32,
                      zlabx=1.25, zlaby=0, zlabz=0.41,
                      plot.points=T, ell.n=50, plane.color="#dddddd", text.cex=1.0, ...) 
{
  if (!require(rgl)) 
    stop("rgl package missing")
  if (!require(mgcv)) 
    stop("mgcv package missing")
  
  showLabels3d <- car::: showLabels3d  
  nice <- car:::nice  
  summaries <- list()
  if ((!is.null(groups)) && (nlevels(groups) > length(surface.col))) 
    stop(sprintf("Number of groups (%d) exceeds number of colors (%d)"), 
         nlevels(groups), length(surface.col))
  if ((!is.null(groups)) && (!is.factor(groups))) 
    stop("groups variable must be a factor")
  rgl.clear()
  rgl.bg(color="white")
  valid <- if (is.null(groups)) 
    complete.cases(x, y, z)
  else complete.cases(x, y, z, groups)
  x <- x[valid]
  y <- y[valid]
  z <- z[valid]
  labels <- labels[valid]
  if (is.null(minx)) minx <- min(x)
  if (is.null(maxx)) maxx <- max(x)
  if (is.null(miny)) miny <- min(y)
  if (is.null(maxy)) maxy <- max(y)
  if (is.null(minz)) minz <- min(z)
  if (is.null(maxz)) maxz <- max(z)
  if (axis.scales) {
    lab.min.x <- nice(minx)
    lab.max.x <- nice(maxx)
    lab.min.y <- nice(miny)
    lab.max.y <- nice(maxy)
    lab.min.z <- nice(minz)
    lab.max.z <- nice(maxz)
    minx <- min(lab.min.x, minx)
    maxx <- max(lab.max.x, maxx)
    miny <- min(lab.min.y, miny)
    maxy <- max(lab.max.y, maxy)
    minz <- min(lab.min.z, minz)
    maxz <- max(lab.max.z, maxz)
    min.x <- (lab.min.x - minx)/(maxx - minx)
    max.x <- (lab.max.x - minx)/(maxx - minx)
    min.y <- (lab.min.y - miny)/(maxy - miny)
    max.y <- (lab.max.y - miny)/(maxy - miny)
    min.z <- (lab.min.z - minz)/(maxz - minz)
    max.z <- (lab.max.z - minz)/(maxz - minz)
  }
  if (!is.null(groups)) 
    groups <- groups[valid]
  x <- (x - minx)/(maxx - minx)
  y <- (y - miny)/(maxy - miny)
  z <- (z - minz)/(maxz - minz)
  size <- sphere.size * ((100/length(x))^(1/3)) * 0.015
  if (plot.points) {
    if (is.null(groups)) {
      if (size > threshold) 
        rgl.spheres(x, y, z, color = point.col, radius = size)
      else rgl.points(x, y, z, color = point.col)
    }
    else {
      if (size > threshold) 
        rgl.spheres(x, y, z, color = surface.col[as.character(groups)], 
                    radius = size)
      else rgl.points(x, y, z, color = surface.col[as.character(groups)])
    }
  } else {
    xm <- aggregate(x, by=list(groups), FUN=mean)$x
    ym <- aggregate(y, by=list(groups), FUN=mean)$x
    zm <- aggregate(z, by=list(groups), FUN=mean)$x
    rgl.spheres(xm, ym, zm, color="black", radius = size, lit=F)
    for (i in 1:length(levels(groups))) {
      lev <- levels(groups)[i]
      thickline3d(along="z", to=zm[i], other1=xm[i], ym[i], thickness=linewidth,
                  color=surface.col[lev], alpha=linealpha)
      thickline3d(along="y", to=ym[i], other1=xm[i], zm[i], thickness=linewidth,
                  color=surface.col[lev], alpha=linealpha)
      thickline3d(along="x", to=xm[i], other1=ym[i], zm[i], thickness=linewidth,
                  color=surface.col[lev], alpha=linealpha)
      
      thickline3d(along="z", to=zm[i], other1=xm[i], ym[i]+linewidth, 
                  thickness=linewidth/10., color="black", alpha=linealpha)
      thickline3d(along="z", to=zm[i], other1=xm[i], ym[i]-linewidth, 
                  thickness=linewidth/10., color="black", alpha=linealpha)
      thickline3d(along="y", to=ym[i], other1=xm[i], zm[i]+linewidth, 
                  thickness=linewidth/10., color="black", alpha=linealpha)
      thickline3d(along="y", to=ym[i], other1=xm[i], zm[i]-linewidth, 
                  thickness=linewidth/10., color="black", alpha=linealpha)
      thickline3d(along="x", to=xm[i], other1=ym[i]+linewidth, zm[i],
                  thickness=linewidth/10., color="black", alpha=linealpha)
      thickline3d(along="x", to=xm[i], other1=ym[i]-linewidth, zm[i],
                  thickness=linewidth/10., color="black", alpha=linealpha)
    }
  } 
  if (!axis.scales) 
    axis.col[1] <- axis.col[3] <- axis.col[2]
  for (p in seq(0,1,1/4.)) {
    thickline3d(along="x", to=1.05, other1=p, other2=0)
    thickline3d(along="x", to=1.05, other1=0, other2=p)
    thickline3d(along="y", to=1.05, other1=p, other2=0)
    thickline3d(along="y", to=1.05, other1=0, other2=p)
    thickline3d(along="z", to=1.05, other1=p, other2=0)
    thickline3d(along="z", to=1.05, other1=0, other2=p)
  }
  {
    l <- cube3d(cbind(c(1,0,0,0), c(0,1,0,0), c(0,0,0,-0.001), c(0,0,0,1)))
    l$vb[l$vb==-1] <- 0
    shade3d(l, color=plane.color, lit=F)
    l <- cube3d(cbind(c(1,0,0,0), c(0,0,0, -0.001), c(0,1,0,0), c(0,0,0,1)))
    l$vb[l$vb==-1] <- 0
    shade3d(l, color=plane.color, lit=F)
    l <- cube3d(cbind(c(0, 0, 0, -0.001), c(1,0,0,0), c(0,1,0,0), c(0,0,0,1)))
    l$vb[l$vb==-1] <- 0
    shade3d(l, color=plane.color, lit=F)
  }
  text3d(zlabx, zlaby, zlabz, zlab, adj = 1, color = axis.col[1],  useFreeType = T,
         family="serif", cex=text.cex, font=2)
  text3d(xlabx, xlaby, xlabz, xlab, adj = 1, color = axis.col[2], useFreeType = T,
         family="serif", cex=text.cex, font=2)
  text3d(ylabx, ylaby, ylabz, ylab, adj = 1, color = axis.col[3],  useFreeType = T,
         family="serif", cex=text.cex, font=2)
  if (axis.scales) {
    x.labels <-  seq(lab.min.x, lab.max.x, by=diff(range(lab.min.x, lab.max.x))/4)
    x.at <- seq(min.x, max.x, by=diff(range(min.x, max.x))/4)
    rgl.texts(x.at, 0, 1.1, x.labels, col = axis.col[1],
              family="serif", useFreeType = T, cex=text.cex)
    
    z.labels <-  seq(lab.min.z, lab.max.z, by=diff(range(lab.min.z, lab.max.z))/4)
    z.at <- seq(min.z, max.z, by=diff(range(min.z, max.z))/4)
    rgl.texts(1.1, 0, z.at, z.labels, col = axis.col[3],
              family="serif", useFreeType = T, cex=text.cex)
    
    y.labels <-  seq(lab.min.y, lab.max.y, by=diff(range(lab.min.y, lab.max.y))/4)
    y.at <- seq(min.y, max.y, by=diff(range(min.y, max.y))/4)
    rgl.texts(0, y.at, 1.1, y.labels, col = axis.col[2],
              family="serif", useFreeuseFreeType = T, cex=text.cex)
  }
  if (ellipsoid) {
    dfn <- 3
    if (is.null(groups)) {
      dfd <- length(x) - 1
      radius <- sqrt(dfn * qf(level, dfn, dfd))
      ellips <- car:::ellipsoid(center = c(mean(x), mean(y), 
                                           mean(z)), shape = cov(cbind(x, y, z)), radius = radius)
      if (fill) 
        shade3d(ellips, col = surface.col[1], alpha = ellipsoid.alpha, 
                lit = FALSE)
      if (grid) 
        wire3d(ellips, col = surface.col[1], lit = FALSE)
    } else {
      levs <- levels(groups)
      for (j in 1:length(levs)) {
        group <- levs[j]
        select.obs <- groups == group
        xx <- x[select.obs]
        yy <- y[select.obs]
        zz <- z[select.obs]
        dfd <- length(xx) - 1
        radius <- sqrt(dfn * qf(level, dfn, dfd))
        ellips <- car:::ellipsoid(center = c(mean(xx), mean(yy), 
                                             mean(zz)), shape = cov(cbind(xx, yy, zz)), 
                                  radius = radius, n=ell.n)
        if (fill) 
          shade3d(ellips, col = surface.col[group], alpha = ellipsoid.alpha, 
                  lit = F)
        if (grid) 
          wire3d(ellips, col = surface.col[group], lit = FALSE)
        coords <- ellips$vb[, which.max(ellips$vb[1,])]
      }
    }
  }

}
