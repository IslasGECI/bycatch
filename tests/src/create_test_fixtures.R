# ==========================================
# create_test_fixtures.R
#
# Context: One-time script to generate test fixture files for the plot layer.
#
# Description: Runs the real compute_* functions once and saves outputs as .rds
# files in tests/data/. These fixtures are read by test_plot.R and by slow render
# tests. This script is NOT part of the test suite.
#
# Entradas: /workdir/tests/data/trips_5_ids.csv
#
# Salida: /workdir/tests/data/assessment_detail.rds
#         /workdir/tests/data/kba_polygons.rds
#         /workdir/tests/data/ud_polygons.rds
#
# Dependencias: bycatch, readr, tibble, sf
#
# Notas: Run inside the Docker container:
#   Rscript tests/src/create_test_fixtures.R
# ==========================================

# ==== CONFIGURACIÓN ====
library(readr)
library(tibble)
library(bycatch)

levelUD <- 50
smoothing_method <- "log_median"
n_iterations <- 10
popSize <- 10

# ==== ENTRADAS ====
data_path <- "/workdir/tests/data/trips_5_ids.csv"
data <- read_csv(data_path, show_col_types = FALSE)

config <- list(
  colony = tibble(
    Longitude = -118.29162,
    Latitude = 28.88421
  )
)

# ==== PROCESAMIENTO / ANÁLISIS ====
# compute_* functions are expected to self-manage S2 (P5),
# but guards are not yet implemented in the codebase.
# Set S2 off explicitly for this one-time generation.
previous_s2 <- sf::sf_use_s2(FALSE)

# Step 1: Compute individual KDE (fast, no bootstrap)
cat("Computing individual KDE...\n")
kde <- bycatch:::compute_individual_kde(data, config, levelUD, smoothing_method)

# Step 2: Save UDPolygons fixture
cat("Saving UDPolygons fixture...\n")
saveRDS(kde$UDPolygons, "/workdir/tests/data/ud_polygons.rds")

# Step 3: Compute representative assessment (expensive bootstrap, n_iterations = 10)
cat("Computing representative assessment (n_iterations =", n_iterations, ")...\n")
assessment <- bycatch:::compute_representative_assessment(
  kde$KDE_surface, kde$tracks, levelUD, n_iterations
)

# Step 4: Save assessment_detail fixture
cat("Saving assessment_detail fixture...\n")
saveRDS(assessment$assessment_detail, "/workdir/tests/data/assessment_detail.rds")

# Step 5: Compute potential KBA
cat("Computing potential KBA...\n")
site <- bycatch:::compute_potential_kba(
  kde$KDE_surface,
  assessment$assessment_summary$out,
  popSize,
  levelUD
)

# Step 6: Save KBA polygons fixture
cat("Saving KBA polygons fixture...\n")
saveRDS(site, "/workdir/tests/data/kba_polygons.rds")

# ==== SALIDA ====
sf::sf_use_s2(previous_s2)
cat("All fixtures generated successfully.\n")
cat("  /workdir/tests/data/ud_polygons.rds\n")
cat("  /workdir/tests/data/assessment_detail.rds\n")
cat("  /workdir/tests/data/kba_polygons.rds\n")
