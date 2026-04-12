# Design: ggplot2 + xkcd Rewrite of goyal-welch-plots.R

**Date:** 2026-04-12
**Scope:** Rewrite `goyal-welch-plots.R` to remove the `iaw` environment dependency and replace the base R plotting block with ggplot2 + the `xkcd` package, replicating the existing comic-style figure in `fig/gwdp.pdf`.

---

## Approach

Minimal refactor (Approach A): keep the same script structure and SSE computation logic unchanged. Only:
1. Remove all `iaw$` calls, replacing with direct base R or ggplot2 equivalents.
2. Swap the base R `plot()`/`lines()`/`text()`/`arrows()` block for a single `ggplot()` call.
3. Add `library()` calls at the top.

Working-directory convention is preserved: data read from `"goyal-welch-a.csv"` and output saved to `"gwdp.pdf"`, both relative to the working directory.

---

## Section 1: Dependencies

Replace the `iaw` environment checks and `cat()` preamble with explicit library imports at the top of the script:

```r
library(ggplot2)   # >= 3.4.0 required for scale_linewidth_manual()
library(xkcd)
library(extrafont) # required by xkcd for Humor Sans font
loadfonts(quiet = TRUE)  # loads installed fonts; Humor Sans must be pre-installed via font_import()
```

Direct replacements for each `iaw$` function and the standalone `last()` call:

| Old | Source | New |
|---|---|---|
| `iaw$lagseries(x)` | `iaw` env | `c(NA, head(x, -1))` |
| `iaw$residuals(lm(...))` | `iaw` env | `residuals(lm(...))` |
| `last(ds$yyyy, 1)` | unknown external (not `iaw$`) | `tail(ds$yyyy, 1)` |
| `iaw$pdf.start("gwdp.pdf")` | `iaw` env | `ggsave("gwdp.pdf", plot = p, width = 8, height = 5)` |
| `iaw$hline(0, lty=2)` | `iaw` env | `geom_hline(yintercept = 0, linetype = "dashed")` |
| `iaw$p.arrows(...) + text(...)` | `iaw` env | `annotate("segment", arrow = ...) + annotate("text", ...)` |
| `iaw$pdf.end()` | `iaw` env | *(removed — `ggsave` replaces the pdf open/close pair)* |

Note: `tstat`, `rsq`, and `lyr` are already computed in the existing script from the `lm()` summary object and are retained unchanged:
- `tstat <- round(coef(isreg)[2,3], 2)` (t-statistic of D/P coefficient, 2 decimal places)
- `rsq   <- round(isreg$adj.r.squared, 3) * 100` (adjusted R², as percentage)
- `lyr   <- tail(ds$yyyy, 1)` (last year in data, replaces `last(ds$yyyy, 1)`)

---

## Section 2: Data Reshaping

`plotwork` is built as before (wide format). Before plotting, reshape to long format using base R `rbind` — no new dependencies:

```r
plotlong <- rbind(
  data.frame(yyyy = plotwork$yyyy, improvement = plotwork$is.improvement,  type = "IS"),
  data.frame(yyyy = plotwork$yyyy, improvement = plotwork$oos.improvement, type = "OOS")
)
```

`type` maps to `color` and `linewidth` aesthetics in ggplot2.

---

## Section 3: Plot Construction

**Fixed constants** (same as current script — hardcoded, not derived from data):
- Oil shock band: `xmin = 1973`, `xmax = 1975`
- Oil shock label: `x = 1977`, `y = -0.15`
- Arrow bases: `x = 1890`, `xend = 1895`
- Arrow tip y-values and text positions: as in current script

**Runtime-derived values** (computed from `plotwork` before the ggplot call):

```r
# Row 35 = year ~1906 (35th obs in 1872-start subset); used for line label placement
annotateloc  <- plotwork$yyyy[35]
is_val_ann   <- plotwork$is.improvement[35]
oos_val_ann  <- plotwork$oos.improvement[35]

# Row 72 = year ~1943; the horizontal dashed reference matching the current script's
# lines(c(yyyy[72], 2100), rep(oos.improvement[72], 2), lty=2)
oos_ref_line <- plotwork$oos.improvement[plotwork$yyyy == plotwork$yyyy[72]]
```

```r
p <- ggplot(plotlong, aes(x = yyyy, y = improvement, color = type, linewidth = type)) +
  # Oil shock band (fixed constants)
  annotate("rect", xmin = 1973, xmax = 1975, ymin = -Inf, ymax = Inf, fill = "red", alpha = 0.4) +
  annotate("text", x = 1977, y = -0.15, label = "Oil Shock (1974)", angle = 90,
           color = "red", size = 3) +
  # Lines
  geom_line() +
  scale_color_manual(values = c("IS" = "black", "OOS" = "blue")) +
  scale_linewidth_manual(values = c("IS" = 0.8, "OOS" = 1.2)) +
  # Reference lines
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = oos_ref_line, linetype = "dashed") +
  # Direct line labels (runtime-derived positions)
  annotate("text", x = annotateloc, y = is_val_ann + 0.01,  label = "IS",
           color = "black", vjust = 0) +
  annotate("text", x = annotateloc, y = oos_val_ann - 0.01, label = "OOS",
           color = "blue",  vjust = 1) +
  # Arrows and explanatory labels (fixed constants, black)
  annotate("segment", x = 1890, xend = 1895, y = -0.12, yend = -0.08,
           color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
  annotate("text", x = 1909, y = -0.09, color = "black",
           label = "Conditional Model\nPredicts better", size = 3) +
  annotate("segment", x = 1890, xend = 1895, y = -0.13, yend = -0.17,
           color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
  annotate("text", x = 1909, y = -0.16, color = "black",
           label = "Prevailing Mean\nPredicts better", size = 3) +
  # Data info and stats annotations (runtime-derived text, fixed positions)
  annotate("text", x = 1890, y = 0.16, hjust = 0, size = 3, color = "black",
           label = paste0("Dependent: Log Equity Premium\nIndependent: Lagged D/P\nData: 1872 (1892) to ", lyr)) +
  annotate("text", x = 1985, y = 0.13, hjust = 0, size = 3, color = "black",
           label = paste0("IS T-stat: ", tstat, "\nIS Adj R^2: ", rsq, "%")) +
  # Scales and labels
  scale_y_continuous(limits = c(-0.2, 0.2)) +
  labs(x = "Year", y = "Cumulative SSE Difference") +
  theme_xkcd() +
  theme(legend.position = "none")

ggsave("gwdp.pdf", plot = p, width = 8, height = 5)
```

---

## Files Changed

| File | Change |
|---|---|
| `goyal-welch-plots.R` | In-place rewrite: remove `iaw` env checks + `cat()` preamble; add `library()` + `loadfonts()`; replace base R plot block with ggplot2 + xkcd |
| `CLAUDE.md` | Remove the note about `iaw` environment dependency; update "Running the Analysis" to reflect self-contained `source("goyal-welch-plots.R")` with no pre-loading required |

---

## Out of Scope

- Restructuring into multiple files
- Changing data path conventions
- Tidyverse data manipulation
- Adding new analyses or extending the date range
