# Selected alpha-synuclein conformers for Figure 1C

Source ensemble: PED00024, ensemble e001  
Source file: `PED00024e001.pdb`  
Total models: 576  
Selection variable: global radius of gyration from `PED00024e001_gyration_global.csv`

All model weights in `PED00024e001_weights.tsv` are effectively uniform, so no weight adjustment was required.

## Selected models

| Intended state | Percentile | PED model | Radius of gyration | Extracted file |
|---|---:|---:|---:|---|
| Compact | 20th | 513 | 24.911 Å | `alpha_syn_compact_model513.pdb` |
| Intermediate | 50th | 417 | 29.897 Å | `alpha_syn_intermediate_model417.pdb` |
| Extended | 80th | 349 | 36.772 Å | `alpha_syn_extended_model349.pdb` |

The absolute minimum and maximum radius-of-gyration conformers were not used because they may be visual or physical outliers.

## PDB2Vector workflow

Upload each extracted PDB separately. Use the same rendering settings for all three:

- backbone trace or thin tube representation;
- transparent background;
- no molecular surface;
- identical stroke width;
- minimal coloring rather than a sequence rainbow;
- generous but consistent cropping around each chain.

For a superimposed ensemble glyph, export each conformer using the same canvas dimensions. Exact structural alignment is not essential for an IDP, but the chain centroids and overall visual scale should be consistent.

Suggested Figure 1C colors:

- compact: blue, matching the dominant basin;
- intermediate: orange, matching the intermediate basin;
- extended: purple, matching the shallow basin.

Alternatively, render all three in the same neutral gray and apply the basin colors during figure assembly. This avoids implying that each conformation is uniquely assigned to a specific basin.

