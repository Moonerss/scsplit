# Repository Guidelines

## Project Overview

`scsplit` is a Nextflow DSL2 pipeline that splits H5AD/AnnData or SingleCellExperiment RDS inputs by one cell-metadata column. It accepts a CSV samplesheet and writes per-dataset H5AD, RDS, or both formats with a split manifest.

## Architecture & Data Flow

`main.nf` passes `input`, `split_column`, `output_format`, and `outdir` to `SCSPLIT` in `workflows/scsplit.nf`. The workflow validates the samplesheet, creates dataset metadata tuples, and dispatches inputs to native H5AD or SCE-RDS split processes. Split outputs are expanded per group; conversion processes run only for requested cross-format outputs. Results are grouped by dataset and passed to `COLLECT_OUTPUTS`, which organizes format-specific directories and the final manifest.

Each local process declares typed Nextflow inputs and named outputs in `main.nf`; implementation scripts live under that module's `templates/`. Keep channel contracts and metadata (`id`, `name`, `input_format`) consistent when changing module interfaces. Splitting rejects empty objects, absent split columns, and missing values. Preserve original group values in manifests; sanitize only filenames.

## Key Directories

- `workflows/`: top-level pipeline orchestration and channel transformations.
- `modules/local/`: validation, split, conversion, and result collection processes; `templates/` contains the Python/R work scripts.
- `containers/`: shared all-module runtime dependencies, Dockerfile, and Singularity/Apptainer definition; module-specific environments remain for the Conda profile.
- `assets/`: schema assets.
- `tests/test_data/`: reserved for small fixtures; currently empty.
- `DESIGN.md`: intended product/design scope; some proposed directories and interfaces are not implemented. Follow the live workflow and process contracts for current behavior.

## Development Commands

Run the documented example from the repository root:

```bash
nextflow run . -profile conda --input samplesheet.csv --split_column donor --output_format h5ad --outdir results
```

`--output_format` is `h5ad` by default and also accepts `rds` or `both`. The samplesheet CSV must have exactly `name,input` columns. Select one declared environment with `-profile conda`, `-profile docker`, or `-profile singularity`. The repository does not currently define or document build or lint commands. `DESIGN.md` proposes `nf-test test`, `nf-core lint`, and `pre-commit run --all-files`, but these are not wired to existing test/config files.

## Code Conventions & Common Patterns

- Each module declares its Conda environment and runtime image in `modules/local/<module>/main.nf`; module Conda dependencies live in `environment.yml`. `containers/environment.yml` is the single dependency source for the unified Docker/Singularity runtime. `conf/modules.config` contains resource overrides.
- Select one runtime profile: `-profile conda`, `-profile docker`, `-profile singularity`, or `-profile apptainer`. Container profiles use `params.container_image`, defaulting to `scsplit:0.1.0`; Singularity/Apptainer use `containers/scsplit.sif`.

## Important Files

- `main.nf`: pipeline entry point and parameter defaults.
- `nextflow.config`: manifest, Nextflow/plugin requirement, schema plugin, and defaults.
- `nextflow_schema.json`: CLI parameter constraints.
- `workflows/scsplit.nf`: input routing, format branching, and aggregation.
- `modules/local/validate_input/`: samplesheet validation and normalized TSV generation.
- `modules/local/split_h5ad/`, `split_sce_rds/`: native split logic and split manifests.
- `modules/local/convert_h5ad_to_rds/`, `convert_rds_to_h5ad/`: cross-format conversion.
- `modules/local/collect_outputs/`: dataset output layout and final manifest.
- `containers/environment.yml`, `containers/Dockerfile`, `containers/scsplit.def`: unified runtime dependency list and container builds.
- `conf/base.config`, `conf/modules.config`: process defaults and resource overrides.
- `README.md`, `DESIGN.md`: usage and design reference.

## Runtime/Tooling Preferences

The pipeline runtime is Nextflow; the configuration requires Bash. Python modules use Python 3.11 and the unified container uses R 4.5; module Conda environments declare their own package versions. Build Docker with `docker build -f containers/Dockerfile -t scsplit:0.1.0 .`, or build Singularity/Apptainer from the repository root with `apptainer build containers/scsplit.sif containers/scsplit.def`. Container engines must be installed on the execution host. The repository has no Python/R package manager manifest or lockfile, and no Node/Bun tooling.

## Testing & QA

There are currently no test files, snapshots, test harness configuration, or test datasets under `tests/`; do not treat proposed tests in `DESIGN.md` as implemented coverage. When adding tests, follow the design's nf-test direction and use small fixtures under `tests/test_data/`. Assert observable behavior: output object type and cell count, group membership, manifest mapping, format conversion, and dataset directory naming. Do not claim verification unless the relevant workflow or test was run.
