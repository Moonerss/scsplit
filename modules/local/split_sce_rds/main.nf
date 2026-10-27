process SPLIT_SCE_RDS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    tuple val(meta), path(input), val(split_column)

    output:
    tuple val(meta), path('rds_outputs'), path('split_manifest.tsv'), emit: split_outputs
    path 'versions.yml', emit: versions

    script:
    template 'split_sce_rds.R'
}
