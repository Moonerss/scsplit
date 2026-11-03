# Repository Guidelines

## Project

`scsplit` is a Nextflow DSL2 pipeline that splits H5AD/AnnData, SingleCellExperiment RDS, or Seurat RDS objects by one cell-metadata column. Each run emits one selected format (`anndata`, `sce`, or `seurat`) and a per-dataset split manifest.

## Architecture

`main.nf` passes `input`, `split_column`, `output_format`, and `outdir` to `SCSPLIT` in `workflows/scsplit.nf`. The workflow rejects a missing or empty `split_column`, validates the samplesheet, creates metadata tuples, splits H5AD/RDS inputs natively, detects RDS object type, converts only when needed, and publishes grouped results through `COLLECT_OUTPUTS`.

Keep process contracts and metadata (`id`, `name`, `input_format`, `input_object_type`) stable. Empty objects, absent metadata columns, and missing group values fail. Manifests preserve original group values; filenames are sanitized.

Runtime scripts are executable files in repository-level `bin/`. Processes call them by name and pass values through command-line arguments. Do not add module-local `templates/` scripts or template interpolation.

## Repository Layout

- `main.nf`: entry point and parameter defaults.
- `workflows/`: orchestration and channel transformations.
- `modules/local/`: process definitions, inputs, outputs, and environments.
- `bin/`: executable Python/R process scripts with portable shebangs.
- `containers/`: unified dependencies and Docker/Singularity definitions.
- `conf/`: process resources and defaults.
- `assets/`: schema assets.
- `tests/test_data/`: deterministic H5AD, SCE, Seurat, and samplesheet fixtures.
- `README.md`: user instructions.
- `DESIGN.md`: behavioral and interface design.

## Run

`--input` and `--split_column` are required. The samplesheet must contain exactly `name,input` columns. `--output_format` defaults to `anndata` and accepts `anndata`, `sce`, or `seurat`.

```bash
cd /mnt/d/code/Github/nextflow/scsplit
nextflow run . -profile singularity \
    --input tests/test_data/samplesheet_all.csv \
    --split_column donor \
    --output_format anndata \
    --outdir results/test_data
```

Use one profile per run: `conda`, `docker`, `singularity`, or `apptainer`. Docker and Singularity/Apptainer use `params.container_image`; the latter profiles point to `containers/scsplit.sif`.

## Development Rules

- Keep channel contracts and named outputs stable.
- Keep dependencies in module `environment.yml` files and `containers/environment.yml` for the unified image.
- Keep scripts in `bin/`, executable, independently callable, and argument-driven.
- Avoid unrelated refactors and new abstractions.
- Update README or DESIGN when user-visible behavior or process contracts change.

## Verification

```bash
python3 -m py_compile bin/*.py
nextflow lint .
```

The repository currently has no nf-test files, snapshots, test harness, or pre-commit configuration. New tests should assert object type, cell and feature counts, group membership, manifest mapping, conversion behavior, and dataset directory naming. Report only commands that were actually run.
