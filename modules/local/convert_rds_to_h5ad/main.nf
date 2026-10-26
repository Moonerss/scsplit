process CONVERT_RDS_TO_H5AD {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/96/96bb395431d12e1db60ae56a0788543a29343cea42657c79d548d015ab69e960/data'
        : 'community.wave.seqera.io/library/adata_readrds:a4ce240ec6f50fd9'}"

    input:
    tuple val(meta), path(input), path(manifest)

    output:
    tuple val(meta), path('*.h5ad'), path(manifest), emit: converted_outputs
    path 'versions.yml', emit: versions

    script:
    """
    python ${projectDir}/modules/local/convert_rds_to_h5ad/templates/convert_rds_to_h5ad.py \\
        --input ${input} \\
        --output ${input.simpleName}.h5ad
    cat > versions.yml <<'EOF'
    CONVERT_RDS_TO_H5AD:
        python: "\$(python --version 2>&1 | sed 's/^Python //')"
        anndata2ri: "\$(python -c 'import anndata2ri; print(anndata2ri.__version__)')"
    EOF
    """
}
