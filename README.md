# Expanding Protein Structure Prediction — Figure Files

This repository contains the source files, scripts, editable assets, and rendered outputs for the figures accompanying the *Expanding Protein Structure Prediction* project.

The repository is organized by figure so that each figure can be edited and regenerated independently.

## Repository layout

```text
Figure1/
├── R_scripts/       R script for the state-space paradigm figure
├── structures/      Protein and context-icon assets
└── figure_files/    Rendered Figure 1 outputs

Figure2/
└── pymol_sessions/  PyMOL sessions used to prepare structure panels

Figure3/
├── scripts/         R script for the practical-guidelines cartoon
├── icons_candidates/ Editable icon assets
└── figure_versions/ Rendered Figure 3 versions

Figure4/
├── scripts/         R script for the state-space roadmap
├── parts_fig4/      Editable component and icon assets
└── output/          Rendered Figure 4 outputs
```

## Reproducing the figures

Run each script from its figure directory or from the script's own directory. The scripts resolve their input and output paths relative to the script location where possible, so changing the working directory should not be necessary.

Install the required R packages from the repository root with:

```bash
Rscript requirements.R
```

The optional `svglite` package enables SVG export for Figure 1. Figure 4 SVG conversion also requires the external `pdftocairo` command from Poppler.

### Figure 1

```bash
cd Figure1/R_scripts
Rscript creating_Figure1_state_space_paradigm.R
```

This produces PNG, PDF, and—when `svglite` is available—SVG output in `Figure1/figure_files/`.

Required R packages include `magick`; `svglite` is optional and is needed for SVG export.

### Figure 3

```bash
cd Figure3/scripts
Rscript practical_guidelines_cartoon.R
```

This regenerates the Figure 3 versions in `Figure3/figure_versions/`.

Required R packages include `ggplot2`, `grid`, `magick`, and `rsvg`.

### Figure 4

```bash
cd Figure4/scripts
Rscript roadmap_figure4.R
```

This regenerates the PDF, PNG, and TIFF outputs in `Figure4/output/`. SVG output is also produced when `pdftocairo` is available.

Required R packages include `magick` and `ragg`. `grid` is included with R, and `pdftocairo` is optional for SVG conversion.

### Figure 2

Figure 2 currently contains PyMOL session files. Open the relevant `.pse` file in PyMOL to inspect or edit the structure visualization.

## Development disclosure

The initial figure scripts and source assets in this repository were prepared by the project authors. OpenAI Codex was subsequently used as a development assistant for code review, path handling, refactoring, documentation, repository organization, and validation. All AI-assisted changes were reviewed and accepted by the project maintainer, who remains responsible for the published code, figures, and documentation.

## Editing notes

- Keep source assets and scripts in their corresponding figure directory.
- Treat rendered files as outputs of the scripts when a script is available.
- Large structure files are intentionally excluded from version control; obtain or store them separately as needed.

## Citation

If you use these figure files, please cite the associated manuscript:

> Chakravarty, D., Miller, J. J., Teng, D., Ramahi, Y. O., Bryant, P., Neira-Mahuzier, C., Ramírez-Sarmiento, C. A., Rauscher, S., Bowman, G. R., Tiwary, P., and Porter, L. L. *Expanding Protein Structure Prediction into Conformational State Space*. Manuscript version dated 31 July 2026.

### Authors and affiliations

1. Devlina Chakravarty — Division of Intramural Research, National Library of Medicine, National Institutes of Health
2. Justin J. Miller — Department of Biochemistry and Biophysics, University of Pennsylvania
3. Da Teng — Institute for Health Computing, University of Maryland
4. Yousuf O. Ramahi — Department of Chemical and Physical Sciences and Department of Chemistry, University of Toronto Mississauga and University of Toronto
5. Patrick Bryant — Department of Molecular Biosciences, Stockholm University
6. Camila Neira-Mahuzier — Institute for Biological and Medical Engineering, Pontificia Universidad Católica de Chile; ANID Millennium Science Initiative Program, Millennium Institute for Integrative Biology (iBio)
7. César A. Ramírez-Sarmiento — Institute for Biological and Medical Engineering, Pontificia Universidad Católica de Chile; ANID Millennium Science Initiative Program, Millennium Institute for Integrative Biology (iBio)
8. Sarah Rauscher — Department of Chemical and Physical Sciences and Department of Physics, University of Toronto Mississauga and University of Toronto
9. Gregory R. Bowman — Department of Biochemistry and Biophysics, University of Pennsylvania
10. Pratyush Tiwary — Department of Chemistry and Biochemistry and Institute for Physical Science and Technology, University of Maryland, College Park
11. Lauren L. Porter — Division of Intramural Research, National Library of Medicine, and National Heart, Lung, and Blood Institute, National Institutes of Health

Lauren L. Porter is the corresponding author: `porterll@nih.gov`.

## Figure asset attribution

### NIH BioArt Source

Several biomedical illustrations in this repository were downloaded from [NIAID NIH BioArt Source](https://bioart.niaid.nih.gov/). The embedded asset metadata identifies these files as public-domain illustrations by Ryan Kissinger, with credit to NIAID. A suitable collection-level credit is:

> Illustrations by Ryan Kissinger, courtesy of NIAID, from [NIAID NIH BioArt Source](https://bioart.niaid.nih.gov/).

NIH BioArt Source recommends citing individual entries when their entry identifiers are available. The source's recommended format and licensing guidance are described in its [FAQ](https://bioart.niaid.nih.gov/faqs). Please retain the creator, credit, license, and entry URL for each BioArt asset if the files are replaced or additional assets are added.

### Bioicons

[Bioicons](https://bioicons.com/) provides free science illustrations under permissive open-source licenses, primarily **CC0 (Creative Commons Zero / Public Domain), CC BY (Creative Commons Attribution), and the MIT License**. Some line-art icons in this repository were obtained through Bioicons. Bioicons asks users to cite the individual icon and its original license; the platform credit alone is not a substitute for source-specific attribution.

The project-level citation is:

> [Bioicons](https://bioicons.com/), a library of free open-source icons for scientific illustrations. Source repository: [duerrsimon/bioicons](https://github.com/duerrsimon/bioicons).

For the simple line icons derived from the Phosphor icon set, also credit [Phosphor Icons](https://phosphoricons.com/) and retain the [MIT license](https://github.com/phosphor-icons/core/blob/main/LICENSE) with any redistributed source assets.

### Protein structure cartoons

Protein structure illustrations were generated using the [PDB2Vector tool](https://bioicons.com/pdb2vector/), developed by Simon Dür. Suggested citation:

> Protein structure illustrations were generated using the PDB2Vector tool (https://bioicons.com/pdb2vector/), developed by Simon Dür.

## License

The original scripts and general-purpose code in this repository are released under the [MIT License](LICENSE).

The MIT License does not automatically apply to figure compositions, source images, icons, protein structure files, or other third-party assets. Those materials remain subject to the asset-specific terms and attribution requirements described above.

NIH BioArt Source assets are governed by the [NIH BioArt Source Terms and Conditions](https://bioart.niaid.nih.gov/terms). NIH BioArt Source states that its illustrations may be used for educational, research, informational, and commercial purposes, subject to the license and attribution requirements associated with each individual entry. Third-party Bioicons, Phosphor, and other assets remain subject to their own licenses and attribution requirements.
