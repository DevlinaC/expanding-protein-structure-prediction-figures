# =============================================================================
# Figure 3: cartoon-style guidance for structure prediction
#
# Four stages are arranged left-to-right beneath the evidence bar:
#   1. Dominant model
#   2. Alternative states
#   3. Physical testing
#   4. Experimental evidence
#
# The script keeps text to short stage labels and uses SVG cartoons
# to communicate the biological triggers represented as text in v5.
#
# QUICK START
#   From the Figure3 directory:
#     Rscript scripts/practical_guidelines_cartoon.R
#
# INPUTS
#   icons_candidates/CTD_alpha_vectorized.svg
#   icons_candidates/CTD_beta_vectorized.svg
#   icons_candidates/IDP_part3.svg
#   icons_candidates/homolog_phylogeny.svg
#   icons_candidates/TestTubeRack0001-red.svg
#
# OUTPUTS
#   figure_versions/Figure3_cartoon_v6.{png,pdf}
#
# REQUIRED R PACKAGES
#   ggplot2, magick, and rsvg. `grid` is included with R.
#
# PATHS
#   The script resolves the figure directory from its own file location, so it
#   can be run from the Figure3 directory, the scripts directory, or RStudio.
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
  library(magick)
  library(rsvg)
})

# ---- Resolve paths relative to this script -------------------
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) == 1) {
  # R may encode spaces in --file paths as "~+~".
  script_file <- sub("^--file=", "", script_arg[1])
  script_file <- gsub("~\\+~", " ", script_file)
  script_dir <- dirname(normalizePath(script_file, mustWork = TRUE))
} else if (basename(getwd()) == "scripts") {
  script_dir <- normalizePath(getwd(), mustWork = TRUE)
} else if (basename(getwd()) == "Figure3") {
  script_dir <- normalizePath(file.path(getwd(), "scripts"), mustWork = TRUE)
} else {
  stop("Run this script from the Figure3 directory, the scripts directory, or RStudio.")
}

figure_dir <- normalizePath(file.path(script_dir, ".."), mustWork = TRUE)
icons_dir <- file.path(figure_dir, "icons_candidates")
output_dir <- file.path(figure_dir, "figure_versions")
if (!dir.exists(icons_dir)) stop("Missing icon directory: ", icons_dir)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

icon <- function(filename) file.path(icons_dir, filename)

# ---- Palette -------------------------------------------------
tier_fill <- c(
  "#8FBFA5", # fast / dominant-state model
  "#E9C46A", # alternative-state hypotheses
  "#E8925A", # physical plausibility
  "#C1666B"  # population and mechanism evidence
)

tier_dark <- c(
  "#3F7D5F",
  "#A87508",
  "#B9531D",
  "#912E36"
)

state_blue   <- "#3E4A89"
state_orange <- "#FD8D62"
ink          <- "#4D4D4D"

# ---- Helpers for placing editable SVG assets ----------------
# Phosphor icons use currentColor. Supplying colour replaces it without
# changing the source SVG, so the same asset can be reused across tiers.
svg_raster <- function(path, colour = NULL, trim = TRUE, width = 900,
                       flip = FALSE, rotate = 0) {
  svg_text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                    collapse = "\n")

  # NIH BioArt SVG exports use a harmless namespace prefix that some
  # renderers do not understand. Normalize it in memory if present.
  svg_text <- gsub("ns0:", "", svg_text, fixed = TRUE)
  svg_text <- gsub("xmlns:ns0=", "xmlns=", svg_text, fixed = TRUE)

  if (!is.null(colour)) {
    svg_text <- gsub("currentColor", colour, svg_text, fixed = TRUE)
  }

  # Render from the modified in-memory SVG rather than rewriting source files.
  img <- image_read(rsvg_png(charToRaw(svg_text), width = width))
  if (trim) img <- image_trim(img)
  if (flip) img <- image_flop(img)
  if (rotate != 0) {
    img <- image_rotate(img, rotate)
    # ImageMagick 6 fills newly exposed rotation corners with white.
    # Restore transparency so rotated proteins sit cleanly on the card.
    img <- image_transparent(img, "white", fuzz = 8)
  }
  as.raster(img)
}

add_svg <- function(plot, path, x, y, width, height,
                    colour = NULL, trim = TRUE,
                    flip = FALSE, rotate = 0) {
  grob <- rasterGrob(
    svg_raster(
      path, colour = colour, trim = trim,
      flip = flip, rotate = rotate
    ),
    interpolate = TRUE
  )
  plot + annotation_custom(
    grob,
    xmin = x - width / 2, xmax = x + width / 2,
    ymin = y - height / 2, ymax = y + height / 2
  )
}

# ---- Canvas and stage cards ---------------------------------
card_centres <- c(2.2, 6.1, 10.0, 13.9)
card_width   <- 3.45
card_bottom  <- 1.05
card_top     <- 7.55

cards <- data.frame(
  x = card_centres,
  xmin = card_centres - card_width / 2,
  xmax = card_centres + card_width / 2,
  fill = tier_fill,
  dark = tier_dark,
  label = c(
    "Single struture prediction",
    "Alternative state sampling",
    "Energetic refinement",
    "Experiments"
  )
)

p <- ggplot() +
  # softly colored stage cards
  geom_rect(
    data = cards,
    aes(xmin = xmin, xmax = xmax, ymin = card_bottom, ymax = card_top),
    fill = cards$fill, alpha = 0.12,
    colour = cards$fill, linewidth = 1.1
  ) +
  # colored header bands
  geom_rect(
    data = cards,
    aes(xmin = xmin, xmax = xmax, ymin = 6.83, ymax = card_top),
    fill = cards$fill, colour = NA
  ) +
  geom_text(
    data = cards,
    aes(x = x, y = 7.19, label = label),
    colour = "white", fontface = "bold", size = 6.2,
    family = "sans"
  ) +
  # light arrows show escalation without implying strict exclusivity
  annotate(
    "segment",
    x = cards$xmax[-4] + 0.10,
    xend = cards$xmin[-1] - 0.10,
    y = 4.25, yend = 4.25,
    colour = "#9A9A9A", linewidth = 0.9,
    arrow = arrow(type = "closed", length = unit(2.5, "mm"))
  )

# ---- Top organizing axis: fast/approximate -> rigorous/experimental
n_grad <- 500
grad_cols <- colorRampPalette(tier_fill)(n_grad)
grad_x <- seq(0.55, 15.6, length.out = n_grad + 1)

gradient_df <- data.frame(
  xmin = grad_x[-length(grad_x)],
  xmax = grad_x[-1]+0.06,
  fill = grad_cols
)

p <- p +
  geom_rect(
    data = gradient_df,
    aes(xmin = xmin, xmax = xmax, ymin = 8.42, ymax = 8.90,
        fill = fill),
    colour = NA
  ) +
  scale_fill_identity() +
  annotate(
    "segment",
    x = 0.55, xend = 15.53, y = 8.66, yend = 8.66,
    colour = "transparent",
    arrow = arrow(type = "closed", length = unit(3.2, "mm"))
  ) +
  annotate(
    "text", x = 0.55, y = 9.12,
    label = "PARTIAL REPRESENTATION",
    hjust = 0, fontface = "bold", size = 4.4, colour = tier_dark[1]
  ) +
  annotate(
    "text", x = 15.45+0.15, y = 9.12,
    label = "MORE COMPLETE REPRESENTATION",
    hjust = 1, fontface = "bold", size = 4.4, colour = tier_dark[4]
  ) +
  annotate(
    "text", x = 2.2, y = 8.66,
    label = "COORDINATES",
    fontface = "bold", size = 6.4, colour = "white"
  )+
  annotate(
    "text", x = 6.1, y = 8.66,
    label = "+MULTIPLE STATES",
    fontface = "bold", size = 6.4, colour = "white"
  )+
  annotate(
    "text", x = 10.0, y = 8.66,
    label = "+ENERGETICS",
    fontface = "bold", size = 6.4, colour = "white"
  )+
  annotate(
    "text", x = 13.9, y = 8.66,
    label = "+VALIDATED MECHANISMS",
    fontface = "bold", size = 6.4, colour = "white"
  )

# ---- Stage 1: dominant basin / one likely state --------------
# A simple energy basin is drawn directly in R so it remains vector.
basin_x <- seq(0.90, 3.50, length.out = 120)
basin_y <- 3.80 + 1.05 * ((basin_x - 2.20) / 1.30)^2
#basin_y = 3.8

p <- p +
  geom_path(
    data = data.frame(x = basin_x, y = basin_y),
    aes(x, y), colour = tier_dark[1], linewidth = 1.5,
    lineend = "round"
  ) +
  annotate(
    "text", x = 2.20, y = 3.3,
    label = "Coordinates", fontface = "bold",
    size = 5.8, colour = tier_dark[1]
  ) +
 annotate(
  "text", x = 2.20, y = 1.90,
  label = "Methods:\nAlphaFold2,3\nOpenFold2,3\nRoseTTAFold\nESMFold2", fontface = "bold",
  size = 5, colour = tier_dark[1]
)

p <- add_svg(
  p, icon("CTD_alpha_vectorized.svg"),
  x = 2.20, y = 5.28, width = 1.38, height = 2.15
)

# ---- Stage 2: alternative-state triggers ---------------------
# Phylogeny = divergent homolog groups; paired orange proteins = partner context;
# residue marker = variant; IDP ensemble = disorder/broad ensemble.
p <- add_svg(
  p, icon("homolog_phylogeny.svg"),
  x = 6.10, y = 5.62, width = 2.65, height = 1.82
)
p <- p +
  annotate(
    "text", x = 6.10, y = 4.65,
    label = "Divergent homologs", fontface = "bold",
    size = 3.5, colour = tier_dark[2]
  )
p <- add_svg(
  p, icon("CTD_beta_vectorized.svg"),
  x = 4.87, y = 4.0, width = 0.72, height = 0.68,
  rotate = -12
)
p <- add_svg(
  p, icon("CTD_beta_vectorized.svg"),
  x = 5.24, y = 4.0, width = 0.72, height = 0.68,
  flip = TRUE, rotate = 12
)
p <- add_svg(
  p, icon("IDP_part3.svg"),
  x = 6.25, y = 4.0, width = 1.25, height = 0.95
)
p <- add_svg(
  p, icon("CTD_alpha_vectorized.svg"),
  x = 7.33, y = 4.0, width = 0.70, height = 1.05
)
p <- p +
  annotate(
    "point", x = 7.60, y = 4.30,
    shape = 21, size = 5.2, stroke = 1.1,
    fill = tier_dark[2], colour = "white"
  )

# Minimal environment cartoon: pH droplet plus ions.
drop <- data.frame(
  x = c(4.83, 4.65, 4.69, 4.83, 4.97, 5.01, 4.83),
  y = c(2.60, 2.27, 2.03, 1.90, 2.03, 2.27, 2.60)
)
#p <- p +
#  geom_polygon(
#    data = drop, aes(x, y),
#    fill = "#CFE8F3", colour = "#397A93", linewidth = 0.8
#  ) +
#  annotate("text", x = 4.83, y = 2.18, label = "pH",
#           fontface = "bold", size = 3.2, colour = "#397A93") +
#  annotate("point", x = c(5.42, 5.77), y = c(2.18, 2.36),
#           size = c(6.0, 5.2), shape = 21, stroke = 0.8,
#           fill = c("#8EC7E6", "#B99AD6"), colour = "white") +
#  annotate("text", x = c(5.42, 5.77), y = c(2.18, 2.36),
#           label = c("+", "-"), fontface = "bold", size = 3.0,
#    
p <- p +
  annotate(
      "text", x = 6.10, y = 3.3,
      label = "Accessible states", fontface = "bold",
      size = 5.8, colour = tier_dark[2]
    )

p <- p+
  annotate(
    "text", x = 6.10, y = 1.90,
    label = "Methods:\nCF-random\nMSA subsampling\nAFSample2,3\nAFCluster", fontface = "bold",
    size = 5, colour = tier_dark[2]
  )

# ---- Stage 3: stability, barriers and timescale --------------
# Cartoon double-well landscape drawn as a vector path.
landscape_control <- data.frame(
  x = c(8.55, 8.80, 9.02, 9.20, 9.38, 9.62, 9.88,
        10.10, 10.33, 10.54, 10.74, 10.96, 11.20, 11.45),
  y = c(5.90, 5.55, 4.68, 4.18, 4.63, 5.22, 5.72,
        5.28, 4.54, 4.05, 4.42, 5.08, 5.54, 5.85)
)
landscape_spline <- spline(
  landscape_control$x, landscape_control$y,
  n = 240, method = "natural"
)
landscape <- data.frame(x = landscape_spline$x, y = landscape_spline$y)

p <- p +
  geom_path(
    data = landscape, aes(x, y),
    colour = tier_dark[3], linewidth = 1.6,
    lineend = "round", linejoin = "round"
  ) +
  annotate(
    "segment", x = 9.60, xend = 10.45, y = 4.83, yend = 4.83,
    colour = tier_dark[3], linewidth = 1.0,
    arrow = arrow(type = "closed", length = unit(2.4, "mm"))
  )

p <- p +
  annotate(
    "text", x = 9.23, y = 3.8,
    label = "40%", fontface = "bold",
    size = 4.4, colour = "black")

p <- p +
  annotate(
    "text", x = 10.63, y = 3.8,
    label = "60%", fontface = "bold",
    size = 4.4, colour = "black")

p <- add_svg(
  p, icon("CTD_alpha_vectorized.svg"),
  x = 9.20, y = 4.45, width = 0.36, height = 0.55
)
p <- add_svg(
  p, icon("CTD_beta_vectorized.svg"),
  x = 10.55, y = 4.35, width = 0.48, height = 0.46
)

# A second pair of protein snapshots makes the transition/pathway explicit
# without introducing a third icon family.
#p <- add_svg(
#  p, icon("CTD_alpha_vectorized.svg"),
#  x = 9.15, y = 2.70, width = 0.45, height = 0.70
#)
#p <- add_svg(
#  p, icon("CTD_beta_vectorized.svg"),
#  x = 10.85, y = 2.70, width = 0.62, height = 0.58
#)

#p <- p +
#  annotate(
#    "segment", x = 9.55, xend = 10.40, y = 2.70, yend = 2.70,
#    colour = tier_dark[3], linewidth = 1.0, linetype = "dashed",
#    arrow = arrow(type = "closed", length = unit(2.4, "mm"))
#  ) 
p <- p +
  annotate(
    "text", x = 10.00, y = 3.3,
    label = "Populations", fontface = "bold",
    size = 5.8, colour = tier_dark[3]
  )
p <- p+
  annotate(
    "text", x = 10.00, y = 1.90,
    label = "Methods:\nBioEmu\nAF2-RAVE\nMulti-Basin SBMs\n REMD", fontface = "bold",
    size = 5, colour = tier_dark[3]
  )

# ---- Stage 4: populations, transient states and experiments --
p <- add_svg(
  p, icon("TestTubeRack0001-red.svg"),
  x = 13.90, y = 5.45, width = 2.30, height = 1.55
)

# Population measurement: repeat the PDB2Vector state cartoons rather than
# introducing abstract dots from another icon style.
for (x_pos in c(12.58, 12.92, 13.26, 13.60)) {
  p <- add_svg(
    p, icon("CTD_alpha_vectorized.svg"),
    x = x_pos, y = 4.10, width = 0.25, height = 0.39
  )
}
for (x_pos in c(14.05, 14.43)) {
  p <- add_svg(
    p, icon("CTD_beta_vectorized.svg"),
    x = x_pos, y = 4.10, width = 0.34, height = 0.32
  )
}

# A magnifier over a low-population orange protein represents a
# cryptic/transient state.
theta <- seq(0, 2 * pi, length.out = 100)
magnifier <- data.frame(
  x = 14.90 + 0.38 * cos(theta),
  y = 4.10 + 0.38 * sin(theta)
)

p <- add_svg(
  p, icon("CTD_beta_vectorized.svg"),
  x = 14.90, y = 4.10, width = 0.36, height = 0.34
)

p <- p +
  geom_path(
    data = magnifier, aes(x, y),
    colour = tier_dark[4], linewidth = 1.25
  ) +
  annotate(
    "segment", x = 15.17, xend = 15.48, y = 3.80, yend = 3.52,
    colour = tier_dark[4], linewidth = 1.25, lineend = "round"
  ) 

p <- p +
  annotate(
    "text", x = 13.90, y = 3.3,
    label = "Mechanisms", fontface = "bold",
    size = 5.8, colour = tier_dark[4]
  )

p <- p+
  annotate(
    "text", x = 13.90, y = 1.90,
    label = "Methods:\nNMR\nHDX-MS\nCryo-EM\nDEER", fontface = "bold",
    size = 5, colour = tier_dark[4]
  )

# ---- Bottom Arrow -------------------------------------------

gradient_ribbon_arrow <- function(x_start = 6, x_end = 15, y = 1,
                                  col_start = "#E9C46A",
                                  col_end   = "#C1666B",
                                  n = 160,
                                  shaft_width = 12,
                                  head_length = 0.50,
                                  head_height = 0.18) {
  # Build many short segments so the shaft looks like a smooth ribbon
  xs <- seq(x_start, x_end, length.out = n + 1)
  
  segs <- data.frame(
    x    = xs[-length(xs)],
    xend = xs[-1],
    y    = y,
    yend = y,
    t    = seq(0, 1, length.out = n)
  )
  
p <- p+
    geom_segment(
      data = segs,
      aes(x = x, y = y, xend = xend, yend = yend, colour = t),
      linewidth = shaft_width,
      lineend = "round"
    ) +
    annotate(
      "polygon",
      x = c(x_end, x_end - head_length, x_end - head_length),
      y = c(y, y + head_height, y - head_height),
      fill = col_end,
      colour = col_end
    ) +
    scale_colour_gradient(
      low = col_start,
      high = col_end,
      guide = "none"
    ) +
    coord_cartesian(
      xlim = c(x_start - 1.5, x_end + 0.8),
      ylim = c(y - 0.6, y + 0.6),
      expand = FALSE
    ) +
    theme_void()
}

p <- gradient_ribbon_arrow(
  x_start = 4.5, x_end = 15.5, y = 0.6,
  col_start = "#E9C46A",
  col_end = "#C1666B"
) +
  annotate(
    "text",
    x = 2.2, y = 0.6,
    label = "CURRENT",
    colour = "#3F7D5F",
    fontface = "bold",
    size = 7
  )+
  annotate(
    "text",
    x = 10.0, y = 0.6,
    label = "FUTURE",
    colour = "WHITE",
    fontface = "bold",
    size = 7
  )


# ---- Final styling -------------------------------------------
p <- p +
  coord_cartesian(xlim = c(0.25, 15.75), ylim = c(0.65, 10.15),
                  clip = "off", expand = FALSE) +
  labs(title = "Methods for Characterizing Conformational State Spaces") +
  theme_void(base_family = "sans") +
  theme(
    plot.background = element_rect(fill = "white", colour = NA),
    plot.title = element_text(
      face = "bold", size = 22, hjust = 0.5,
      colour = "#222222", margin = margin(b = 12)
    ),
    plot.margin = margin(18, 24, 20, 24)
  )

# ---- Export --------------------------------------------------
png_file <- file.path(output_dir, "Figure3_cartoon_v6.png")
pdf_file <- file.path(output_dir, "Figure3_cartoon_v6.pdf")

ggsave(png_file, p, width = 16, height = 10.2, dpi = 300, bg = "white")
ggsave(pdf_file, p, width = 16, height = 10.2, bg = "white",
       device = grDevices::pdf)

message("Saved:\n  ", png_file, "\n  ", pdf_file)
