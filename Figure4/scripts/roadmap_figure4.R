#!/usr/bin/env Rscript

# =============================================================================
# Figure 4: Proposed framework for conformational state-space inference
#
# PURPOSE
#   Rebuild Figure 4 as a reproducible portrait framework. The central target
#   is state-space inference with uncertainty. Six research components inform
#   that target iteratively; selected outer links show specific feedback rather
#   than a required sequence of operations.
#
# INPUTS
#   Layout reference (not read by the script):
#     ../fig4_draft2.png
#
#   SVG assets read by the script:
#     ../parts_fig4/state_structures/CTD_alpha_vectorized.svg
#     ../parts_fig4/state_structures/CTD_beta_vectorized.svg
#     ../parts_fig4/state_structures/IDP_part1.svg
#     ../parts_fig4/state_structures/IDP_part3.svg
#     ../parts_fig4/context_icons/ph.svg
#
# OUTPUTS
#   Always: ../output/figure4_state_space_roadmap_v2.{pdf,png,tiff}
#   When pdftocairo is available:
#           ../output/figure4_state_space_roadmap_v2.svg
#
# QUICK START
#   From the Figure4 directory:
#     Rscript scripts/roadmap_figure4.R
#   The script can also be sourced from RStudio or run from another directory.
#
#   From RStudio:
#     Open this file and click Source. No setwd() call is required.
#     Running selected lines also works when this file is the active document.
#
#   Required R packages:
#     install.packages(c("magick", "ragg"))
#
#   `grid` is included with R. `pdftocairo` is optional and is used only to
#   convert the vector PDF into SVG; the PDF remains the vector master.
#
# COLLABORATOR EDITING MAP
#   Most revisions should require editing only one of these locations:
#     Global appearance     FIG_*, FONT_FAMILY, *_SIZE, MODULE_ALPHA and COL
#     Ellipse text/layout   modules
#     Central spokes       spokes
#     Feedback arrows      links
#     Ellipse icons         draw_module_icon()
#     Central state space   draw_state_space_card()
#     Arrow legend          draw_relationship_legend()
#     Output file name      OUTPUT_STEM
#
# LAYOUT CONVENTIONS
#   - Coordinates use grid's normalized parent coordinates ("npc"):
#       x = 0 is left, x = 1 is right, y = 0 is bottom, y = 1 is top.
#   - `modules$r` is the shared base size; MODULE_RX_SCALE and MODULE_RY_SCALE
#     convert it into a consistent, slightly horizontal ellipse.
#   - Use "\n" inside a label to control line breaks explicitly.
#   - All six roadmap ellipses intentionally share one base size.
#   - Relationship arrows intentionally stop short of the ellipses and central
#     card. If modules move, update arrow endpoints and label coordinates.
#
# SAFE REVISION WORKFLOW
#   1. Change one section at a time.
#   2. Run the script; PDF, PNG and TIFF are regenerated, followed by SVG when
#      pdftocairo is available.
#   3. Inspect the PNG at the expected publication width.
#   4. Confirm that no labels, icons, arrowheads or ellipses overlap.
#   5. Keep draw_figure() as the single rendering entry point so PDF, SVG,
#      PNG and TIFF retain identical geometry.
# =============================================================================

suppressPackageStartupMessages({
  library(grid)
  library(magick)
})

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

# Resolve this file rather than relying on getwd(). This supports:
#   1. Rscript from a terminal (`--file=...`)
#   2. source() / the RStudio Source button (`sys.frames()$ofile`)
#   3. line-by-line execution in RStudio (active editor document)
#   4. a final search from common project working directories
resolve_script_path <- function(filename) {
  command_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", command_args, value = TRUE)

  if (length(file_arg) > 0) {
    path <- sub("^--file=", "", file_arg[1])
    path <- gsub("~\\+~", " ", path)
    if (file.exists(path)) {
      return(normalizePath(path))
    }
  }

  frame_paths <- unlist(
    lapply(
      sys.frames(),
      function(frame) {
        path <- frame$ofile
        if (is.character(path) && length(path) == 1 && nzchar(path)) {
          path
        } else {
          NULL
        }
      }
    ),
    use.names = FALSE
  )

  frame_paths <- frame_paths[file.exists(frame_paths)]
  if (length(frame_paths) > 0) {
    return(normalizePath(tail(frame_paths, 1)))
  }

  if (
    requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()
  ) {
    editor_path <- tryCatch(
      rstudioapi::getSourceEditorContext()$path,
      error = function(e) ""
    )
    if (nzchar(editor_path) && file.exists(editor_path)) {
      return(normalizePath(editor_path))
    }
  }

  # Search upward from the working directory. This covers running from the
  # repository root, Figure4/, or Figure4/scripts/.
  search_roots <- character()
  current_dir <- normalizePath(getwd())
  for (i in 1:8) {
    search_roots <- c(search_roots, current_dir)
    parent_dir <- dirname(current_dir)
    if (identical(parent_dir, current_dir)) {
      break
    }
    current_dir <- parent_dir
  }

  candidates <- unique(unlist(lapply(
    search_roots,
    function(root) {
      c(
        file.path(root, filename),
        file.path(root, "scripts", filename),
        file.path(root, "Figure4", "scripts", filename),
        file.path(
          root,
          "possible figures",
          "Figure4",
          "scripts",
          filename
        )
      )
    }
  )))

  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) > 0) {
    return(normalizePath(candidates[1]))
  }

  stop(
    "Could not locate ", filename, ". In RStudio, open this script and click ",
    "Source; from a terminal, run it with Rscript."
  )
}

script_path <- resolve_script_path("roadmap_figure4.R")
script_dir <- dirname(script_path)

figure_dir <- normalizePath(file.path(script_dir, ".."), mustWork = TRUE)
parts_dir <- file.path(figure_dir, "parts_fig4")
structure_dir <- file.path(parts_dir, "state_structures")
context_dir <- file.path(parts_dir, "context_icons")
output_dir <- file.path(figure_dir, "output")

if (!dir.exists(structure_dir) || !dir.exists(context_dir)) {
  stop(
    "Figure 4 asset folders were not found relative to the script.\n",
    "Resolved script: ", script_path, "\n",
    "Expected structures: ", structure_dir, "\n",
    "Expected context icons: ", context_dir
  )
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Global style
# -----------------------------------------------------------------------------

FIG_WIDTH <- 7.2
FIG_HEIGHT <- 7.8
FONT_FAMILY <- "Helvetica"
MODULE_ALPHA <- 0.90
FLOW_LABEL_SIZE <- 8.0
OUTPUT_STEM <- "figure4_state_space_roadmap_v2"

# Roadmap nodes are slightly wider than tall. RY is converted to npc units so
# the physical ellipse proportions remain stable on the portrait device.
MODULE_RX_SCALE <- 1.12
MODULE_RY_SCALE <- 1.05

# Bounding boxes are c(left, bottom, right, top), in npc units.
TARGET_CARD_BOX <- c(0.335, 0.305, 0.665, 0.680)
RELATIONSHIP_LEGEND_BOX <- c(0.135, 0.012, 0.865, 0.066)

COL <- list(
  ink = "#111827",
  ink_soft = "#374151",
  grey = "#6B7280",
  grey_mid = "#9CA3AF",
  grey_light = "#D1D5DB",
  grey_fill = "#F5F7FA",
  target_fill = "#F5FAFD",
  white = "#FFFFFF",
  training = "#1599A6",
  benchmarks = "#1769B0",
  objective = "#5B46B2",
  physics = "#2F8F68",
  perturbation = "#EA7208",
  experiment = "#9D3157",
  state_a = "#2F78B7",
  state_b = "#4FA64A",
  state_c = "#8357B4",
  state_d = "#F28A22"
)

# One row per research component, ordered clockwise for layout only.
#   key       selects the icon branch in draw_module_icon()
#   x, y      ellipse center in npc units
#   r         shared base size used to calculate ellipse radii
#   title     bold heading inside the ellipse
#   subtitle  explanatory line(s) below the heading
#   colour    ellipse, arrow and flow-label color
modules <- data.frame(
  id = 1:6,
  key = c(
    "training", "benchmarks", "objective",
    "physics", "perturbation", "experiment"
  ),
  x = c(0.50, 0.82, 0.82, 0.50, 0.18, 0.18),
  y = c(0.805, 0.695, 0.425, 0.170, 0.425, 0.695),
  r = rep(0.102, 6),
  title = c(
    "Training and\nreference data",
    "Landscape-aware\nbenchmarks",
    "Ensemble prediction\nobjectives",
    "Physics-based\nestimation",
    "Context and\nperturbation\nmodeling",
    "Orthogonal\nexperimental\nconstraints"
  ),
  subtitle = c(
    "Multi-state structures, trajectories,\nobservables, and conditions",
    "States, populations, perturbations,\nand kinetics",
    "Distributions, dynamics,\nand calibrated uncertainty",
    "Energetic organization and rates\nunder model and sampling\nassumptions",
    "Mutations, ligands, environment,\nand assembly conditions",
    "Matched-condition observables\nand independent tests"
  ),
  colour = c(
    COL$training,
    COL$benchmarks,
    COL$objective,
    COL$physics,
    COL$perturbation,
    COL$experiment
  ),
  stringsAsFactors = FALSE
)

# Every component exchanges information with the central inference target.
# Endpoints stop outside the module ellipses and the central card.
spokes <- data.frame(
  module = 1:6,
  x0 = c(0.500, 0.728, 0.706, 0.500, 0.294, 0.272),
  y0 = c(0.706, 0.637, 0.425, 0.269, 0.425, 0.637),
  x1 = c(0.500, 0.665, 0.665, 0.500, 0.335, 0.335),
  y1 = c(0.680, 0.597, 0.425, 0.305, 0.425, 0.597),
  colour = modules$colour,
  stringsAsFactors = FALSE
)

# Selected outer relationships preserve the useful circular layout while
# avoiding a mandatory six-step pipeline. `ends = "both"` denotes iterative
# exchange; `ends = "last"` is retained only for a specific directional claim.
#   source/target  module IDs for documentation and validation
#   x0, y0         start of the visible arrow
#   x1, y1         arrowhead position
#   curvature      0 for a straight arrow; signed values bend the curve
#   label_x/y      center of the concise data-flow label
# Endpoints are deliberately outside the ellipses, leaving a consistent gap.
links <- data.frame(
  source = 1:6,
  target = c(2, 3, 4, 5, 6, 1),
  x0 = c(0.610, 0.820, 0.735, 0.405, 0.180, 0.290),
  y0 = c(0.767, 0.580, 0.350, 0.238, 0.540, 0.733),
  x1 = c(0.710, 0.820, 0.585, 0.265, 0.180, 0.390),
  y1 = c(0.733, 0.540, 0.238, 0.350, 0.580, 0.767),
  curvature = c(-0.16, 0, -0.15, -0.15, 0, -0.16),
  ends = c("both", "both", "both", "both", "last", "last"),
  label = c(
    "held-out systems\nand conditions",
    "benchmark results\nand failure modes",
    "distributional and\ndynamical targets",
    "energetic and\nkinetic estimates",
    "testable perturbation\npredictions",
    "structures, observables,\nconditions + uncertainty"
  ),
  label_x = c(0.735, 0.910, 0.770, 0.230, 0.090, 0.265),
  label_y = c(0.830, 0.560, 0.275, 0.275, 0.560, 0.830),
  colour = modules$colour,
  stringsAsFactors = FALSE
)

# Fail early with a useful message if a collaborator makes an invalid edit.
expected_keys <- c(
  "training", "benchmarks", "objective",
  "physics", "perturbation", "experiment"
)

if (
  nrow(modules) != 6 ||
  !identical(modules$id, 1:6) ||
  !setequal(modules$key, expected_keys)
) {
  stop(
    "`modules` must contain IDs 1-6 and exactly these keys: ",
    paste(expected_keys, collapse = ", ")
  )
}

if (
  nrow(spokes) != 6 ||
  any(!spokes$module %in% modules$id)
) {
  stop("`spokes` must connect all six modules to the central target.")
}

if (
  nrow(links) != 6 ||
  any(!links$source %in% modules$id) ||
  any(!links$target %in% modules$id) ||
  any(!links$ends %in% c("both", "last"))
) {
  stop("`links` must define six valid connections between module IDs 1-6.")
}

layout_values <- c(
  modules$x, modules$y, modules$r,
  spokes$x0, spokes$y0, spokes$x1, spokes$y1,
  links$x0, links$y0, links$x1, links$y1,
  links$label_x, links$label_y,
  TARGET_CARD_BOX, RELATIONSHIP_LEGEND_BOX
)

if (any(!is.finite(layout_values)) || any(layout_values < 0 | layout_values > 1)) {
  stop("All layout coordinates and radii must be finite values from 0 to 1.")
}

# -----------------------------------------------------------------------------
# General drawing helpers
# -----------------------------------------------------------------------------

draw_text <- function(
  label,
  x,
  y,
  fontsize = 10,
  col = COL$ink,
  fontface = "plain",
  just = "centre",
  rot = 0,
  lineheight = 0.95
) {
  grid.text(
    label,
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    just = just,
    rot = rot,
    gp = gpar(
      fontfamily = FONT_FAMILY,
      fontsize = fontsize,
      fontface = fontface,
      col = col,
      lineheight = lineheight
    )
  )
}

draw_math <- function(
  label,
  x,
  y,
  fontsize = 9,
  col = COL$ink,
  fontface = "plain",
  just = "centre"
) {
  grid.text(
    label,
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    just = just,
    gp = gpar(
      fontfamily = FONT_FAMILY,
      fontsize = fontsize,
      fontface = fontface,
      col = col
    )
  )
}

draw_roundrect <- function(
  box,
  fill = "white",
  col = COL$grey,
  lwd = 1,
  radius = 0.012
) {
  grid.roundrect(
    x = unit((box[1] + box[3]) / 2, "npc"),
    y = unit((box[2] + box[4]) / 2, "npc"),
    width = unit(box[3] - box[1], "npc"),
    height = unit(box[4] - box[2], "npc"),
    r = unit(radius, "snpc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_rect <- function(box, fill = "white", col = NA, lwd = 1) {
  grid.rect(
    x = unit((box[1] + box[3]) / 2, "npc"),
    y = unit((box[2] + box[4]) / 2, "npc"),
    width = unit(box[3] - box[1], "npc"),
    height = unit(box[4] - box[2], "npc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_arrow <- function(
  x0,
  y0,
  x1,
  y1,
  col = COL$grey,
  lwd = 1.5,
  ends = "last",
  length_in = 0.08,
  lty = 1
) {
  grid.lines(
    x = unit(c(x0, x1), "npc"),
    y = unit(c(y0, y1), "npc"),
    arrow = arrow(
      angle = 25,
      length = unit(length_in, "inches"),
      ends = ends,
      type = "closed"
    ),
    gp = gpar(
      col = col,
      fill = col,
      lwd = lwd,
      lty = lty,
      lineend = "round"
    )
  )
}

draw_curve_arrow <- function(
  x0,
  y0,
  x1,
  y1,
  curvature,
  col,
  lwd = 4,
  ends = "last",
  length_in = 0.13,
  lty = 1
) {
  grid.curve(
    x1 = unit(x0, "npc"),
    y1 = unit(y0, "npc"),
    x2 = unit(x1, "npc"),
    y2 = unit(y1, "npc"),
    curvature = curvature,
    square = FALSE,
    ncp = 12,
    shape = 0.5,
    arrow = arrow(
      angle = 25,
      length = unit(length_in, "inches"),
      ends = ends,
      type = "closed"
    ),
    gp = gpar(
      col = col,
      fill = col,
      lwd = lwd,
      lty = lty,
      lineend = "round"
    )
  )
}

draw_circle <- function(x, y, r, fill, col = NA, lwd = 1) {
  grid.circle(
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    r = unit(r, "snpc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_ellipse <- function(
  x,
  y,
  rx,
  ry,
  fill = NA,
  col = COL$ink,
  lwd = 1
) {
  theta <- seq(0, 2 * pi, length.out = 100)
  grid.polygon(
    x = unit(x + rx * cos(theta), "npc"),
    y = unit(y + ry * sin(theta), "npc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_image <- function(img, x, y, width, height, interpolate = TRUE) {
  grid.raster(
    as.raster(img),
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    width = unit(width, "npc"),
    height = unit(height, "npc"),
    interpolate = interpolate
  )
}

read_svg_asset <- function(path, width = 1600) {
  if (!file.exists(path)) {
    stop("Missing SVG asset: ", path)
  }
  image_read_svg(path, width = width) |>
    image_trim()
}

recolour_image <- function(img, colour, opacity = 1) {
  out <- image_colorize(img, opacity = 100, color = colour)
  if (opacity < 1) {
    out <- tryCatch(
      image_fx(
        out,
        expression = sprintf("%0.3f*a", opacity),
        channel = "alpha"
      ),
      error = function(e) out
    )
  }
  out
}

# -----------------------------------------------------------------------------
# Asset loading
# -----------------------------------------------------------------------------

# Only assets used in the current figure are loaded. To replace an icon:
#   1. Put the SVG in state_structures/ or context_icons/.
#   2. Load it here with read_svg_asset().
#   3. Draw it in draw_module_icon() or draw_contribution_icon().
# Transparent SVG backgrounds are preferred.
img_ctd_alpha <- read_svg_asset(
  file.path(structure_dir, "CTD_alpha_vectorized.svg")
)
img_ctd_beta <- read_svg_asset(
  file.path(structure_dir, "CTD_beta_vectorized.svg")
)
img_idp1 <- read_svg_asset(file.path(structure_dir, "IDP_part1.svg"))
img_idp3 <- read_svg_asset(file.path(structure_dir, "IDP_part3.svg"))

img_state_a <- recolour_image(img_ctd_alpha, COL$state_a)
img_state_b <- recolour_image(img_ctd_beta, COL$state_b)
img_state_c <- recolour_image(img_idp3, COL$state_c)
img_state_d <- recolour_image(img_idp1, COL$state_d)

img_ctd_white <- recolour_image(img_ctd_alpha, COL$white, 0.94)
img_idp3_white <- recolour_image(img_idp3, COL$white, 0.48)

img_ph <- read_svg_asset(file.path(context_dir, "ph.svg"), width = 900)
img_ph_white <- recolour_image(img_ph, COL$white, 0.95)

# -----------------------------------------------------------------------------
# Native mini-icon helpers
# -----------------------------------------------------------------------------

draw_database <- function(
  x,
  y,
  width = 0.035,
  height = 0.050,
  col = COL$white,
  lwd = 1.2
) {
  rx <- width / 2
  ry <- height * 0.105
  draw_ellipse(x, y + height / 2 - ry, rx, ry, fill = NA, col = col, lwd = lwd)
  draw_ellipse(x, y - height / 2 + ry, rx, ry, fill = NA, col = col, lwd = lwd)
  grid.lines(
    x = unit(c(x - rx, x - rx), "npc"),
    y = unit(c(y - height / 2 + ry, y + height / 2 - ry), "npc"),
    gp = gpar(col = col, lwd = lwd)
  )
  grid.lines(
    x = unit(c(x + rx, x + rx), "npc"),
    y = unit(c(y - height / 2 + ry, y + height / 2 - ry), "npc"),
    gp = gpar(col = col, lwd = lwd)
  )
  for (yy in c(y - 0.010, y + 0.008)) {
    draw_ellipse(x, yy, rx, ry, fill = NA, col = col, lwd = lwd * 0.85)
  }
}

draw_microchip_array <- function(
  x,
  y,
  size = 0.042,
  col = COL$white
) {
  # Vector microarray/chip: a chip outline, contact pins and a 3 x 3 array.
  half <- size / 2
  chip_half <- size * 0.36

  draw_roundrect(
    c(
      x - chip_half,
      y - chip_half,
      x + chip_half,
      y + chip_half
    ),
    fill = adjustcolor(col, alpha.f = 0.10),
    col = col,
    lwd = 1.0,
    radius = size * 0.07
  )

  pin_positions <- seq(-chip_half * 0.62, chip_half * 0.62, length.out = 3)
  for (offset in pin_positions) {
    grid.lines(
      x = unit(c(x - half, x - chip_half), "npc"),
      y = unit(c(y + offset, y + offset), "npc"),
      gp = gpar(col = col, lwd = 0.9)
    )
    grid.lines(
      x = unit(c(x + chip_half, x + half), "npc"),
      y = unit(c(y + offset, y + offset), "npc"),
      gp = gpar(col = col, lwd = 0.9)
    )
    grid.lines(
      x = unit(c(x + offset, x + offset), "npc"),
      y = unit(c(y - half, y - chip_half), "npc"),
      gp = gpar(col = col, lwd = 0.9)
    )
    grid.lines(
      x = unit(c(x + offset, x + offset), "npc"),
      y = unit(c(y + chip_half, y + half), "npc"),
      gp = gpar(col = col, lwd = 0.9)
    )
  }

  array_positions <- seq(
    -chip_half * 0.55,
    chip_half * 0.55,
    length.out = 3
  )
  for (dx in array_positions) {
    for (dy in array_positions) {
      draw_circle(
        x + dx,
        y + dy,
        size * 0.045,
        fill = col,
        col = NA
      )
    }
  }
}

draw_benchmark_icon <- function(x, y, col = COL$white) {
  # Multi-basin recovery curve.
  t <- seq(0, 1, length.out = 120)
  yy <- 0.67 -
    0.50 * exp(-((t - 0.24)^2) / 0.018) -
    0.40 * exp(-((t - 0.72)^2) / 0.025)
  yy <- (yy - min(yy)) / (max(yy) - min(yy))
  xx <- x - 0.055 + t * 0.070
  yv <- y - 0.020 + yy * 0.045
  grid.lines(
    x = unit(xx, "npc"),
    y = unit(yv, "npc"),
    gp = gpar(col = col, lwd = 1.6, lineend = "round")
  )
  draw_circle(x - 0.038, y - 0.012, 0.0045, COL$state_b, COL$white, 0.6)
  draw_circle(x - 0.006, y - 0.007, 0.0045, COL$state_d, COL$white, 0.6)

  # Population bars.
  base_x <- x + 0.025
  heights <- c(0.020, 0.033, 0.046)
  for (i in seq_along(heights)) {
    grid.rect(
      x = unit(base_x + (i - 1) * 0.012, "npc"),
      y = unit(y - 0.020 + heights[i] / 2, "npc"),
      width = unit(0.008, "npc"),
      height = unit(heights[i], "npc"),
      gp = gpar(fill = col, col = NA)
    )
  }
  grid.lines(
    x = unit(c(base_x - 0.007, base_x + 0.038), "npc"),
    y = unit(c(y - 0.020, y - 0.020), "npc"),
    gp = gpar(col = col, lwd = 1.0)
  )
}

draw_density_curve <- function(
  x,
  y,
  width = 0.055,
  height = 0.045,
  col = COL$white,
  lwd = 1.4
) {
  t <- seq(-3, 3, length.out = 120)
  den <- exp(-0.5 * t^2)
  den <- den / max(den)
  xx <- x - width / 2 + (t + 3) / 6 * width
  yy <- y - height / 2 + den * height
  grid.lines(
    x = unit(xx, "npc"),
    y = unit(yy, "npc"),
    gp = gpar(col = col, lwd = lwd, lineend = "round")
  )
  grid.lines(
    x = unit(c(x - width / 2, x + width / 2), "npc"),
    y = unit(c(y - height / 2, y - height / 2), "npc"),
    gp = gpar(col = col, lwd = lwd * 0.7)
  )
}

draw_energy_curve <- function(
  x,
  y,
  width = 0.100,
  height = 0.050,
  col = COL$white,
  label_mode = c("both", "delta_g", "none")
) {
  label_mode <- match.arg(label_mode)
  t <- seq(-1.3, 1.3, length.out = 160)
  energy <- 0.30 * (t^2 - 0.72)^2 + 0.08 * t
  energy <- (energy - min(energy)) / (max(energy) - min(energy))
  xx <- x - width / 2 + (t + 1.3) / 2.6 * width
  yy <- y - height / 2 + energy * height

  # Anchor annotations to the actual curve geometry rather than fixed offsets.
  # ΔG‡ marks the saddle point (the barrier maximum between the two basins);
  # ΔG marks the second basin.
  left_candidates <- which(t < 0)
  right_candidates <- which(t > 0)
  left_min <- left_candidates[which.min(energy[left_candidates])]
  right_min <- right_candidates[which.min(energy[right_candidates])]
  barrier_candidates <- seq.int(left_min, right_min)
  saddle <- barrier_candidates[
    which.max(energy[barrier_candidates])
  ]

  grid.lines(
    x = unit(xx, "npc"),
    y = unit(yy, "npc"),
    gp = gpar(col = col, lwd = 1.7, lineend = "round")
  )

  if (label_mode == "none") {
    return(invisible(NULL))
  }

  label_size <- if (width < 0.060) 4.7 else 9.2
  saddle_label_y <- yy[saddle] + height * 0.24
  basin_label_y <- yy[right_min] - height * 0.18

  if (label_mode == "both") {
    draw_math(
      expression(Delta * G),
      xx[saddle] - width * 0.035,
      saddle_label_y,
      label_size,
      col,
      "bold"
    )

    # Draw the double dagger as geometry so it remains portable across PDF
    # devices and does not depend on a font containing U+2021.
    # Offset the double dagger to the upper-right so it reads as a superscript
    # rather than merging with the final stroke of G at publication size.
    dagger_x <- xx[saddle] + width * 0.090
    dagger_y <- saddle_label_y + height * 0.14
    dagger_height <- height * 0.24
    dagger_width <- width * 0.030
    grid.lines(
      x = unit(c(dagger_x, dagger_x), "npc"),
      y = unit(
        c(dagger_y - dagger_height / 2, dagger_y + dagger_height / 2),
        "npc"
      ),
      gp = gpar(col = col, lwd = 1.10)
    )
    for (dy in c(-dagger_height * 0.18, dagger_height * 0.18)) {
      grid.lines(
        x = unit(c(dagger_x - dagger_width, dagger_x + dagger_width), "npc"),
        y = unit(c(dagger_y + dy, dagger_y + dy), "npc"),
        gp = gpar(col = col, lwd = 1.10)
      )
    }
  }

  draw_math(
    expression(Delta * G),
    xx[right_min],
    basin_label_y,
    label_size,
    col
  )
}

draw_ligand <- function(x, y, col = COL$white, scale = 1) {
  r <- 0.007 * scale
  theta <- seq(0, 2 * pi, length.out = 7)[-7] + pi / 6
  centers <- rbind(c(x - 0.010 * scale, y), c(x + 0.010 * scale, y))
  for (i in seq_len(nrow(centers))) {
    grid.polygon(
      x = unit(centers[i, 1] + r * cos(theta), "npc"),
      y = unit(centers[i, 2] + r * sin(theta), "npc"),
      gp = gpar(fill = NA, col = col, lwd = 1.1)
    )
  }
  grid.lines(
    x = unit(c(x - 0.003 * scale, x + 0.003 * scale), "npc"),
    y = unit(c(y, y), "npc"),
    gp = gpar(col = col, lwd = 1.1)
  )
}

draw_experiment_icon <- function(x, y, col = COL$white, scale = 1) {
  # `scale` changes the test tube and population trace together so the motif
  # can remain comfortably inside its container.
  # Test tube.
  grid.roundrect(
    x = unit(x - 0.025 * scale, "npc"),
    y = unit(y, "npc"),
    width = unit(0.018 * scale, "npc"),
    height = unit(0.052 * scale, "npc"),
    r = unit(0.006 * scale, "snpc"),
    gp = gpar(fill = NA, col = col, lwd = 1.2)
  )
  grid.lines(
    x = unit(
      c(x - 0.035 * scale, x - 0.015 * scale),
      "npc"
    ),
    y = unit(
      c(y + 0.027 * scale, y + 0.027 * scale),
      "npc"
    ),
    gp = gpar(col = col, lwd = 1.2)
  )
  grid.rect(
    x = unit(x - 0.025 * scale, "npc"),
    y = unit(y - 0.015 * scale, "npc"),
    width = unit(0.014 * scale, "npc"),
    height = unit(0.014 * scale, "npc"),
    gp = gpar(
      fill = adjustcolor(col, alpha.f = 0.24),
      col = NA
    )
  )

  # Population curve.
  draw_density_curve(
    x + 0.028 * scale,
    y,
    0.048 * scale,
    0.045 * scale,
    col,
    1.35
  )
}

draw_target_icon <- function(x, y, col, scale = 1) {
  for (rr in c(0.016, 0.010, 0.004) * scale) {
    draw_circle(x, y, rr, fill = NA, col = col, lwd = 0.9)
  }
  draw_arrow(
    x - 0.021 * scale,
    y - 0.021 * scale,
    x - 0.004 * scale,
    y - 0.004 * scale,
    col = col,
    lwd = 1.0,
    length_in = 0.040
  )
}

# -----------------------------------------------------------------------------
# Module drawing
# -----------------------------------------------------------------------------

draw_module_base <- function(module) {
  x <- module$x
  y <- module$y
  r <- module$r
  col <- module$colour
  rx <- r * MODULE_RX_SCALE
  ry <- r * MODULE_RY_SCALE * FIG_WIDTH / FIG_HEIGHT

  # Soft shadow and tonal highlight create a reliable pseudo-gradient.
  draw_ellipse(
    x + 0.003,
    y - 0.004,
    rx,
    ry,
    fill = adjustcolor(COL$ink, alpha.f = 0.12),
    col = NA
  )
  draw_ellipse(
    x,
    y,
    rx,
    ry,
    fill = adjustcolor(col, alpha.f = MODULE_ALPHA),
    col = darken_colour(col, 0.15),
    lwd = 1.0
  )
  draw_ellipse(
    x - rx * 0.23,
    y + ry * 0.28,
    rx * 0.68,
    ry * 0.68,
    fill = adjustcolor(COL$white, alpha.f = 0.055),
    col = NA
  )

  title_lines <- length(strsplit(module$title, "\n", fixed = TRUE)[[1]])
  title_y <- y + if (title_lines > 2) 0.038 else 0.033
  subtitle_y <- y - 0.014

  draw_text(
    module$title,
    x,
    title_y,
    fontsize = if (title_lines > 2) 9.2 else 10.2,
    col = COL$white,
    fontface = "bold",
    lineheight = 0.90
  )
  draw_text(
    module$subtitle,
    x,
    subtitle_y,
    fontsize = 6.8,
    col = COL$white,
    fontface = "bold",
    lineheight = 0.94
  )
}

darken_colour <- function(colour, amount = 0.15) {
  rgb <- col2rgb(colour) / 255
  rgb <- pmax(0, rgb * (1 - amount))
  rgb(rgb[1], rgb[2], rgb[3])
}

draw_module_icon <- function(module) {
  # Keep each ellipse to no more than two visual motifs. This preserves
  # legibility when the full figure is reduced to journal dimensions.
  #
  # To replace an icon, change only the branch matching module$key. The x/y
  # offsets are relative to that ellipse's center; positive x moves right and
  # positive y moves up.
  x <- module$x
  key <- module$key
  y_offset <- 0.068
  y <- module$y - y_offset

  if (key == "training") {
    draw_microchip_array(x - 0.027, y, 0.043, COL$white)
    draw_database(x + 0.027, y, 0.032, 0.046, COL$white, 1.20)
  }

  if (key == "benchmarks") {
    draw_benchmark_icon(x, y + 0.005, COL$white)
  }

  if (key == "objective") {
    draw_image(img_ctd_white, x - 0.026, y + 0.003, 0.031, 0.040)
    draw_image(img_idp3_white, x + 0.026, y + 0.003, 0.042, 0.035)
  }

  if (key == "physics") {
    draw_energy_curve(x, y + 0.002, 0.102, 0.048, COL$white)
  }

  if (key == "perturbation") {
    draw_ligand(x - 0.025, y + 0.003, COL$white, 1.22)
    draw_image(img_ph_white, x + 0.027, y + 0.003, 0.034, 0.041)
  }

  if (key == "experiment") {
    # Slightly reduced and lifted so both motifs remain comfortably inside the
    # lower arc of the experimental-constraints ellipse.
    draw_experiment_icon(x, y + 0.005, COL$white, scale = 0.78)
  }
}

# -----------------------------------------------------------------------------
# Central target card
# -----------------------------------------------------------------------------

draw_state_label <- function(label, pop_expr, x, y, col) {
  draw_text(label, x, y, 8.1, col, "bold")
  draw_math(pop_expr, x, y - 0.014, 7.0, col, "bold")
}

draw_state_space_card <- function() {
  # The card geometry is controlled by TARGET_CARD_BOX. State coordinates below
  # are independent of the outer components and may be edited without moving them.
  card <- TARGET_CARD_BOX

  # Shadow and main card.
  draw_roundrect(
    card + c(0.004, -0.004, 0.004, -0.004),
    fill = adjustcolor(COL$ink, alpha.f = 0.10),
    col = NA,
    radius = 0.010
  )
  draw_roundrect(
    card,
    fill = COL$target_fill,
    col = "#203A66",
    lwd = 1.35,
    radius = 0.010
  )

  draw_text(
    "STATE-SPACE INFERENCE",
    0.50,
    0.653,
    11.2,
    COL$ink,
    "bold"
  )
  draw_math(
    expression(p[eq](X~"|"~S * "," * C) ~~ ";" ~~ K[ij](S * "," * C)),
    0.50,
    0.628,
    8.0,
    COL$ink_soft
  )

  # State centers. Keep labels and transition endpoints synchronized if these
  # coordinates change.
  state <- list(
    A = c(0.500, 0.555),
    B = c(0.425, 0.492),
    C = c(0.575, 0.492),
    D = c(0.500, 0.420)
  )

  # Transition network behind the states. Grey bidirectional arrows avoid a
  # privileged sequence; the dashed B-C edge denotes an unresolved relationship.
  draw_arrow(0.484, 0.540, 0.444, 0.508, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.516, 0.540, 0.556, 0.508, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.500, 0.532, 0.500, 0.443, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.450, 0.492, 0.550, 0.492, COL$grey, 0.95, "both", 0.045, 2)
  draw_arrow(0.444, 0.473, 0.482, 0.436, COL$grey, 1.00, "both", 0.045)
  draw_arrow(
    0.518,
    0.436,
    0.556,
    0.473,
    COL$grey,
    1.00,
    "both",
    0.045
  )

  # Translucent halos make state-support uncertainty visible without implying
  # that the pictured structures exhaust the accessible conformations.
  draw_circle(state$A[1], state$A[2], 0.027, adjustcolor(COL$state_a, 0.16), NA)
  draw_circle(state$B[1], state$B[2], 0.027, adjustcolor(COL$state_b, 0.16), NA)
  draw_circle(state$C[1], state$C[2], 0.027, adjustcolor(COL$state_c, 0.16), NA)
  draw_circle(state$D[1], state$D[2], 0.027, adjustcolor(COL$state_d, 0.16), NA)

  # State structures.
  draw_image(img_state_a, state$A[1], state$A[2], 0.032, 0.043)
  draw_image(img_state_b, state$B[1], state$B[2], 0.042, 0.033)
  draw_image(img_state_c, state$C[1], state$C[2], 0.047, 0.032)
  draw_image(img_state_d, state$D[1], state$D[2], 0.035, 0.039)

  draw_state_label(
    "State A",
    bquote("(" * p[A] %+-% sigma[A] * ")"),
    state$A[1],
    0.604,
    COL$state_a
  )
  draw_state_label(
    "State B",
    bquote("(" * p[B] %+-% sigma[B] * ")"),
    state$B[1] - 0.010,
    0.540,
    COL$state_b
  )
  draw_state_label(
    "State C",
    bquote("(" * p[C] %+-% sigma[C] * ")"),
    state$C[1] + 0.010,
    0.540,
    COL$state_c
  )
  draw_state_label(
    "State D",
    bquote("(" * p[D] %+-% sigma[D] * ")"),
    state$D[1] - 0.075,
    0.435,
    COL$state_d
  )

  # Output definition.
  bullets <- c(
    "Structural support / accessible states",
    "Equilibrium populations",
    "Transitions and rates",
    "Context dependence",
    "Uncertainty"
  )
  ys <- c(0.382, 0.365, 0.348, 0.331, 0.314)
  for (i in seq_along(bullets)) {
    draw_circle(0.380, ys[i], 0.0022, COL$ink, NA)
    draw_text(
      bullets[i],
      0.390,
      ys[i],
      7.7,
      COL$ink,
      "bold",
      just = "left"
    )
  }
}

# -----------------------------------------------------------------------------
# Compact relationship and uncertainty legend
# -----------------------------------------------------------------------------

draw_relationship_legend <- function() {
  box <- RELATIONSHIP_LEGEND_BOX
  draw_roundrect(
    box,
    fill = COL$grey_fill,
    col = COL$grey_light,
    lwd = 0.75,
    radius = 0.006
  )

  draw_arrow(0.155, 0.039, 0.195, 0.039, COL$grey, 1.2, "both", 0.045)
  draw_text(
    "iterative exchange",
    0.205,
    0.039,
    7.2,
    COL$ink_soft,
    "bold",
    just = "left"
  )

  draw_arrow(0.370, 0.039, 0.410, 0.039, COL$grey, 1.2, "last", 0.045)
  draw_text(
    "specific directional influence",
    0.420,
    0.039,
    7.2,
    COL$ink_soft,
    "bold",
    just = "left"
  )

  grid.lines(
    x = unit(c(0.650, 0.690), "npc"),
    y = unit(c(0.039, 0.039), "npc"),
    gp = gpar(col = COL$grey, lwd = 1.2, lty = 2)
  )
  draw_text(
    "conditional / unresolved",
    0.700,
    0.039,
    7.2,
    COL$ink_soft,
    "bold",
    just = "left"
  )
}

# -----------------------------------------------------------------------------
# Complete figure
# -----------------------------------------------------------------------------

draw_figure <- function() {
  grid.newpage()
  grid.rect(gp = gpar(fill = COL$white, col = NA))

  # Title block.
  draw_text(
    "Proposed framework for conformational state-space inference",
    0.50,
    0.968,
    16.2,
    COL$ink,
    "bold"
  )
  draw_text(
    paste(
      "An iterative research program integrating data, prediction,",
      "physics, perturbation, and experiment"
    ),
    0.50,
    0.935,
    10.5,
    COL$ink_soft,
    "italic"
  )

  # Draw selected outer feedback links first so endpoints sit behind nodes.
  for (i in seq_len(nrow(links))) {
    link <- links[i, ]
    if (link$curvature == 0) {
      draw_arrow(
        link$x0,
        link$y0,
        link$x1,
        link$y1,
        link$colour,
        lwd = 3.2,
        ends = link$ends,
        length_in = 0.090
      )
    } else {
      draw_curve_arrow(
        link$x0,
        link$y0,
        link$x1,
        link$y1,
        link$curvature,
        link$colour,
        lwd = 3.2,
        ends = link$ends,
        length_in = 0.090
      )
    }
  }

  # Bidirectional spokes are the primary relationship structure: each research
  # component both informs and is refined by state-space inference.
  for (i in seq_len(nrow(spokes))) {
    spoke <- spokes[i, ]
    draw_arrow(
      spoke$x0,
      spoke$y0,
      spoke$x1,
      spoke$y1,
      spoke$colour,
      lwd = 2.6,
      ends = "both",
      length_in = 0.075
    )
  }

  # Central target.
  draw_state_space_card()

  # Six interacting research components.
  for (i in seq_len(nrow(modules))) {
    module <- modules[i, ]
    draw_module_base(module)
    draw_module_icon(module)
  }

  # Relationship labels stay on top and remain readable near the central card.
  for (i in seq_len(nrow(links))) {
    link <- links[i, ]
    draw_text(
      link$label,
      link$label_x,
      link$label_y,
      fontsize = FLOW_LABEL_SIZE,
      col = link$colour,
      fontface = "bold",
      lineheight = 0.94
    )
  }

  draw_relationship_legend()
}

# -----------------------------------------------------------------------------
# Export
# -----------------------------------------------------------------------------

# OUTPUT_STEM changes the basename only. Every device calls draw_figure(), so a
# collaborator should never need to edit individual export blocks.
stem <- OUTPUT_STEM
pdf_file <- file.path(output_dir, paste0(stem, ".pdf"))
svg_file <- file.path(output_dir, paste0(stem, ".svg"))
png_file <- file.path(output_dir, paste0(stem, ".png"))
tiff_file <- file.path(output_dir, paste0(stem, ".tiff"))

pdf(
  pdf_file,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  useDingbats = FALSE,
  bg = COL$white
)
draw_figure()
dev.off()

ragg::agg_png(
  png_file,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  units = "in",
  res = 300,
  background = COL$white
)
draw_figure()
dev.off()

ragg::agg_tiff(
  tiff_file,
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  units = "in",
  res = 300,
  compression = "lzw",
  background = COL$white
)
draw_figure()
dev.off()

# Convert the vector PDF to SVG. This is more reliable than the base macOS SVG
# device in headless sessions without XQuartz. If pdftocairo is unavailable,
# the script still produces PDF, PNG and TIFF and reports a warning.
pdftocairo_candidates <- c(
  unname(Sys.which("pdftocairo")),
  file.path(
    path.expand("~"),
    ".cache/codex-runtimes/codex-primary-runtime/dependencies/native/",
    "poppler/poppler/bin/pdftocairo"
  )
)
pdftocairo_bin <- pdftocairo_candidates[
  nzchar(pdftocairo_candidates) & file.exists(pdftocairo_candidates)
][1]

if (!is.na(pdftocairo_bin)) {
  font_cache_dir <- file.path(tempdir(), "fontconfig-cache")
  dir.create(font_cache_dir, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(XDG_CACHE_HOME = font_cache_dir)

  status <- system2(
    pdftocairo_bin,
    args = c("-svg", shQuote(pdf_file), shQuote(svg_file))
  )

  if (
    status != 0 ||
    !file.exists(svg_file) ||
    file.info(svg_file)$size == 0
  ) {
    status <- system2(
      pdftocairo_bin,
      args = c("-svg", shQuote(pdf_file), shQuote(svg_file))
    )
  }

  if (
    status != 0 ||
    !file.exists(svg_file) ||
    file.info(svg_file)$size == 0
  ) {
    warning("PDF-to-SVG conversion failed; the PDF remains the vector master.")
  }
} else {
  warning("pdftocairo was not found; the PDF remains the vector master.")
}

message("Figure 4 exports written to: ", output_dir)
