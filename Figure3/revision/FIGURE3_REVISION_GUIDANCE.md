# Figure 3 revision guidance

## Purpose

Figure 3 should summarize the complementary information provided by current approaches to conformational state-space characterization. It should not imply that the four method classes form a mandatory linear pipeline or that experiments automatically provide a complete representation of the landscape.

The revised manuscript distinguishes four inferential contributions:

1. representative coordinates;
2. candidate structural states;
3. model-dependent energetic weights and rates;
4. experimental constraints and independent tests.

No individual component provides ground truth on its own.

## Primary changes

### Remove unsupported numerical populations

Delete the hard-coded `40%` and `60%` labels. Replace them with either:

- `pA` and `pB`, preferably rendered as `p_A` and `p_B`; or
- the phrase `Relative weights` with the qualifier `(condition dependent)`.

The figure or caption should make clear that these are illustrative weights rather than measured or inferred values.

### Remove the hierarchy

Remove the following elements:

- the `PARTIAL REPRESENTATION` to `MORE COMPLETE REPRESENTATION` hierarchy;
- the `CURRENT` to `FUTURE` axis;
- arrows that make the four columns look like a necessary sequential pipeline.

Alternative-state prediction, physics-based estimation, and ensemble-sensitive experiments are already current approaches. Experiments provide complementary projections and constraints rather than an automatically more complete representation.

### Revise the four panels

| Current panel or label | Recommended replacement |
|---|---|
| Single structure prediction | Representative structure prediction |
| Coordinates | One candidate basin |
| Alternative state sampling | Candidate-state generation |
| Accessible states | Candidate states |
| Energetic refinement | Physics-based estimation |
| Populations | Model-dependent weights and rates |
| Experiments | Experimental constraints and tests |
| Validated mechanisms | Experimentally constrained interpretation |

`Candidate states` is preferable to `Accessible states` because generation of a conformation does not establish thermodynamic accessibility.

`Physics-based estimation` is preferable to `Energetic refinement` because this panel includes methods that estimate energetic organization, populations, and sometimes kinetics rather than simply refining structures.

`Experimental constraints and tests` is preferable to `Experiments` or `Validated mechanisms` because experiments measure incomplete and often ensemble-averaged projections. They constrain and test interpretations but do not uniquely validate an ensemble or mechanism.

## Recommended limitation line for each panel

Add one compact limitation beneath the principal output in each panel:

1. Representative structure prediction:
   - `Confidence does not imply occupancy`
2. Candidate-state generation:
   - `Sampling does not establish accessibility`
3. Physics-based estimation:
   - `Force-field and sampling dependent`
4. Experimental constraints and tests:
   - `Averaged and potentially non-unique`

These lines can replace part of the long method lists if space is limited.

## Method-list simplification

Table 1 now lists the principal experimental approaches and their limitations. Figure 3 therefore does not need to repeat a comprehensive list of experimental methods.

Recommended options:

- show no named methods in the panels and move examples to the caption; or
- retain only two or three representative examples per panel.

If representative examples are retained, use consistent formatting:

- Representative structure prediction: `AlphaFold 2/3`, `RoseTTAFold`, `ESMFold`
- Candidate-state generation: `MSA perturbation`, `AF-Cluster`, `Cfold`
- Physics-based estimation: `MD and enhanced sampling`, `AF2-RAVE`, `BioEmu`
- Experimental constraints and tests: `NMR`, `smFRET/DEER`, `HDX-MS`, `SAXS`, `cryo-EM`

Avoid citation numbers embedded in method names inside the figure. Put the supporting citations in the caption.

## Recommended title

Preferred:

> Complementary views of protein conformational state space

Acceptable minimal-change alternative:

> Methods for characterizing protein conformational state spaces

## Recommended visual organization

### Preferred design

Retain the four-column layout but present all four columns as parallel, complementary views. Use equal-height panels without a top completeness gradient or bottom temporal axis. A shared line beneath the panels can read:

> Joint interpretation is required for landscape inference

The panels may retain their existing colors, but color should distinguish method classes rather than encode increasing completeness.

### Minimal-change design

If the R script is difficult to restructure:

1. remove the `40%` and `60%` labels;
2. replace them with `p_A` and `p_B`;
3. rename `Energetic refinement` to `Physics-based estimation`;
4. rename `Accessible states` to `Candidate states`;
5. rename `Experiments` to `Experimental constraints and tests`;
6. replace `Validated mechanisms` with `Experimentally constrained interpretation`;
7. remove the `CURRENT` to `FUTURE` bar;
8. replace the top hierarchy with `COMPLEMENTARY INFORMATION`;
9. soften or remove the arrows between panels;
10. add the four limitation lines.

## Draft caption

> **Figure 3 | Complementary approaches to characterizing protein conformational state space.** Representative structure predictors identify a high-confidence coordinate model that may correspond to one candidate basin but do not determine its equilibrium occupancy. Candidate-state generation methods sample alternative structural hypotheses, although sampling a conformation does not establish its thermodynamic accessibility or population. Physics-based and hybrid approaches estimate energetic organization, relative weights, and, when supported by an appropriate dynamical model, transition rates; these estimates remain dependent on force fields, initial conditions, sampling, and convergence. Ensemble-sensitive experiments provide averaged or sparse observables that constrain and independently test computationally proposed distributions, but their interpretation may be non-unique. The approaches therefore provide complementary information and must be integrated to infer state identities, populations, dynamics, and biological context.

## R-script implementation checklist

- [ ] Remove the hard-coded `40%` and `60%` strings.
- [ ] Add `p_A` and `p_B` or a qualitative relative-weight label.
- [ ] Remove or replace the top partial-to-complete hierarchy.
- [ ] Remove the current-to-future bar.
- [ ] Remove or soften sequential arrows.
- [ ] Update the four panel headings and outputs.
- [ ] Add one short limitation to each panel.
- [ ] Shorten or remove method lists that duplicate Table 1.
- [ ] Ensure `cryo-EM`, `AlphaFold`, and other method names use consistent capitalization.
- [ ] Re-export PDF, PNG, TIFF, and any vector version used by the manuscript.
- [ ] Confirm that the manuscript figure and repository-generated figure are identical.

## Relevant source

Current R source:

`../ExpandingProteinStructurePrediction_figs/Figure3/scripts/practical_guidelines_cartoon.R`

