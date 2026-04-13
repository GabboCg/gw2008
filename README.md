# Goyal-Welch (2008, RFS) Replication

Replication of the DP figure from Goyal & Welch (2008, RFS) paper in an XKCD style.

## Overview 

The figure plots the **cumulative sum-of-squared-errors (SSE) difference** between the prevailing mean model and the conditional D/P model, both in-sample (IS) and out-of-sample (OOS). When the line is above zero, the conditional model (using lagged dividend-to-price ratio) predicts the equity premium better than the historical mean; below zero, the mean wins.

The plot is rendered in an **XKCD-style** using a custom `ggplot2` theme (`R/xkcd.R`) with the Humor Sans font, replicating the hand-drawn aesthetic popularized by the [xkcd](https://xkcd.com) webcomic.

The in-sample fit (IS, black) shows modest but consistent improvement from using D/P — adjusted R² of −0.2% and a t-stat of 0.88. Out-of-sample (OOS, blue), the conditional model mostly underperforms the prevailing mean, with a brief exception around the 1973–74 oil shock. The second dashed reference line marks the OOS level at the start of the post-oil-shock period.

## Data

`data/goyal-welch-a.csv` — annual S&P 500 data (1802–2020) from [Amit Goyal's website](http://www.hec.unil.ch/agoyal/). Download the latest version to extend the sample beyond 2020.

## Structure

```
main.R          # main script
R/xkcd.R        # custom XKCD-style ggplot2 theme (Humor Sans)
data/           # raw CSV data
fig/            # output figures
```

## Usage

One-time font setup (requires [Humor Sans](https://github.com/shreyankg/xkcd-desktop/blob/master/Humor-Sans.ttf)):

```r
library(extrafont)
font_import()
```

**Run:**

```r
source("main.R")
```

Output: `fig/gwdp.pdf`

## Dependencies

- R ≥ 4.0
- `ggplot2` ≥ 3.4.0
- `extrafont`
- `tidyr`

## References

- Goyal, A., & Welch, I. (2008). A comprehensive look at the empirical performance of equity premium prediction. *Review of Financial Studies*, 21(4), 1455–1508.
