process CONVERT_RDS_TO_H5AD {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? "${projectDir}/containers/scsplit.sif"
        : params.container_image}"

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
