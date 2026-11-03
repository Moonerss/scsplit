process SPLIT_RDS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    tuple val(meta), path(input), val(split_column)

    output:
    tuple val(meta), path('rds_outputs'), path('split_manifest.tsv'), emit: split_outputs
    path 'versions.yml', emit: versions

    script:
    "split_rds.R '${input}' '${split_column}' '${meta.name}' '${meta.input_object_type}'"
}
