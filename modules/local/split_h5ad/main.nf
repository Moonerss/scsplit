process SPLIT_H5AD {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? "${projectDir}/containers/scsplit.sif"
        : params.container_image}"

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
