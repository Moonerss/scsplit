process CONVERT_ANNDATA_TO_SCE {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    tuple val(meta), path(input), path(manifest)

    output:
    tuple val(meta), path('*.rds'), path('*_split_manifest.tsv'), emit: converted_outputs
    path 'versions.yml', emit: versions

    script:
    template 'convert_anndata_to_sce.R'
}
