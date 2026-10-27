process CONVERT_H5AD_TO_RDS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? "${projectDir}/containers/scsplit.sif"
        : params.container_image}"

    input:
    tuple val(meta), path(input), path(manifest)

    output:
    tuple val(meta), path('*.rds'), path(manifest), emit: converted_outputs
    path 'versions.yml', emit: versions

    script:
    """
    Rscript ${projectDir}/modules/local/convert_h5ad_to_rds/templates/convert_h5ad_to_rds.R \\
        --input ${input} \\
        --output ${input.simpleName}.rds
    cat > versions.yml <<'EOF'
    CONVERT_H5AD_TO_RDS:
        r: "\$(R --version | head -n 1 | sed 's/^R version //')"
        anndataR: "\$(Rscript -e 'cat(as.character(packageVersion(\"anndataR\")))')"
    EOF
    """
}
