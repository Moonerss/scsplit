process SPLIT_SCE_RDS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/96/96bb395431d12e1db60ae56a0788543a29343cea42657c79d548d015ab69e960/data'
        : 'community.wave.seqera.io/library/adata_readrds:a4ce240ec6f50fd9'}"

    input:
    tuple val(meta), path(input), val(split_column)

    output:
    tuple val(meta), path('rds_outputs'), path('split_manifest.tsv'), emit: split_outputs
    path 'versions.yml', emit: versions

    script:
    """
    Rscript ${projectDir}/modules/local/split_sce_rds/templates/split_sce_rds.R \\
        --input ${input} \\
        --split-column '${split_column}' \\
        --name '${meta.name}' \\
        --output-dir rds_outputs \\
        --manifest split_manifest.tsv
    cat > versions.yml <<'EOF'
    SPLIT_SCE_RDS:
        r: \"\$(R --version | head -n 1 | sed 's/^R version //')\"
        SingleCellExperiment: \"\$(Rscript -e 'cat(as.character(packageVersion(\"SingleCellExperiment\")))')\"
    EOF
    """
}
