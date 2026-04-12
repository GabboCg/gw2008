# ggplot2 + xkcd Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `goyal-welch-plots.R` to be self-contained (no `iaw` environment) and replace the base R plot with ggplot2 + the `xkcd` package, producing the same comic-style figure.

**Architecture:** Single-script minimal refactor — the SSE computation logic is untouched; only the `iaw$` calls are replaced with direct equivalents and the base R plot block is replaced with a ggplot2 call. Data flows: CSV → wide `plotwork` df → long `plotlong` df → ggplot object → `gwdp.pdf`.

**Tech Stack:** R, ggplot2 (>= 3.4.0), xkcd, extrafont

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `goyal-welch-plots.R` | Modify | Main script — all changes happen here |
| `CLAUDE.md` | Modify | Remove `iaw` env note; update "Running the Analysis" section |

---

### Task 1: Replace `iaw` checks and add libraries

**Files:**
- Modify: `goyal-welch-plots.R` (lines 1–16)

- [ ] **Step 1: Open the file and locate the preamble**

  Lines 1–16 are the `cat()` message and the five `if (!exists(...))` checks that define the `iaw` environment. These are entirely replaced.

- [ ] **Step 2: Replace the preamble with library imports**

  Delete lines 1–16 and replace with:

  ```r
  ################################################################
  ## Replication of Goyal-Welch (RFS, July 2008)
  ## Cumulative SSE difference: conditional (D/P) vs. prevailing mean
  ################################################################

  library(ggplot2)   # >= 3.4.0 required for scale_linewidth_manual()
  library(xkcd)
  library(extrafont) # Humor Sans font for xkcd theme
  loadfonts(quiet = TRUE)
  ```

  Note: `font_import()` is a one-time setup step the user must run once in their R session before first use. It is NOT added to the script.

- [ ] **Step 3: Verify the file loads without error**

  In R console (working directory = project root):
  ```r
  # Just check syntax — don't source fully yet
  parse(file = "goyal-welch-plots.R")
  ```
  Expected: no parse errors.

- [ ] **Step 4: Commit**

  ```bash
  git add goyal-welch-plots.R
  git commit -m "refactor: replace iaw preamble with library imports"
  ```

---

### Task 2: Replace `iaw$lagseries` and `last()` calls

**Files:**
- Modify: `goyal-welch-plots.R` (data prep block, ~lines 19–29)

The current script uses:
- `iaw$lagseries(x)` in three places (lines 24, 26, 27)
- `last(ds$yyyy, 1)` on line 42

- [ ] **Step 1: Replace `iaw$lagseries` calls**

  Find all three occurrences and replace inline:

  | Old | New |
  |---|---|
  | `iaw$lagseries(sp500index)` | `c(NA, head(sp500index, -1))` |
  | `iaw$lagseries(sp500d12)` | `c(NA, head(sp500d12, -1))` |

  In `within(dsraw, {...})` block, the full lines become:
  ```r
  spret  <- (sp500index + sp500d12) / c(NA, head(sp500index, -1)) - 1
  logeqp <- log(1.0 + spret - tbill / 100.0)
  lagdp  <- c(NA, head(sp500d12, -1)) / c(NA, head(sp500index, -1))
  ```

- [ ] **Step 2: Replace `last()` call**

  Line `lyr <- last(ds$yyyy, 1)` → `lyr <- tail(ds$yyyy, 1)`

- [ ] **Step 3: Replace `iaw$residuals` call**

  Line `is.xyresid <- iaw$residuals(lm(logeqp ~ lagdp, data=ds))` → `is.xyresid <- residuals(lm(logeqp ~ lagdp, data=ds))`

- [ ] **Step 4: Verify data prep produces correct output**

  ```r
  source("goyal-welch-plots.R")
  # Script will error at the plotting section (not yet rewritten), but check:
  # - plotwork exists and has correct shape
  print(dim(plotwork))   # should be ~130 rows × 6 columns
  print(summary(plotwork))
  ```
  Expected: 130 rows, columns: yyyy, is.meanresid, is.xyresid, oos.meanresid, oos.xyresid, is.improvement, oos.improvement.

- [ ] **Step 5: Commit**

  ```bash
  git add goyal-welch-plots.R
  git commit -m "refactor: replace iaw$lagseries, iaw$residuals, last() with base R equivalents"
  ```

---

### Task 3: Reshape data and build ggplot object

**Files:**
- Modify: `goyal-welch-plots.R` (plotting block — replace everything from `iaw$pdf.start(...)` to `iaw$pdf.end()`)

- [ ] **Step 1: Delete the old plotting block**

  Remove everything from `iaw$pdf.start("gwdp.pdf")` through `iaw$pdf.end()` (the final line of the script).

- [ ] **Step 2: Add the reshape step**

  After `rm(ds)` and the `plotwork` construction, add:

  ```r
  plotlong <- rbind(
    data.frame(yyyy = plotwork$yyyy, improvement = plotwork$is.improvement,  type = "IS"),
    data.frame(yyyy = plotwork$yyyy, improvement = plotwork$oos.improvement, type = "OOS")
  )
  ```

- [ ] **Step 3: Compute runtime annotation values**

  ```r
  annotateloc  <- plotwork$yyyy[35]          # ~year 1906, label placement
  is_val_ann   <- plotwork$is.improvement[35]
  oos_val_ann  <- plotwork$oos.improvement[35]
  oos_ref_line <- plotwork$oos.improvement[plotwork$yyyy == plotwork$yyyy[72]]  # ~year 1943 dashed ref
  ```

- [ ] **Step 4: Write the ggplot call**

  ```r
  p <- ggplot(plotlong, aes(x = yyyy, y = improvement, color = type, linewidth = type)) +
    # Oil shock band
    annotate("rect", xmin = 1973, xmax = 1975, ymin = -Inf, ymax = Inf,
             fill = "red", alpha = 0.4) +
    annotate("text", x = 1977, y = -0.15, label = "Oil Shock (1974)",
             angle = 90, color = "red", size = 3) +
    # Lines
    geom_line() +
    scale_color_manual(values = c("IS" = "black", "OOS" = "blue")) +
    scale_linewidth_manual(values = c("IS" = 0.8, "OOS" = 1.2)) +
    # Reference lines
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_hline(yintercept = oos_ref_line, linetype = "dashed") +
    # Direct line labels
    annotate("text", x = annotateloc, y = is_val_ann + 0.01,
             label = "IS", color = "black", vjust = 0) +
    annotate("text", x = annotateloc, y = oos_val_ann - 0.01,
             label = "OOS", color = "blue", vjust = 1) +
    # Arrows and explanatory labels
    annotate("segment", x = 1890, xend = 1895, y = -0.12, yend = -0.08,
             color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
    annotate("text", x = 1909, y = -0.09, color = "black", size = 3,
             label = "Conditional Model\nPredicts better") +
    annotate("segment", x = 1890, xend = 1895, y = -0.13, yend = -0.17,
             color = "black", arrow = arrow(length = unit(0.2, "cm"))) +
    annotate("text", x = 1909, y = -0.16, color = "black", size = 3,
             label = "Prevailing Mean\nPredicts better") +
    # Data info and stats
    annotate("text", x = 1890, y = 0.16, hjust = 0, size = 3, color = "black",
             label = paste0("Dependent: Log Equity Premium\nIndependent: Lagged D/P\nData: 1872 (1892) to ", lyr)) +
    annotate("text", x = 1985, y = 0.13, hjust = 0, size = 3, color = "black",
             label = paste0("IS T-stat: ", tstat, "\nIS Adj R^2: ", rsq, "%")) +
    # Scales and theme
    scale_y_continuous(limits = c(-0.2, 0.2)) +
    labs(x = "Year", y = "Cumulative SSE Difference") +
    theme_xkcd() +
    theme(legend.position = "none")

  ggsave("gwdp.pdf", plot = p, width = 8, height = 5)
  ```

- [ ] **Step 5: Source the full script and verify output**

  ```r
  source("goyal-welch-plots.R")
  ```
  Expected:
  - No errors or warnings (other than possible font fallback message if Humor Sans not installed)
  - `gwdp.pdf` created/updated in working directory
  - Open `gwdp.pdf` and visually confirm: two lines (black IS, blue OOS), red oil shock band, dashed reference lines, arrows and labels, xkcd/comic font style

- [ ] **Step 6: Commit**

  ```bash
  git add goyal-welch-plots.R
  git commit -m "feat: replace base R plot with ggplot2 + xkcd comic theme"
  ```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the "Running the Analysis" section**

  In `CLAUDE.md`, the current text says the script depends on an `iaw` environment pre-loaded before sourcing. Replace the Running the Analysis section so it reads:

      ## Running the Analysis

      The project uses R with an RStudio project file (`gw2008.Rproj`).

      **One-time font setup** (only needed on first use):

          library(extrafont)
          font_import()   # imports system fonts including Humor Sans if installed

      **Run the script:**

          source("goyal-welch-plots.R")

      Output: `gwdp.pdf` in the working directory.

- [ ] **Step 2: Remove the `iaw` environment note from the Architecture section**

  Delete or update the bullet/paragraph that describes the `iaw` environment abstraction, since it no longer exists.

- [ ] **Step 3: Commit**

  ```bash
  git add CLAUDE.md
  git commit -m "docs(CLAUDE.md): update for self-contained script, remove iaw env notes"
  ```
