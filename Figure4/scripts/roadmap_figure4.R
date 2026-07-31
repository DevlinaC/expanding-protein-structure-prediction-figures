#!/usr/bin/env Rscript

# =============================================================================
# Figure 4: Toward state-space protein structure prediction
#
# PURPOSE
#   Rebuild figure draft as a reproducible portrait roadmap.
#   The target is a conformational state space surrounded by six interlocking
#   components connected by labeled, clockwise data-flow arrows.
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
#     ../parts_fig4/context_icons/128WellPlateTop0001_perturbation.svg
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
#     Cycle arrows/labels   links
#     Ellipse icons         draw_module_icon()
#     Central state space   draw_state_space_card()
#     Bottom text/layout    draw_contribution_strip()
#     Bottom icons          draw_contribution_icon()
#     Output file name      OUTPUT_STEM
#
# LAYOUT CONVENTIONS
#   - Coordinates use grid's normalized parent coordinates ("npc"):
#       x = 0 is left, x = 1 is right, y = 0 is bottom, y = 1 is top.
#   - `modules$r` is the shared base size; MODULE_RX_SCALE and MODULE_RY_SCALE
#     convert it into a consistent, slightly horizontal ellipse.
#   - Use "\n" inside a label to control line breaks explicitly.
#   - All six roadmap ellipses intentionally share one base size.
#   - Cycle arrows intentionally stop short of the ellipses by a uniform gap.
#     If modules move, update both the arrow endpoints and label coordinates.
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

script_path <- resolve_script_path("figure4_roadmap_v2.R")
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
FLOW_LABEL_SIZE <- 9.5
CONTRIBUTION_TEXT_SIZE <- 7.2
OUTPUT_STEM <- "figure4_state_space_roadmap_v2"

# Roadmap nodes are slightly wider than tall. RY is converted to npc units so
# the physical ellipse proportions remain stable on the portrait device.
MODULE_RX_SCALE <- 1.12
MODULE_RY_SCALE <- 1.05

# Bounding boxes are c(left, bottom, right, top), in npc units.
TARGET_CARD_BOX <- c(0.355, 0.322, 0.645, 0.695)
CONTRIBUTION_STRIP_BOX <- c(0.015, 0.012, 0.985, 0.120)

COL <- list(
  ink = "#111827",
  ink_soft = "#374151",
  grey = "#6B7280",
  grey_mid = "#9CA3AF",
  grey_light = "#D1D5DB",
  grey_fill = "#F5F7FA",
  contribution_fill = "#EAF4FB",
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

# One row per roadmap component, ordered clockwise.
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
  y = c(0.805, 0.695, 0.435, 0.225, 0.435, 0.695),
  r = rep(0.095, 6),
  title = c(
    "Training Data",
    "Landscape\nBenchmarks",
    "Prediction\nObjective",
    "Physics-Based\nModeling",
    "Perturbation\nModeling",
    "Experimental\nFeedback"
  ),
  subtitle = c(
    "Multi-state structures\n+ context",
    "Basin recovery\n+ populations",
    "Ensembles\n+ uncertainty",
    "Energetics + transitions",
    "Mutations + ligands\n+ environment",
    "Validation\n+ mechanism"
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

# One row per clockwise cycle connection.
#   source/target  module IDs for documentation and validation
#   x0, y0         start of the visible arrow
#   x1, y1         arrowhead position
#   curvature      0 for a straight arrow; signed values bend the curve
#   label_x/y      center of the concise data-flow label
# Endpoints are deliberately outside the ellipses, leaving a consistent gap.
links <- data.frame(
  source = 1:6,
  target = c(2, 3, 4, 5, 6, 1),
  x0 = c(0.601, 0.820, 0.732, 0.412, 0.180, 0.281),
  y0 = c(0.770, 0.588, 0.374, 0.276, 0.542, 0.730),
  x1 = c(0.719, 0.820, 0.588, 0.268, 0.180, 0.399),
  y1 = c(0.730, 0.542, 0.276, 0.374, 0.588, 0.770),
  curvature = c(-0.16, 0, -0.15, -0.15, 0, -0.16),
  label = c(
    "state/context\ncases",
    "recovery\nmetrics",
    "ensemble\ntargets",
    "energy/rate\nconstraints",
    "testable\npredictions",
    "measured states\n+ populations"
  ),
  label_x = c(0.665, 0.945, 0.755, 0.245, 0.055, 0.325),
  label_y = c(0.820, 0.565, 0.305, 0.305, 0.565, 0.825),
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
  nrow(links) != 6 ||
  any(!links$source %in% modules$id) ||
  any(!links$target %in% modules$id)
) {
  stop("`links` must define six valid connections between module IDs 1-6.")
}

layout_values <- c(
  modules$x, modules$y, modules$r,
  links$x0, links$y0, links$x1, links$y1,
  links$label_x, links$label_y,
  TARGET_CARD_BOX, CONTRIBUTION_STRIP_BOX
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

img_plate <- read_svg_asset(
  file.path(context_dir, "128WellPlateTop0001_perturbation.svg"),
  width = 1200
)
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
  # `scale` changes the test tube and population trace together. The main
  # Experimental Feedback ellipse and bottom strip deliberately use reduced
  # scales so neither motif touches its container.
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

  # Number badge.
  badge_y <- y + ry - 0.018
  draw_circle(badge_y * 0 + x, badge_y, 0.0175, COL$white, COL$grey_light, 0.8)
  draw_text(
    as.character(module$id),
    x,
    badge_y,
    fontsize = 11.5,
    col = COL$ink,
    fontface = "bold"
  )

  multi_title <- grepl("\n", module$title, fixed = TRUE)
  title_y <- y + if (multi_title) 0.025 else 0.035
  # Keep a clean gap between the subtitle block and the icon row.
  subtitle_y <- y - if (multi_title) 0.022 else 0.008

  draw_text(
    module$title,
    x,
    title_y,
    fontsize = if (multi_title) 11.4 else 12.2,
    col = COL$white,
    fontface = "bold",
    lineheight = 0.91
  )
  draw_text(
    module$subtitle,
    x,
    subtitle_y,
    fontsize = 8.6,
    col = COL$white,
    fontface = "bold",
    lineheight = 0.92
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
  y_offset <- if (key == "physics") {
    0.057
  } else if (key == "training") {
    0.062
  } else {
    0.068
  }
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
    # lower arc of the Experimental Feedback ellipse.
    draw_experiment_icon(x, y + 0.005, COL$white, scale = 0.78)
  }
}

# -----------------------------------------------------------------------------
# Central target card
# -----------------------------------------------------------------------------

draw_state_label <- function(label, pop_expr, x, y, col) {
  draw_text(label, x, y, 8.4, col, "bold")
  draw_math(pop_expr, x, y - 0.014, 7.4, col, "bold")
}

draw_state_space_card <- function() {
  # The card geometry is controlled by TARGET_CARD_BOX. State coordinates below
  # are independent of the outer cycle and may be edited without moving modules.
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

  draw_text("TARGET", 0.50, 0.675, 9.0, COL$ink, "bold")
  draw_text(
    "Conformational\nState Space",
    0.50,
    0.645,
    12.8,
    COL$ink,
    "bold",
    lineheight = 0.92
  )

  # State centers. Keep labels and transition endpoints synchronized if these
  # coordinates change.
  state <- list(
    A = c(0.500, 0.555),
    B = c(0.425, 0.485),
    C = c(0.575, 0.485),
    D = c(0.500, 0.410)
  )

  # Transition network behind the states. All central transitions deliberately
  # use the same grey, solid, bidirectional arrow style.
  draw_arrow(0.484, 0.540, 0.444, 0.501, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.516, 0.540, 0.556, 0.501, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.500, 0.532, 0.500, 0.433, COL$grey, 1.05, "both", 0.045)
  draw_arrow(0.450, 0.485, 0.550, 0.485, COL$grey, 0.95, "both", 0.045, 2)
  draw_arrow(0.444, 0.466, 0.482, 0.426, COL$grey, 1.00, "both", 0.045)
  draw_arrow(
    0.518,
    0.426,
    0.556,
    0.466,
    COL$grey,
    1.00,
    "both",
    0.045
  )

  # State halos.
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
    bquote("(pop. " * p[A] * ")"),
    state$A[1],
    0.604,
    COL$state_a
  )
  draw_state_label(
    "State B",
    bquote("(pop. " * p[B] * ")"),
    state$B[1] - 0.010,
    0.533,
    COL$state_b
  )
  draw_state_label(
    "State C",
    bquote("(pop. " * p[C] * ")"),
    state$C[1] + 0.010,
    0.533,
    COL$state_c
  )
  draw_state_label(
    "State D",
    bquote("(pop. " * p[D] * ")"),
    state$D[1] - 0.075,
    0.425,
    COL$state_d
  )

  # Output definition.
  bullets <- c(
    "States (structures)",
    "Populations",
    "Transitions / pathways",
    "Context dependence"
  )
  ys <- c(0.375, 0.360, 0.345, 0.330)
  for (i in seq_along(bullets)) {
    draw_circle(0.405, ys[i], 0.0022, COL$ink, NA)
    draw_text(
      bullets[i],
      0.415,
      ys[i],
      8.0,
      COL$ink,
      "bold",
      just = "left"
    )
  }
}

# -----------------------------------------------------------------------------
# Bottom contribution strip
# -----------------------------------------------------------------------------

draw_contribution_icon <- function(id, x, y, col) {
  # IDs follow the clockwise module order:
  # 1 training, 2 benchmarks, 3 objective, 4 physics, 5 perturbation,
  # 6 experimental feedback.
  if (id == 1) {
    draw_image(img_plate, x, y, 0.034, 0.027)
  }
  if (id == 2) {
    draw_target_icon(x, y, col, scale = 1.15)
  }
  if (id == 3) {
    draw_density_curve(x, y, 0.036, 0.032, col, 1.15)
    for (dx in c(-0.010, 0, 0.010)) {
      draw_circle(x + dx, y + 0.006, 0.0025, adjustcolor(col, 0.55), NA)
    }
  }
  if (id == 4) {
    draw_energy_curve(x, y, 0.048, 0.034, col, label_mode = "delta_g")
  }
  if (id == 5) {
    draw_ligand(x, y, col, 0.82)
    draw_circle(x - 0.017, y + 0.016, 0.0038, fill = NA, col = col, lwd = 1)
    draw_circle(x + 0.017, y - 0.016, 0.0038, fill = NA, col = col, lwd = 1)
  }
  if (id == 6) {
    # A simple test-tube + population trace reads more clearly at publication
    # size than the detailed NMR instrument artwork used in early drafts.
    draw_experiment_icon(x, y, col, scale = 0.78)
  }
}

draw_contribution_strip <- function() {
  # The bottom strip is a compact summary, not a second legend. Keep phrases
  # short enough to remain readable at final publication width.
  strip <- CONTRIBUTION_STRIP_BOX
  draw_roundrect(
    strip,
    fill = COL$contribution_fill,
    col = COL$grey_mid,
    lwd = 0.8,
    radius = 0.008
  )

  first_right <- 0.145
  draw_text(
    "What each\ncomponent\ncontributes",
    0.076,
    0.067,
    7.7,
    COL$ink_soft,
    "bold",
    lineheight = 0.94
  )

  grid.lines(
    x = unit(c(first_right, first_right), "npc"),
    y = unit(c(0.020, 0.113), "npc"),
    gp = gpar(col = COL$grey_light, lwd = 0.8)
  )

  contribution_text <- c(
    "Diverse states /\ncontexts",
    "State / population\nrecovery",
    "Calibrated\nensembles",
    "Energetic / kinetic\nplausibility",
    "Perturbation\ngeneralization",
    "Empirical populations\n+ mechanisms"
  )

  cell_w <- (strip[3] - first_right) / 6
  for (i in 1:6) {
    left <- first_right + (i - 1) * cell_w
    right <- left + cell_w

    if (i > 1) {
      grid.lines(
        x = unit(c(left, left), "npc"),
        y = unit(c(0.020, 0.113), "npc"),
        gp = gpar(col = COL$grey_light, lwd = 0.75)
      )
    }

    icon_x <- (left + right) / 2
    text_x <- icon_x
    draw_contribution_icon(i, icon_x, 0.092, modules$colour[i])
    draw_text(
      contribution_text[i],
      text_x,
      0.044,
      CONTRIBUTION_TEXT_SIZE,
      COL$ink,
      "bold",
      just = "centre",
      lineheight = 0.98
    )
  }
}

# -----------------------------------------------------------------------------
# Complete figure
# -----------------------------------------------------------------------------

draw_figure <- function() {
  grid.newpage()
  grid.rect(gp = gpar(fill = COL$white, col = NA))

  # Title block.
  draw_text(
    "Toward State-Space Protein Structure Prediction",
    0.50,
    0.968,
    18.0,
    COL$ink,
    "bold"
  )
  draw_text(
    "A roadmap for recovering the conformational state space",
    0.50,
    0.935,
    11.8,
    COL$ink_soft,
    "italic"
  )

  # Draw the cycle arrows first so their endpoints sit behind the nodes.
  for (i in seq_len(nrow(links))) {
    link <- links[i, ]
    if (link$curvature == 0) {
      draw_arrow(
        link$x0,
        link$y0,
        link$x1,
        link$y1,
        link$colour,
        lwd = 5.8,
        ends = "last",
        length_in = 0.165
      )
    } else {
      draw_curve_arrow(
        link$x0,
        link$y0,
        link$x1,
        link$y1,
        link$curvature,
        link$colour,
        lwd = 4.5,
        ends = "last",
        length_in = 0.135
      )
    }
  }

  # Central target.
  draw_state_space_card()

  # Six roadmap components.
  for (i in seq_len(nrow(modules))) {
    module <- modules[i, ]
    draw_module_base(module)
    draw_module_icon(module)
  }

  # Data-flow labels stay on top and remain readable near the central card.
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

  # Contribution summary.
  draw_contribution_strip()
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
