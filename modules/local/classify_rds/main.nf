process CLASSIFY_RDS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    tuple val(meta), path(input), val(split_column)
    output:
    tuple val(meta), path(input), path('classified_metadata.tsv'), emit: classified

    script:
    template 'classify_rds.R'
}
