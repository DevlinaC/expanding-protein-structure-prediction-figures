# R package requirements for the figure-generation scripts.
#
# Install from the repository root with:
#   Rscript requirements.R
#
# `grid` is part of base R and does not need to be installed separately.

required_packages <- c(
  "ggplot2",  # Figure 3
  "magick",   # Figures 1, 3, and 4
  "ragg",     # Figure 4 raster output
  "rsvg"      # Figure 3 SVG rendering
)

optional_packages <- c(
  "svglite"   # Optional SVG export for Figure 1
)

missing_required <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_required) > 0) {
  install.packages(missing_required, repos = "https://cloud.r-project.org")
}

missing_optional <- optional_packages[
  !vapply(optional_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_optional) > 0) {
  message(
    "Optional packages not installed: ",
    paste(missing_optional, collapse = ", "),
    ". Figure 1 SVG export may be unavailable."
  )
}

message("Required R packages are available.")
