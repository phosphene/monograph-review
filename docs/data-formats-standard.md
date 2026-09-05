# Data Format Standards — V1.0 (2026-09-05)

**Status:** Active  
**Last Updated:** 2026-09-05  
**Author:** Ed Phil / FeelingFlowingBot  
**Review Cycle:** Quarterly  

---

## Executive Summary

This document establishes the official data format policies for the monograph-review repository, implementing a hybrid approach optimized for open science reproducibility and computational efficiency.

### Core Policy

| Data Type | Recommended Format | Rationale |
|-----------|-------------------|-----------|
| **Empirical measurements** (time series, observations) | **TSV** (`.tsv`) | Human-readable, git-friendly, flat structure, no quoting issues |
| **Configuration/metadata** (parameters, settings) | **JSON** (`.json`) | Structured, versionable, shallow nesting supported |
| **Large numerical arrays** (>1M elements) | **HDF5** (`.h5`) | Compression, partial access, hierarchical organization |
| **R object serialization** (intermediate results) | **RDS** (`.rds`) | Preserves all R attributes/classes |

---

## TSV Files: Empirical Data

### When to Use

- Tabular experimental data with many rows (>1000)
- Time series observations
- Measurement logs
- Any dataset where human readability matters

### Schema Requirements

Every TSV file must include:

1. **Header row** with descriptive column names (snake_case preferred)
2. **Data types documented** in comments or external schema
3. **Unique identifier columns** (e.g., `observation_id`, `species_id`)
4. **Units specified** either in header or separate metadata

### Example Structure

```tsv
# File: earthworm_recovery.tsv
# Format: Empirical recovery time series
# Units: seconds, ratio [0-1], dimensionless

time_retention_second	retention_ratio	treatment_condition	worm_id	experiment_id
0.000	1.0000	controlled	WC_001	WC_2026_001
0.125	0.9847	controlled	WC_001	WC_2026_001
...
```

### R Usage Patterns

```r
# Read TSV data
data <- read.delim("earthworm_recovery.tsv", header = TRUE, comment.char = "#")

# Write TSV data
write.table(results, "output.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
```

---

## JSON Files: Configuration & Metadata

### When to Use

- Experiment configuration files
- Parameter specifications
- Model settings
- Small structured datasets (<100 rows)
- Schema definitions

### Nesting Guidelines

- ✅ **Shallow (1-3 levels)**: Acceptable
- ⚠️ **Medium (4-5 levels)**: Use only if necessary
- ❌ **Deep (6+ levels)**: Avoid; flatten structure instead

### Example Structure

```json
{
  "experiment": {
    "id": "WC_2026_001",
    "species": {
      "scientific_name": "Lumbricus terrestris"
    },
    "parameters": {
      "temperature_celsius": 20.0
    }
  },
  "analysis_config": {
    "slaving_method": "implicit_rosenbrock"
  }
}
```

### R Usage Patterns

```r
# Install required package (preinstalled in miniforge env)
library(jsonlite)

# Read JSON
config <- fromJSON("experiment_WC_2026_001.json", simplifyVector = TRUE)

# Write JSON (pretty-printed, indentation enabled)
toJSON(config, pretty = TRUE, auto_unbox = TRUE) %>% 
  writeLines("output.json")
```

---

## HDF5 Files: Large Numerical Arrays

### When to Use

- Multi-dimensional numerical arrays (>1M elements)
- Hierarchical collections of large datasets
- Datasets requiring partial access patterns

### Installation Note

Install via conda-forge or CRAN:

```bash
conda install -n base r-rhdf5
# OR
Rscript -e 'install.packages("rhdf5", lib="/home/node/.openclaw/tools/R-library")'
```

### Usage Pattern

```r
library(rhdf5)

# Write array
h5createFile("results.h5")
h5write(data_matrix, "results.h5", "/dataset")

# Read subset
subset_data <- h5read("results.h5", "/dataset", index = list(1:100, ))
```

---

## Version Control Best Practices

### Git-Friendly Formatting

**TSV:** ✅ Excellent diff visibility
```diff
- retention_ratio 0.8295
+ retention_ratio 0.8296
```

**JSON:** ⚠️ Good with proper indentation
```diff
-   "temperature_celsius": 20.0
+   "temperature_celsius": 20.1
```

### Commit Message Guidelines

Use descriptive messages explaining what changed and why:

```bash
git add data/examples/earthworm_recovery.tsv
git commit -m "Add sample empirical data: earthworm recovery time series (v1)"

git add data/metadata/experiment_*.json
git commit -m "Add experiment metadata configs: WC_2026_001 baseline (v1)"
```

---

## Migration Path

If existing data uses different formats:

1. **CSV → TSV**: `tr ',' '\t' < input.csv > output.tsv`
2. **Nested JSON → Flat TSV**: Use `jq` or Python pandas for restructuring
3. **Binary formats → HDF5**: Convert using appropriate tools (see section below)

---

## References

- TSV specification: RFC 4180 (CSV generalization)
- JSON specification: ECMA-404 / ISO 8602
- HDF5 format: https://www.hdfgroup.org/solutions/hdf5/
- Phosphene R Standards: See `/home/node/.openclaw/workspace/meta/reference/shared-python-environment.md`

---

## Adoption Timeline

- **Immediate**: Apply to new data submissions
- **Week 1**: Audit existing datasets for format compliance
- **Month 1**: Migrate non-compliant data to standardized formats
- **Ongoing**: Enforce via CI validation checks

---

*End of Standards Document*
