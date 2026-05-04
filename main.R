#!/usr/bin/env Rscript
# ======================================================== #
#
#                     Goyal-Welch Plot
#
#                 Gabriel E. Cabrera-Guzmán
#                The University of Manchester
#
#                       Spring, 2026
#
#                https://gcabrerag.rbind.io
#
# ------------------------------ #
# email: gabriel.cabreraguzman@postgrad.manchester.ac.uk
# ======================================================== #

# Load packages
library(ggplot2)   # >= 3.4.0 required for scale_linewidth_manual()
library(extrafont) # Humor Sans font for xkcd theme

# Load auxiliary functions
source("R/xkcd.R")

# Load extra fonts
loadfonts(quiet = TRUE)

# download the latest version from Amit Goyal's website
dsraw <- read.csv("data/goyal-welch-a.csv")  

# to perfectly replicate GW, use ds <- subset(dsraw, dsraw$yyyy<=2005)
ds <- within(dsraw, {
  
    spret  <- (sp500index + sp500d12) / c(NA, head(sp500index, -1)) - 1
    logeqp <- log(1.0 + spret - tbill / 100.0)
    lagdp  <- c(NA, head(sp500d12, -1)) / c(NA, head(sp500index, -1))
    
})

ds <- subset(ds, ds$yyyy >= 1872, select = c("yyyy", "logeqp", "lagdp"))
print(summary(ds))

# in-sample residuals are easy
is_xyresid <- residuals(lm(logeqp ~ lagdp, data = ds))
is_meanresid <- ds$logeqp - mean(ds$logeqp)

isreg <- summary(lm(logeqp ~ lagdp, data = ds))
print(isreg)

tstat <- round(coef(isreg)[2,3], 2)
rsq <- round(isreg$adj.r.squared, 3) * 100
lyr <- tail(ds$yyyy, 1)

# out-of-sample residuals need 20 years of data
firstyear <- 20
oos_xyresid <- oos_meanresid <- rep(NA, nrow(ds))

for (i in firstyear:nrow(ds)) {
  
    oos_meanpred <- mean(ds$logeqp[1:i])
    oos_meanresid[i + 1] <- ds$logeqp[i + 1] - oos_meanpred

    oos_lmcoef <- coef(lm(logeqp ~ lagdp, data = ds[1:i,]))
    oos_pred <- oos_lmcoef[1] + oos_lmcoef[2] * ds$lagdp[i + 1]
    oos_xyresid[i + 1] <- ds$logeqp[i + 1] - oos_pred
    
}

# now create a plotwork-related data set
plotwork <- data.frame(
  yyyy = ds$yyyy, 
  is_meanresid = is_meanresid, 
  is_xyresid = is_xyresid,
  oos_meanresid = oos_meanresid[1:nrow(ds)], 
  oos_xyresid=oos_xyresid[1:nrow(ds)] 
)

# done
rm(ds)  

plotwork[firstyear,] <- c(plotwork$yyyy[firstyear - 1] + 1, 0, 0, 0, 0)

plotwork <- plotwork[complete.cases(plotwork),]
rownames(plotwork) <- NULL

plotwork <- within(plotwork, {
  
    is.improvement <- cumsum(plotwork$is_meanresid ^ 2) - cumsum( is_xyresid ^ 2)
    oos.improvement <- cumsum(oos_meanresid ^ 2) - cumsum( oos_xyresid ^ 2)
    
})

plotlong <- rbind(
  data.frame(yyyy = plotwork$yyyy, improvement = plotwork$is.improvement,  type = "IS"),
  data.frame(yyyy = plotwork$yyyy, improvement = plotwork$oos.improvement, type = "OOS")
)

annotateloc  <- plotwork$yyyy[35] # ~year 1906, label placement
is_val_ann   <- plotwork$is.improvement[35]
oos_val_ann  <- plotwork$oos.improvement[35]
oos_ref_line <- plotwork$oos.improvement[72] # ~year 1943 dashed ref

# --- Theme XKCD ---
theme_xkcd <- theme(
  panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.75),
  panel.background = element_rect(fill = "white"), 
  axis.ticks.length = unit(0.125, "cm"),
  panel.grid = element_line(colour = "white"),
  axis.text.y = element_text(colour = "black"), 
  axis.text.x = element_text(colour = "black"),
  axis.line = element_line(colour = "black"),
  text = element_text(size = 16, family = "Humor Sans")
)

# --- Plot --- 
plotlong |>
  tidyr::pivot_wider(names_from = "type", values_from = improvement) |>
  ggplot() +
  # Oil shock band
  annotate("rect", xmin = 1973, xmax = 1975, ymin = -Inf, ymax = Inf,
           fill = "red", alpha = 1, color = "black") +
  annotate("text", x = 1977, y = -0.15, label = "Oil Shock (1974)",
           angle = 90, color = "red", size = 3.5, family = "Humor Sans") +
  # Lines
  geom_line(aes(x = yyyy, y = OOS), color = "white", linewidth = 1.9) +
  geom_line(aes(x = yyyy, y = OOS), color = "blue", linewidth = 1.1) +
  geom_line(aes(x = yyyy, y = IS), color = "white", linewidth = 1.9) +
  geom_line(aes(x = yyyy, y = IS), color = "black", linewidth = 1.1) +
  # Reference lines
  geom_hline(yintercept = 0, linetype = "dashed") +
  annotate("segment", x = plotwork$yyyy[72], xend = Inf,
           y = oos_ref_line, yend = oos_ref_line, linetype = "dashed") +
  # Direct line labels
  annotate("text", x = annotateloc, y = is_val_ann + 0.010,
           label = "IS", color = "black", vjust = 0, family = "Humor Sans") +
  annotate("text", x = annotateloc, y = oos_val_ann - 0.015,
           label = "OOS", color = "blue", vjust = 1, family = "Humor Sans") +
  # Arrows and explanatory labels
  annotate("segment", x = 1890, xend = 1895, y = -0.12, yend = -0.08,
           color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
  annotate("text", x = 1912, y = -0.08, color = "black", size = 3.5,
           label = "Conditional Model\nPredicts better", family = "Humor Sans") +
  annotate("segment", x = 1890, xend = 1895, y = -0.13, yend = -0.17,
           color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
  annotate("text", x = 1910, y = -0.17, color = "black", size = 3.5,
           label = "Prevailing Mean\nPredicts better", family = "Humor Sans") +
  # Data info and stats
  annotate("text", x = 1890, y = 0.16, hjust = 0, size = 3.5, color = "black",
           label = paste0("Dependent: Log Equity Premium\nIndependent: Lagged D/P\nData: 1872 (1892) to ", lyr),
           family = "Humor Sans") +
  annotate("text", x = 1985, y = 0.13, hjust = 0, size = 3.5, color = "black",
           label = paste0("IS T-stat: ", tstat, "\nIS Adj R^2: ", rsq, "%"),
           family = "Humor Sans") +
  # Scales and theme
  scale_y_continuous(limits = c(-0.2, 0.2)) +
  scale_x_continuous(limits = c(1880, 2020) , breaks = seq(1880, 2020, 20)) +
  labs(x = "Year", y = "Cumulative SSE Difference") +
  theme_xkcd

# Save figures
ggsave("figures/gwdp.pdf", width = 7.25, height = 5, device = cairo_pdf)
