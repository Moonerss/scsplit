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
    def arguments = groovy.json.JsonOutput.toJson([
        manifests: manifests.collect { it.toString() },
        outputs: output_files.collect { it.toString() },
        formats: formats.collect { it.toString() },
        name: meta.name
    ])
    def encodedArguments = arguments.bytes.encodeBase64().toString()
    """
    printf '%s' '${encodedArguments}' | base64 -d > collect_arguments.json
    collect_outputs.py --arguments collect_arguments.json
    """
}
