process SPLIT_H5AD {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/de/de2455bdcbc53723a8d942ffb0dec7559690ef4bea6b380fea2edba7c5d637b9/data'
        : 'community.wave.seqera.io/library/anndata_python_pyyaml:e77bb4f393d60a08'}"

    input:
    tuple val(meta), path(input), val(split_column)

    output:
    tuple val(meta), path('h5ad_outputs'), path('split_manifest.tsv'), emit: split_outputs
    path 'versions.yml', emit: versions

    script:
    """
    python ${projectDir}/modules/local/split_h5ad/templates/split_h5ad.py \\
        --input ${input} \\
        --split-column '${split_column}' \\
        --name '${meta.name}' \\
        --output-dir h5ad_outputs \\
        --manifest split_manifest.tsv
    cat > versions.yml <<'EOF'
    SPLIT_H5AD:
        python: \"\$(python --version 2>&1 | sed 's/^Python //')\"
        anndata: \"\$(python -c 'import anndata; print(anndata.__version__)')\"
    EOF
    """
}
