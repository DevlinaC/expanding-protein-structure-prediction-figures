# Figure 4 revision guidance

## Purpose

Figure 4 should present a proposed iterative research framework for conformational state-space inference. It should not look like a validated six-step causal pipeline in which each component necessarily produces the next.

The figure should emphasize that progress requires continued interaction among:

- training and reference data;
- landscape-aware benchmarks;
- ensemble prediction objectives;
- physics-based estimation;
- context and perturbation modeling;
- orthogonal experimental constraints and tests.

Landscape inference and uncertainty should remain at the center.

## Primary structural changes

### Remove the numbered pipeline

Remove the numbered circles `1` through `6`. The numbering implies a required order and makes the framework appear more established than it is.

Replace the one-way circular sequence with one of the following:

1. bidirectional arrows between adjacent components; or
2. spokes connecting each component to the central inference target, with a smaller number of meaningful feedback arrows among components.

The second option is preferred because it emphasizes that every component informs the central inference problem.

Retain directed arrows only where direction carries a specific meaning, such as:

- context-conditioned predictions to experimental testing;
- experimental observations to training and reference data;
- benchmark results to model development.

## Recommended title and subtitle

Title:

> Proposed framework for conformational state-space inference

Subtitle:

> An iterative research program integrating data, prediction, physics, perturbation, and experiment

The word `proposed` is important because the diagram represents a research program rather than an established workflow.

## Revise the central target

Replace or expand the central label so that uncertainty is explicit:

> STATE-SPACE INFERENCE

The central target should list:

- structural support or accessible states;
- equilibrium populations;
- transitions and rates;
- context dependence;
- uncertainty.

Optional mathematical notation can connect the figure directly to the revised text:

- equilibrium distribution: `p_eq(X | S,C)`;
- kinetic object: `K_ij(S,C)`.

If included, keep this notation secondary and visually smaller than the conceptual labels.

## Recommended node labels

| Current node | Recommended replacement |
|---|---|
| Training Data | Training and reference data |
| Landscape Benchmarks | Landscape-aware benchmarks |
| Prediction Objective | Ensemble prediction objectives |
| Physics-Based Modeling | Physics-based estimation |
| Perturbation Modeling | Context and perturbation modeling |
| Experimental Feedback | Orthogonal experimental constraints |

### Training and reference data

Suggested sublabel:

> Multi-state structures, trajectories, observables, and conditions

This is broader and more accurate than `Multi-state structures + context`.

### Landscape-aware benchmarks

Replace `Basin recovery + populations` with the four benchmark tracks proposed in the manuscript:

- state recovery;
- populations;
- perturbation response;
- kinetics.

If all four do not fit in the node, use:

> States, populations, perturbations, and kinetics

### Ensemble prediction objectives

Suggested sublabel:

> Distributions, dynamics, and calibrated uncertainty

Avoid implying that an ensemble of generated structures is automatically thermodynamic.

### Physics-based estimation

Suggested sublabel:

> Energetic organization and rates under model and sampling assumptions

The `Delta G` and `Delta G double dagger` imagery can remain, but the node or caption should state that population and kinetic estimates depend on force fields, sampling, and dynamical assumptions.

### Context and perturbation modeling

Suggested sublabel:

> Mutations, ligands, environment, and assembly conditions

This incorporates the revised treatment of biological context, oligomeric state, stoichiometry, and concentration without adding a separate node.

### Orthogonal experimental constraints

Replace `Validation + mechanism` with:

> Matched-condition observables and independent tests

Experiments constrain and test distributions but do not automatically provide complete states, populations, or mechanisms.

## Revise the connecting labels

| Current label | Recommended replacement |
|---|---|
| measured states + populations | structures, observables, conditions + uncertainty |
| state/context cases | held-out systems and conditions |
| recovery metrics | benchmark results and failure modes |
| ensemble targets | distributional and dynamical targets |
| energy/rate constraints | energetic and kinetic estimates |
| testable predictions | testable perturbation predictions |

Use compact versions if space is limited.

## Remove or simplify the bottom contribution strip

The bottom strip repeats the information already presented in the six nodes and makes the figure unusually tall. Preferred options are:

1. remove it and place the explanation in the caption; or
2. replace it with a compact legend describing arrow types or uncertainty notation.

If retained, revise its headings so that they do not imply one unique output per component. In particular, replace `Empirical populations + mechanisms` with `Experimental observables + independent tests`.

## Visual treatment of uncertainty

Uncertainty should be visible rather than appearing only as a word in the prediction-objective node. Possible treatments include:

- translucent probability halos around the central states;
- error bars or distribution widths next to population labels;
- a central label reading `Inference + uncertainty`;
- dashed edges for uncertain or condition-dependent transitions;
- a small legend distinguishing predicted, experimentally constrained, and unresolved relationships.

Use only one or two of these devices to avoid clutter.

## Preferred relationship structure

The most defensible relationship diagram is:

- all six outer components connect bidirectionally to the central inference target;
- benchmarks exchange information with data and prediction objectives;
- prediction objectives exchange information with physics-based estimation;
- physics-based estimation exchanges information with perturbation modeling;
- perturbation modeling produces testable predictions for experiments;
- experimental constraints feed back to data, benchmarks, and state-space inference.

This preserves the useful circular organization without asserting that the components must operate in a fixed order.

## Minimal-change design

If major restructuring of the R script is undesirable:

1. remove the numbers `1` through `6`;
2. change all outer arrows to bidirectional arrows;
3. update the title to include `Proposed framework`;
4. change the central title to `State-space inference + uncertainty`;
5. update the six node labels and sublabels;
6. replace `measured states + populations` with `observables + conditions`;
7. replace `Validation + mechanism` with `Independent constraints and tests`;
8. update the benchmark node to include states, populations, perturbations, and kinetics;
9. remove or shorten the bottom contribution strip;
10. revise the caption to state that this is an iterative research program rather than a validated pipeline.

## Draft caption

> **Figure 4 | Proposed framework for conformational state-space inference.** The central prediction target comprises structural support, equilibrium populations under specified conditions, transition pathways and rates, context dependence, and associated uncertainty. Progress toward this target requires iterative interaction among multi-state training and reference data, landscape-aware benchmarks, distributional and dynamical prediction objectives, physics-based estimation, context and perturbation modeling, and orthogonal experimental constraints. Arrows indicate information exchange and feedback rather than a required sequence of operations. Prediction models propose candidate states and distributions; physics-based approaches estimate their energetic and kinetic organization under model and sampling assumptions; perturbation models generate condition-specific, testable predictions; and experiments constrain and independently test the resulting distributions. The framework is a proposed research program rather than a validated pipeline, and no individual component determines the complete conformational landscape.

## R-script implementation checklist

- [ ] Remove numbered step markers.
- [ ] Change the title and subtitle.
- [ ] Add uncertainty to the central target.
- [ ] Update the central state-space labels.
- [ ] Rename and revise all six outer nodes.
- [ ] Add all four benchmark tracks.
- [ ] Replace one-way causal arrows with bidirectional or center-directed relationships.
- [ ] Retain directional arrows only for meaningful experimental or model-development feedback.
- [ ] Update all connecting labels.
- [ ] Remove or simplify the bottom contribution strip.
- [ ] Ensure that physics-based populations and rates are described as assumption dependent.
- [ ] Ensure that experiments are described as constraints and tests, not automatic validation.
- [ ] Re-export PDF, PNG, TIFF, and SVG versions.
- [ ] Confirm that the manuscript figure and repository-generated figure are identical.

## Relevant source

Current R source:

`../ExpandingProteinStructurePrediction_figs/Figure4/scripts/roadmap_figure4.R`

