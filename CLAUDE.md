# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a replication and extension of Goyal & Welch (2008), "Predicting the Equity Premium with Dividend Ratios" (*Review of Financial Studies*). It tests whether lagged dividend-to-price (D/P) ratios predict the equity premium, comparing conditional models against an unconditional mean benchmark, both in-sample and out-of-sample.

## Running the Analysis

The project uses R with an RStudio project file (`gw2008.Rproj`).

**One-time font setup** (only needed on first use):

    library(extrafont)
    font_import()   # imports system fonts including Humor Sans if installed

**Run the script:**

    source("goyal-welch-plots.R")

Output: `gwdp.pdf` in the working directory.

## Architecture

**Single-script pipeline** (`goyal-welch-plots.R`):

1. **Data ingestion** — reads `data/goyal-welch-a.csv` (raw: ~219 annual obs, 1802–2020); constructs log equity premium (`logeqp`) and lagged D/P (`lagdp`); subsets to 1872+ for analysis.
2. **In-sample analysis** — OLS regression `logeqp ~ lagdp`; extracts t-stat and adjusted R².
3. **Out-of-sample analysis** — expanding-window loop starting with 20 years of training data (predictions begin 1892); at each step estimates both the conditional model (with D/P) and the prevailing mean.
4. **Performance metric** — cumulative SSE of mean model minus cumulative SSE of conditional model; positive = conditional model better.
5. **Plotting** — outputs `gwdp.pdf` replicating GW Figure style.

## Key Design Notes

- **GW replication**: To exactly replicate the original GW (2005 endpoint), subset `dsraw` to `yyyy <= 2005` (commented line in script).
- **Data**: `goyal-welch-a.csv` is the Goyal-Welch dataset; download the latest version from Amit Goyal's website to extend beyond 2020.
