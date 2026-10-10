# Helpers for the validation article (vignettes/articles/validation.Rmd).
#
# The articles read the validation web bundle exported by
# RSYC-Canada/R/5900_export_validation_web_bundle.R. Bundles live in
# pkgdown/assets/validation/<model_version>/ and are copied verbatim to the
# site, where the interactive explorer (pkgdown/assets/validation/explorer.js)
# reads the same files. pkgdown/assets/validation/versions.json selects the
# bundle used by both the static articles and the explorer.
#
# To publish a new bundle, run in RSYC-Canada:
#   RSYC_WEB_EXPORT_DIR=../RSYC/pkgdown/assets/validation \
#     Rscript R/5900_export_validation_web_bundle.R
# then set "latest" in versions.json to the new model version.
#
# Scatterplots follow the styling of the RSYC-Canada validation figure script
# 5210_figure_validation_scatterplots.R.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})

validation_assets_dir <- function() {
  candidates <- c(
    file.path("..", "..", "pkgdown", "assets", "validation"),
    file.path("pkgdown", "assets", "validation")
  )
  found <- candidates[dir.exists(candidates)]
  if (length(found) == 0) {
    stop("Cannot find pkgdown/assets/validation.", call. = FALSE)
  }
  normalizePath(found[[1]], winslash = "/")
}

read_columnar_json <- function(path) {
  tibble::as_tibble(jsonlite::fromJSON(path, simplifyVector = TRUE))
}

spatial_levels <- c("tile", "ecozone", "ecoprovince", "ecoregion", "ecodistrict")

spatial_labels <- c(
  tile = "Tile",
  ecozone = "Ecozone",
  ecoprovince = "Ecoprovince",
  ecoregion = "Ecoregion",
  ecodistrict = "Ecodistrict"
)

scale_labels <- c(national = "National", regional = "Regional")

response_names <- c(agb = "AGB", volume = "Volume")

load_validation_bundle <- function(version = NULL) {
  root <- validation_assets_dir()
  if (is.null(version)) {
    version <- jsonlite::fromJSON(file.path(root, "versions.json"))$latest
  }
  dir <- file.path(root, version)
  manifest <- jsonlite::fromJSON(file.path(dir, "manifest.json"))

  species <- tibble::as_tibble(manifest$species)

  models <- read_columnar_json(file.path(dir, "models.json")) %>%
    left_join(species, by = "species")
  stats <- read_columnar_json(file.path(dir, "validation_stats.json"))
  age <- read_columnar_json(file.path(dir, "validation_age.json"))

  model_info <- models %>%
    select(
      key, model_id, response, scale, parameter_level, strata_id,
      model_group, species, species_name
    )

  list(
    version = version,
    manifest = manifest,
    models = models,
    stats = stats %>% inner_join(model_info, by = "key"),
    age = age %>% inner_join(model_info, by = "key")
  )
}

# Panel order used by the RSYC-Canada figures: Generic, Coniferous, Broadleaf,
# then species by decreasing number of points.
order_species_panels <- function(data) {
  panel_order <- data %>%
    count(species_name, sort = TRUE) %>%
    pull(species_name)
  panel_order <- c(
    intersect(c("Generic", "Coniferous", "Broadleaf"), panel_order),
    setdiff(panel_order, c("Generic", "Coniferous", "Broadleaf"))
  )
  mutate(data, species_name = factor(species_name, levels = panel_order))
}

# Age-class points for one response x scale x parameter level, filtered as in
# 5210/5220: positive observations, AGB < 400 Mg/ha, >= 3 points per panel.
validation_points <- function(bundle, y_var, scale, parameter_level) {
  bundle$age %>%
    filter(
      .data$response == .env$y_var,
      .data$scale == .env$scale,
      .data$parameter_level == .env$parameter_level,
      is.finite(pred_mean),
      is.finite(obs_mean),
      obs_mean > 0,
      .data$response != "agb" | obs_mean < 400
    ) %>%
    order_species_panels() %>%
    group_by(species_name) %>%
    filter(n() >= 3) %>%
    ungroup()
}

figure_height <- function(n_panels, per_row, minimum) {
  max(minimum, ceiling(n_panels / 4) * per_row)
}

# 5210_figure_validation_scatterplots.R
validation_scatterplot <- function(points, y_var) {
  labels <- switch(
    y_var,
    agb = list(
      x = expression(AGB[Plot] ~ paste("[Mg/ha]")),
      y = expression(AGB[RSYC] ~ paste("[Mg/ha]"))
    ),
    volume = list(
      x = expression(Volume[Plot] ~ paste("[m"^3 * "/ha]")),
      y = expression(Volume[RSYC] ~ paste("[m"^3 * "/ha]"))
    )
  )

  p <- points %>%
    group_by(species_name) %>%
    scatter::scatter(
      obs_mean,
      pred_mean,
      metrics = list(
        "R2" = yardstick::rsq,
        "bias" = scatter::md,
        "bias%" = scatter::rmd,
        "RMSE" = yardstick::rmse,
        "RMSE%" = scatter::rrmse
      ),
      metrics_position = "inside",
      metrics_inside_placement = "upperleft",
      points_size = 1,
      text_size = 7
    ) +
    xlab(labels$x) +
    ylab(labels$y) +
    facet_wrap(vars(species_name), ncol = 4) +
    scatter::theme_baseR(font_size = 10) +
    theme(strip.text = element_text(margin = margin(b = 1)))

  if (y_var == "volume") {
    metrics_layer <- which(vapply(
      p$layers,
      function(layer) inherits(layer$geom, "GeomRichText"),
      logical(1)
    ))
    p$layers[[metrics_layer]]$mapping$x <- aes(x = 20)$x
    p$layers[[metrics_layer]]$mapping$y <- aes(y = 780)$y
    p <- p + coord_fixed(xlim = c(0, 800), ylim = c(0, 800))
  }

  p
}

validation_summary_table <- function(bundle) {
  bundle$stats %>%
    mutate(
      model_group = factor(
        model_group,
        levels = c("generic", "species_group", "species"),
        labels = c("Generic", "Species group", "Species")
      ),
      parameter_level = factor(parameter_level, levels = spatial_levels)
    ) %>%
    group_by(response, scale, parameter_level, model_group) %>%
    summarise(
      Models = n(),
      `Median R²` = median(rsq, na.rm = TRUE),
      `Median bias%` = median(rmd, na.rm = TRUE),
      `Median RMSE%` = median(rrmse, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(response, scale, parameter_level, model_group) %>%
    mutate(
      response = response_names[response],
      scale = scale_labels[scale],
      parameter_level = spatial_labels[as.character(parameter_level)]
    ) %>%
    rename(
      Response = response,
      Scale = scale,
      Level = parameter_level,
      `Model group` = model_group
    )
}

# Emit one knitr chunk per figure so that each can have its own height.
knit_figure <- function(plot, height, width = 7.5, alt = NULL) {
  env <- new.env()
  env$plot <- plot
  env$alt <- alt %||% "Validation figure"
  chunk <- c(
    sprintf(
      "```{r, fig.width = %s, fig.height = %s, fig.alt = alt, echo = FALSE}",
      width,
      height
    ),
    "print(plot)",
    "```"
  )
  cat(knitr::knit_child(text = chunk, envir = env, quiet = TRUE), "\n\n")
}
