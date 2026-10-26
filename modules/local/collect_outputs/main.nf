process COLLECT_OUTPUTS {
    tag "$meta.name"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'docker://docker.io/library/python:3.11-slim'
        : 'docker.io/library/python:3.11-slim'}"

    input:
    tuple val(meta), path(output_files), path(manifests), val(formats)
    val outdir

    output:
    path "${meta.name}", emit: collected

    script:
    def copy_commands = output_files.withIndex().collect { file, index ->
        "mkdir -p '${meta.name}/${formats[index]}' && cp '${file}' '${meta.name}/${formats[index]}/'"
    }.join('\n')
    def manifest_args = manifests.collect { "'${it}'" }.join(' ')
    def output_args = output_files.collect { "'${it}'" }.join(' ')
    def format_args = formats.collect { "'${it}'" }.join(' ')
    """
    mkdir -p '${meta.name}'
    ${copy_commands}
    python ${projectDir}/modules/local/collect_outputs/templates/collect_outputs.py \\
        --manifests ${manifest_args} \\
        --outputs ${output_args} \\
        --formats ${format_args} \\
        --name '${meta.name}' \\
        --output '${meta.name}/split_manifest.tsv'
    """
}
