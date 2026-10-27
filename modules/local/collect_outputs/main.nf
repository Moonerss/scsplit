process COLLECT_OUTPUTS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"
    publishDir path: { outdir }, mode: 'copy', enabled: true

    input:
    tuple val(meta), path(output_files), path(manifests), val(formats)
    val outdir

    output:
    path "${meta.name}", emit: collected

    script:
    manifest_args = groovy.json.JsonOutput.toJson(manifests.collect { it.toString() })
    output_args = groovy.json.JsonOutput.toJson(output_files.collect { it.toString() })
    format_args = groovy.json.JsonOutput.toJson(formats.collect { it.toString() })
    template 'collect_outputs.py'
}
