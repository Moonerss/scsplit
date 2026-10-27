process CONVERT_RDS_TO_H5AD {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    tuple val(meta), path(input), path(manifest)

    output:
    tuple val(meta), path('*.h5ad'), path('*_split_manifest.tsv'), emit: converted_outputs
    path 'versions.yml', emit: versions

    script:
    template 'convert_rds_to_h5ad.py'
}
