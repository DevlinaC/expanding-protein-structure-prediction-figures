# =============================================================================
# Figure 1: from single-structure prediction to conformational
# state-space prediction
#
# PURPOSE
#   Reproduce the integrated three-part Figure 1 schematic:
#     left   = current single-structure-prediction objective
#     center = proposed conformational-state-space-prediction objective
#     right  = continuum of conformational state-space topologies
#
# INPUTS AND OUTPUTS (paths are relative to this R_scripts directory)
#   Layout reference:
#     ../fig1_draft.png
#   SVG assets:
#     ../structures/
#     ../structures/context_icons/
#   Outputs:
#     ../figure_files/figure1_state_space_paradigm_v1.{png,pdf,svg}
#
# REQUIREMENTS
#   R packages: grid, magick, and svglite (svglite is needed only for SVG
#   export). The script stops with an informative error if an input SVG is
#   missing. Without svglite, PNG and PDF are still written.
#
# RUN
#   From the Figure1 directory:
#     Rscript R_scripts/creating_Figure1_state_space_paradigm.R
#   The path code also supports running the script from RStudio or another
#   working directory.
#
# EDITING GUIDE
#   1. Change the overall page size, font, or colors in "Global style".
#   2. Change panel widths/positions in the first lines of draw_figure().
#   3. Change text, box positions, and arrows within the three clearly marked
#      drawing blocks in draw_figure().
#   4. Change context-icon placement in draw_context_icons().
#   5. Change inset landscape equations in draw_landscape().
#   6. Keep all three export calls pointed at draw_figure() so PNG, PDF, and SVG
#      retain identical geometry.
#
# COORDINATE CONVENTION
#   grid "npc" coordinates are used throughout: (0, 0) is the lower-left of the
#   full canvas and (1, 1) is the upper-right. A box is always represented as
#   c(left, bottom, right, top). box_xy() converts coordinates relative to a box
#   into full-canvas coordinates; sub_box() constructs a nested box.
#
# VECTOR NOTE
#   The protein and icon SVGs are read at high resolution with magick and then
#   placed with grid.raster(). Consequently, those particular grobs are embedded
#   as raster images inside the PDF/SVG. Text, lines, boxes, arrows, and the
#   programmatically drawn landscapes remain vector elements. Replace
#   grid.raster() with native SVG-path placement if a fully vector master is
#   required.
#
# DESIGN RECORD
#   See ../working_files/Figure1_integrated_redesign_record.Rmd for the active
#   legend, scientific rationale, asset map, and transition-arrow semantics.
# =============================================================================

suppressPackageStartupMessages({
  library(grid)
  library(magick)
})

# -----------------------------------------------------------------------------
# Paths
# Resolve paths from the script location rather than assuming a fixed working
# directory. This keeps the script portable within the Figure1_parts folder.
# -----------------------------------------------------------------------------
command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)

if (length(file_arg) > 0) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[1]))
  script_dir <- dirname(script_path)
} else if (basename(getwd()) == "R_scripts") {
  script_dir <- normalizePath(getwd())
} else {
  candidate <- file.path(getwd(), "R_scripts")
  script_dir <- if (dir.exists(candidate)) normalizePath(candidate) else normalizePath(getwd())
}

parts_dir <- dirname(script_dir)
structure_dir <- file.path(parts_dir, "structures")
output_dir <- file.path(parts_dir, "figure_files")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Global style
# FIG_WIDTH and FIG_HEIGHT are in inches. Font sizes are in points. Colors use
# hexadecimal RGB values. These are the safest first settings to edit globally.
# -----------------------------------------------------------------------------
FIG_WIDTH <- 14.0
FIG_HEIGHT <- 9.33
FONT_FAMILY <- "sans"

COL <- list(
  ink = "#20242A",
  grey_dark = "#52565C",
  grey = "#858A91",
  grey_light = "#D9DDE2",
  grey_fill = "#F2F3F5",
  navy = "#173F7A",
  navy_mid = "#4E78B7",
  navy_light = "#EAF1FB",
  blue = "#2E4A9E",
  blue_fill = "#E8ECF8",
  orange = "#E8862E",
  orange_fill = "#FCECDF",
  purple = "#8E63B0",
  purple_fill = "#F2EAF7",
  green = "#56A94E",
  green_fill = "#EAF5E7",
  white = "#FFFFFF"
)

# -----------------------------------------------------------------------------
# Coordinate and drawing helpers
# All x/y/width/height values passed to these helpers are full-canvas npc units
# unless the argument is explicitly named as relative (rx, ry, rel, or y_rel).
# -----------------------------------------------------------------------------
box_xy <- function(box, rx, ry) {
  # Convert a point from coordinates relative to `box` into canvas coordinates.
  box <- unname(box)
  c(
    x = box[1] + rx * (box[3] - box[1]),
    y = box[2] + ry * (box[4] - box[2])
  )
}

sub_box <- function(box, rel) {
  # Create a nested box. `rel` is c(left, bottom, right, top), relative to box.
  p0 <- box_xy(box, rel[1], rel[2])
  p1 <- box_xy(box, rel[3], rel[4])
  unname(c(p0["x"], p0["y"], p1["x"], p1["y"]))
}

draw_roundrect <- function(box, fill = "white", col = COL$grey, lwd = 1.0,
                           radius = 0.012) {
  grid.roundrect(
    x = unit((box[1] + box[3]) / 2, "npc"),
    y = unit((box[2] + box[4]) / 2, "npc"),
    width = unit(box[3] - box[1], "npc"),
    height = unit(box[4] - box[2], "npc"),
    r = unit(radius, "snpc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_rect <- function(box, fill = "white", col = NA, lwd = 1.0) {
  grid.rect(
    x = unit((box[1] + box[3]) / 2, "npc"),
    y = unit((box[2] + box[4]) / 2, "npc"),
    width = unit(box[3] - box[1], "npc"),
    height = unit(box[4] - box[2], "npc"),
    gp = gpar(fill = fill, col = col, lwd = lwd)
  )
}

draw_text <- function(label, x, y, fontsize = 16, col = COL$ink,
                      fontface = "plain", just = "centre", rot = 0,
                      lineheight = 0.95) {
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

draw_arrow <- function(x0, y0, x1, y1, col = COL$grey_dark, lwd = 1.5,
                       ends = "last", length_in = 0.10, lty = 1) {
  # `ends` accepts "first", "last", or "both". Arrowhead length is in physical
  # inches so it remains consistent across different canvas coordinates.
  grid.lines(
    x = unit(c(x0, x1), "npc"),
    y = unit(c(y0, y1), "npc"),
    arrow = arrow(
      angle = 25,
      length = unit(length_in, "inches"),
      ends = ends,
      type = "closed"
    ),
    gp = gpar(col = col, fill = col, lwd = lwd, lty = lty, lineend = "round")
  )
}

draw_header <- function(box, kicker, subtitle, proposed = FALSE) {
  header <- sub_box(box, c(0, 0.90, 1, 1))
  draw_rect(header, fill = if (proposed) COL$navy_light else COL$grey_fill,
            col = NA)
  y_line <- box_xy(box, 0, 0.90)["y"]
  grid.lines(
    x = unit(c(box[1], box[3]), "npc"),
    y = unit(c(y_line, y_line), "npc"),
    gp = gpar(col = if (proposed) COL$navy_mid else COL$grey, lwd = 1.0)
  )
  p1 <- box_xy(box, 0.5, 0.965)
  p2 <- box_xy(box, 0.5, 0.925)
  draw_text(kicker, p1["x"], p1["y"], fontsize = 19, fontface = "bold",
            col = if (proposed) COL$navy else COL$ink)
  draw_text(subtitle, p2["x"], p2["y"], fontsize = 17, fontface = "bold",
            col = if (proposed) COL$navy else COL$ink)
}

draw_sequence <- function(x_center, y, span = 0.150, color = COL$ink) {
  # This is a schematic sequence, not the sequence of any displayed structure.
  # Edit `letters` to change the example or `span` to change its total width.
  letters <- c("M", "E", "T", "L", "Y", "K", "...", "G", "L", "V")
  xs <- seq(x_center - span / 2, x_center + span / 2,
            length.out = length(letters))
  radius <- 0.0092

  for (i in seq_along(letters)) {
    x <- xs[i]
    if (letters[i] != "...") {
      grid.circle(
        x = unit(x, "npc"), y = unit(y, "npc"), r = unit(radius, "npc"),
        gp = gpar(fill = COL$grey_fill, col = "#AEB3B9", lwd = 1.0)
      )
      draw_text(letters[i], x, y, fontsize = 13.5, col = color,
                fontface = "bold")
    } else {
      draw_text(letters[i], x, y, fontsize = 17, col = COL$grey_dark,
                fontface = "bold")
    }
  }
}

read_svg_asset <- function(filename, width = 1600) {
  # Load a protein SVG from structures/ and trim transparent outer margins.
  path <- file.path(structure_dir, filename)
  if (!file.exists(path)) stop("Missing SVG asset: ", path)
  image_read_svg(path, width = width) |>
    image_trim()
}

read_context_icon <- function(filename, width = 1000) {
  # Load an icon SVG from structures/context_icons/.
  path <- file.path(structure_dir, "context_icons", filename)
  if (!file.exists(path)) stop("Missing context icon: ", path)
  image_read_svg(path, width = width) |>
    image_trim()
}

draw_image <- function(img, x, y, width, height) {
  # Place a magick image at its center. width/height are full-canvas npc units.
  grid.raster(
    as.raster(img),
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    width = unit(width, "npc"),
    height = unit(height, "npc"),
    interpolate = TRUE
  )
}

draw_state_node <- function(x, y, label, label_col, img,
                            img_w = 0.052, img_h = 0.074) {
  # State nodes intentionally have no colored backing box.
  draw_image(img, x, y, img_w, img_h)
  draw_text(label, x, y + 0.058, fontsize = 16, col = label_col,
            fontface = "bold")
}

draw_context_icons <- function(box, ph_img, splice_img, membrane_img,
                               y_rel = 0.645) {
  # Fixed 3 x 2 icon grid, in legend order:
  #   top:    ligand, pH, mutation
  #   bottom: splice isoform, PTM, membrane environment
  # x1:x6 control horizontal placement; y_rel controls the top-row height.
  y_top <- box_xy(box, 0.5, y_rel)["y"]
  y_bottom <- box_xy(box, 0.5, y_rel - 0.055)["y"]
  x1 <- box_xy(box, 0.64, y_rel)["x"]
  x2 <- box_xy(box, 0.76, y_rel)["x"]
  x3 <- box_xy(box, 0.88, y_rel)["x"]
  x4 <- box_xy(box, 0.64, y_rel - 0.055)["x"]
  x5 <- box_xy(box, 0.76, y_rel - 0.055)["x"]
  x6 <- box_xy(box, 0.88, y_rel - 0.055)["x"]

  # Ligand cluster
  offsets <- rbind(c(0, 0), c(-0.009, 0.008), c(0.009, 0.008),
                   c(-0.006, -0.010), c(0.008, -0.010))
  for (i in seq_len(nrow(offsets))) {
    grid.circle(
      x = unit(x1 + offsets[i, 1], "npc"),
      y = unit(y_top + offsets[i, 2], "npc"),
      r = unit(0.0045, "npc"),
      gp = gpar(fill = COL$green, col = "#3C8738", lwd = 0.6)
    )
  }

  # pH droplet
  draw_image(ph_img, x2, y_top, width = 0.026, height = 0.036)

  # Mutation / sequence-variant hexagon
  theta <- seq(0, 2 * pi, length.out = 7)[-7] + pi / 6
  grid.polygon(
    x = unit(x3 + 0.010 * cos(theta), "npc"),
    y = unit(y_top + 0.012 * sin(theta), "npc"),
    gp = gpar(fill = COL$navy_mid, col = COL$navy, lwd = 0.7)
  )
  draw_text("A>G", x3, y_top, fontsize = 8, fontface = "bold",
            col = COL$white)

  # Alternative-splicing / isoform branch
  draw_image(splice_img, x4, y_bottom, width = 0.034, height = 0.032)

  # PTM star
  theta_star <- seq(pi / 2, pi / 2 + 2 * pi, length.out = 11)[-11]
  radii <- rep(c(0.014, 0.0065), 5)
  grid.polygon(
    x = unit(x5 + radii * cos(theta_star), "npc"),
    y = unit(y_bottom + radii * sin(theta_star), "npc"),
    gp = gpar(fill = "#F4C44E", col = "#D89B1D", lwd = 0.7)
  )

  # Membrane environment
  draw_image(membrane_img, x6, y_bottom, width = 0.042, height = 0.022)
}

# -----------------------------------------------------------------------------
# Inset landscape helpers
# -----------------------------------------------------------------------------
draw_landscape <- function(box, kind, label) {
  # `kind` selects one of three schematic curve equations:
  #   "single"     = one dominant basin
  #   "multi"      = two discrete basins
  #   "continuous" = broad, continuously colored ensemble
  # These curves and state markers are conceptual and not energy-scale data.
  if (!kind %in% c("single", "multi", "continuous")) {
    stop("Unknown landscape kind: ", kind)
  }

  label_p <- box_xy(box, 0.5, 0.91)
  draw_text(label, label_p["x"], label_p["y"], fontsize = 16.5,
            fontface = "bold", col = COL$ink, lineheight = 0.90)

  curve_box <- sub_box(box, c(0.08, 0.15, 0.92, 0.72))
  t <- seq(0, 1, length.out = 200)

  if (kind == "single") {
    yy <- 0.22 + 0.72 * (2 * t - 1)^2
  } else if (kind == "multi") {
    yy <- 0.60 + 0.20 * t -
      0.48 * exp(-((t - 0.25)^2) / 0.016) -
      0.43 * exp(-((t - 0.68)^2) / 0.020)
    yy <- (yy - min(yy)) / (max(yy) - min(yy)) * 0.72 + 0.18
  } else {
    yy <- 0.33 + 0.48 * (2 * t - 1)^2 +
      0.05 * sin(4 * pi * t)
  }

  xx <- curve_box[1] + t * (curve_box[3] - curve_box[1])
  yv <- curve_box[2] + yy * (curve_box[4] - curve_box[2])

  if (kind == "continuous") {
    pal <- colorRampPalette(c(COL$orange, "#E8D85A", "#80C782",
                              "#6AAFD0", COL$purple))(40)
    cuts <- seq(1, length(t), length.out = 41)
    for (i in seq_len(40)) {
      ids <- floor(cuts[i]):ceiling(cuts[i + 1])
      ids <- ids[ids >= 1 & ids <= length(t)]
      grid.polygon(
        x = unit(c(xx[ids], rev(xx[ids])), "npc"),
        y = unit(c(yv[ids], rep(curve_box[2] + 0.05 *
          (curve_box[4] - curve_box[2]), length(ids))), "npc"),
        gp = gpar(fill = pal[i], col = NA)
      )
    }
  }

  grid.lines(
    x = unit(xx, "npc"), y = unit(yv, "npc"),
    gp = gpar(col = COL$navy, lwd = 1.1, lineend = "round")
  )

  if (kind == "single") {
    p <- box_xy(curve_box, 0.50, 0.24)
    grid.circle(unit(p["x"], "npc"), unit(p["y"], "npc"),
                r = unit(0.0055, "npc"),
                gp = gpar(fill = COL$green, col = "#3C8738", lwd = 0.6))
  }

  if (kind == "multi") {
    x1 <- curve_box[1] + 0.25 * (curve_box[3] - curve_box[1])
    x2 <- curve_box[1] + 0.68 * (curve_box[3] - curve_box[1])
    y1 <- approx(t, yv, xout = 0.25)$y +
      0.08 * (curve_box[4] - curve_box[2])
    y2 <- approx(t, yv, xout = 0.68)$y +
      0.08 * (curve_box[4] - curve_box[2])
    grid.circle(unit(x1, "npc"), unit(y1, "npc"),
                r = unit(0.0055, "npc"),
                gp = gpar(fill = COL$blue, col = COL$navy, lwd = 0.6))
    grid.circle(unit(x2, "npc"), unit(y2, "npc"),
                r = unit(0.0055, "npc"),
                gp = gpar(fill = COL$orange, col = "#B96820", lwd = 0.6))
  }
}

# -----------------------------------------------------------------------------
# Load assets once
# Asset-role mapping:
#   dominant_blue.svg       current structure (desaturated) and State A
#   alt1_orange.svg         State B
#   IDP_part1.svg           State C
#   ph/splice/membrane SVGs biological-context grid
#   arrow-right-short.svg   shift-approach arrow
#
# IDP_part2.svg and IDP_part3.svg are kept in structures/archive_unused/ as
# alternate illustrative conformers that are not loaded by this script.
# -----------------------------------------------------------------------------
img_blue <- read_svg_asset("dominant_blue.svg")
img_orange <- read_svg_asset("alt1_orange.svg")
img_idp_compact <- read_svg_asset("IDP_part1.svg")
img_current <- image_modulate(img_blue, brightness = 108, saturation = 0)
img_ph <- read_context_icon("ph.svg")
img_splice <- read_context_icon("splice_concept_v2.svg")
img_membrane <- read_context_icon("membrane-2d-bluelight.svg")
img_paradigm_arrow <- read_context_icon("arrow-right-short.svg")

# -----------------------------------------------------------------------------
# Complete drawing function
# Edit this function for layout or copy changes. Major elements are positioned
# relative to their containing panel, so moving a panel usually preserves its
# internal composition.
# -----------------------------------------------------------------------------
draw_figure <- function() {
  grid.newpage()
  grid.rect(gp = gpar(fill = "white", col = NA))

  # Panel boxes use c(left, bottom, right, top) in full-canvas npc units.
  # The space between panel_a and panel_b contains the shift-approach graphic.
  panel_a <- c(0.020, 0.025, 0.370, 0.980)  # current objective
  panel_b <- c(0.465, 0.025, 0.815, 0.980)  # proposed objective
  panel_c <- c(0.830, 0.175, 0.985, 0.800)  # topology inset

  # ---------------------------------------------------------------------------
  # Left — Current objective
  # ---------------------------------------------------------------------------
  draw_roundrect(panel_a, fill = COL$white, col = COL$grey, lwd = 1.0)
  draw_header(panel_a, "CURRENT OBJECTIVE", "Single-Structure Prediction")

  p <- box_xy(panel_a, 0.5, 0.82)
  draw_text("Sequence", p["x"], p["y"], fontsize = 16, fontface = "bold")
  p_seq <- box_xy(panel_a, 0.5, 0.765)
  draw_sequence(p_seq["x"], p_seq["y"], span = 0.150)

  p0 <- box_xy(panel_a, 0.5, 0.725)
  p1 <- box_xy(panel_a, 0.5, 0.675)
  draw_arrow(p0["x"], p0["y"], p1["x"], p1["y"], lwd = 3.6,
             col = COL$grey_dark, length_in = 0.13)

  predictor_a <- sub_box(panel_a, c(0.24, 0.555, 0.76, 0.665))
  draw_roundrect(predictor_a, fill = COL$grey_fill, col = COL$grey, lwd = 1.2)
  p <- box_xy(predictor_a, 0.5, 0.5)
  draw_text("Protein-structure\npredictor", p["x"], p["y"],
            fontsize = 16, fontface = "bold")

  p0 <- box_xy(panel_a, 0.5, 0.555)
  p1 <- box_xy(panel_a, 0.5, 0.505)
  draw_arrow(p0["x"], p0["y"], p1["x"], p1["y"], lwd = 3.6,
             col = COL$grey_dark, length_in = 0.13)

  p <- box_xy(panel_a, 0.5, 0.475)
  draw_text("Single predicted structure", p["x"], p["y"],
            fontsize = 15, fontface = "bold")
  p_img <- box_xy(panel_a, 0.5, 0.350)
  draw_image(img_current, p_img["x"], p_img["y"], 0.090, 0.135)

  p0 <- box_xy(panel_a, 0.5, 0.245)
  p1 <- box_xy(panel_a, 0.5, 0.195)
  draw_arrow(p0["x"], p0["y"], p1["x"], p1["y"], lwd = 3.6,
             col = COL$grey_dark, length_in = 0.13)

  p <- box_xy(panel_a, 0.5, 0.135)
  draw_text("Biological function", p["x"], p["y"], fontsize = 15.5,
            fontface = "bold")
  p <- box_xy(panel_a, 0.5, 0.095)
  draw_text("(inferred from one structure)", p["x"], p["y"], fontsize = 13,
            col = COL$grey_dark, fontface = "bold")

  # ---------------------------------------------------------------------------
  # Paradigm-shift label and supplied SVG arrow
  # These use full-canvas coordinates because they sit between panel boxes.
  # ---------------------------------------------------------------------------
  draw_text("SHIFT\nAPPROACH", 0.418, 0.625, fontsize = 15,
            fontface = "bold", col = COL$navy, lineheight = 0.9)
  draw_image(img_paradigm_arrow, 0.416, 0.545, width = 0.072, height = 0.051)

  # ---------------------------------------------------------------------------
  # Center — Proposed objective
  # ---------------------------------------------------------------------------
  draw_roundrect(panel_b, fill = COL$white, col = COL$navy_mid, lwd = 1.1)
  draw_header(panel_b, "PROPOSED OBJECTIVE",
              "Conformational State-Space Prediction", proposed = TRUE)

  p <- box_xy(panel_b, 0.27, 0.815)
  draw_text("Sequence", p["x"], p["y"], fontsize = 16, fontface = "bold")
  p_seq <- box_xy(panel_b, 0.27, 0.750)
  draw_sequence(p_seq["x"], p_seq["y"], span = 0.150)

  p <- box_xy(panel_b, 0.76, 0.815)
  draw_text("Biological context", p["x"], p["y"], fontsize = 16,
            fontface = "bold", col = COL$navy)
  draw_context_icons(
    panel_b,
    ph_img = img_ph,
    splice_img = img_splice,
    membrane_img = img_membrane,
    y_rel = 0.755
  )

  seq_start <- box_xy(panel_b, 0.31, 0.690)
  seq_end <- box_xy(panel_b, 0.45, 0.650)
  ctx_start <- box_xy(panel_b, 0.72, 0.690)
  ctx_end <- box_xy(panel_b, 0.56, 0.650)
  draw_arrow(seq_start["x"], seq_start["y"], seq_end["x"], seq_end["y"],
             lwd = 2.2, col = COL$ink, length_in = 0.11)
  draw_arrow(ctx_start["x"], ctx_start["y"], ctx_end["x"], ctx_end["y"],
             lwd = 2.2, col = COL$ink, length_in = 0.11)

  predictor_b <- sub_box(panel_b, c(0.31, 0.535, 0.69, 0.625))
  draw_roundrect(predictor_b, fill = COL$navy_light, col = COL$navy_mid,
                 lwd = 1.2)
  p <- box_xy(predictor_b, 0.5, 0.5)
  draw_text("State-space\npredictor", p["x"], p["y"],
            fontsize = 16, fontface = "bold", col = COL$navy)

  p0 <- box_xy(panel_b, 0.5, 0.535)
  p1 <- box_xy(panel_b, 0.5, 0.495)
  draw_arrow(p0["x"], p0["y"], p1["x"], p1["y"], lwd = 3.0,
             col = COL$navy, length_in = 0.11)

  p <- box_xy(panel_b, 0.5, 0.465)
  draw_text("Conformational state space", p["x"], p["y"],
            fontsize = 15, fontface = "bold", col = COL$navy)

  state_a <- box_xy(panel_b, 0.24, 0.345)
  state_b <- box_xy(panel_b, 0.50, 0.285)
  state_c <- box_xy(panel_b, 0.76, 0.345)

  # Transition semantics (also stated in the active figure legend):
  #   B -> A  solid and directional
  #   B <-> C solid and reversible
  #   A <-> C solid and reversible
  # Endpoint offsets keep arrowheads clear of the protein structures.
  draw_arrow(state_b["x"] - 0.033, state_b["y"] + 0.020,
             state_a["x"] + 0.031, state_a["y"] - 0.024,
             col = COL$grey_dark, lwd = 1.9, ends = "last",
             length_in = 0.080)
  draw_arrow(state_b["x"] + 0.033, state_b["y"] + 0.020,
             state_c["x"] - 0.031, state_c["y"] - 0.024,
             col = COL$grey_dark, lwd = 1.9, ends = "both",
             length_in = 0.080)
  draw_arrow(state_a["x"] + 0.032, state_a["y"] + 0.014,
             state_c["x"] - 0.032, state_c["y"] + 0.014,
             col = COL$grey_dark, lwd = 2.0, ends = "both",
             length_in = 0.080)

  draw_state_node(state_a["x"], state_a["y"], "State A", COL$blue,
                  img_blue, img_w = 0.046, img_h = 0.067)
  draw_state_node(state_b["x"], state_b["y"], "State B", COL$orange,
                  img_orange, img_w = 0.051, img_h = 0.058)
  draw_state_node(state_c["x"], state_c["y"], "State C", COL$purple,
                  img_idp_compact, img_w = 0.053, img_h = 0.057)
  p <- box_xy(panel_b, 0.90, 0.345)
  draw_text("...", p["x"], p["y"], fontsize = 17, col = COL$grey_dark,
            fontface = "bold")

  output_box <- sub_box(panel_b, c(0.05, 0.100, 0.95, 0.230))
  draw_roundrect(output_box, fill = COL$navy_light, col = COL$navy_mid,
                 lwd = 1.2)
  p <- box_xy(output_box, 0.5, 0.82)
  draw_text("Outputs", p["x"], p["y"], fontsize = 15,
            fontface = "bold", col = COL$navy)
  p <- box_xy(output_box, 0.05, 0.42)
  draw_text("- Accessible states\n- Relative populations\n- Transition pathways",
            p["x"], p["y"], fontsize = 13.5, just = "left",
            lineheight = 0.95, fontface = "bold")
  p <- box_xy(output_box, 0.55, 0.42)
  draw_text("- Context dependence\n- Perturbation\n  response",
            p["x"], p["y"], fontsize = 13.5, just = "left",
            lineheight = 0.95, fontface = "bold")

  p0 <- box_xy(panel_b, 0.5, 0.095)
  p1 <- box_xy(panel_b, 0.5, 0.065)
  draw_arrow(p0["x"], p0["y"], p1["x"], p1["y"], lwd = 3.0,
             col = COL$navy, length_in = 0.11)
  p <- box_xy(panel_b, 0.5, 0.042)
  draw_text("Biological function", p["x"], p["y"], fontsize = 15.5,
            fontface = "bold", col = COL$navy)
  p <- box_xy(panel_b, 0.5, 0.018)
  draw_text("(emergent from state space and dynamics)", p["x"], p["y"],
            fontsize = 12.5, col = COL$navy, fontface = "bold")

  # ---------------------------------------------------------------------------
  # Right inset — State-space topology continuum
  # ---------------------------------------------------------------------------
  draw_roundrect(panel_c, fill = COL$white, col = COL$navy_mid, lwd = 1.0)
  p <- box_xy(panel_c, 0.5, 0.935)
  draw_text("Conformational\nstate-space\ntopologies", p["x"], p["y"],
            fontsize = 15, fontface = "bold", col = COL$navy,
            lineheight = 0.90)

  land1 <- sub_box(panel_c, c(0.05, 0.66, 0.95, 0.86))
  land2 <- sub_box(panel_c, c(0.05, 0.40, 0.95, 0.62))
  land3 <- sub_box(panel_c, c(0.05, 0.14, 0.95, 0.36))
  draw_landscape(land1, "single", "Single basin")
  draw_landscape(land2, "multi", "Discrete\nmulti-basin")
  draw_landscape(land3, "continuous", "Continuous\nensemble")

  for (yy in c(0.64, 0.38)) {
    # Separator positions are relative to panel_c and intentionally subtle.
    p0 <- box_xy(panel_c, 0.08, yy)
    p1 <- box_xy(panel_c, 0.92, yy)
    grid.lines(
      x = unit(c(p0["x"], p1["x"]), "npc"),
      y = unit(c(p0["y"], p1["y"]), "npc"),
      gp = gpar(col = "#C5CBD3", lwd = 1.0, lty = 2)
    )
  }
  p <- box_xy(panel_c, 0.5, 0.065)
  draw_text("Proteins span\na continuum of\nstate-space topologies",
            p["x"], p["y"], fontsize = 13.5, fontface = "bold",
            col = COL$grey_dark, lineheight = 0.90)
}

# -----------------------------------------------------------------------------
# Export all formats from the same drawing function
# PNG is the 300-dpi review/preview file. PDF is suitable for manuscript
# assembly. SVG is written only when svglite is installed. Do not introduce
# format-specific drawing changes here; edit draw_figure() instead.
# -----------------------------------------------------------------------------
png(
  filename = file.path(output_dir, "figure1_state_space_paradigm_v1.png"),
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  units = "in",
  res = 300,
  bg = "white"
)
draw_figure()
dev.off()

pdf(
  file = file.path(output_dir, "figure1_state_space_paradigm_v1.pdf"),
  width = FIG_WIDTH,
  height = FIG_HEIGHT,
  useDingbats = FALSE,
  bg = "white"
)
draw_figure()
dev.off()

if (requireNamespace("svglite", quietly = TRUE)) {
  svglite::svglite(
    file = file.path(output_dir, "figure1_state_space_paradigm_v1.svg"),
    width = FIG_WIDTH,
    height = FIG_HEIGHT,
    bg = "white"
  )
  draw_figure()
  dev.off()
} else {
  message(
    "SVG export skipped: install the 'svglite' package or use an R build ",
    "with a working Cairo SVG device."
  )
}

message("Saved Figure 1 redesign to: ", output_dir)
