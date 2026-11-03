process VALIDATE_INPUT {
    tag "$samplesheet.baseName"
    conda "${moduleDir}/environment.yml"
    container "${params.container_image}"

    input:
    path samplesheet

    output:
    path 'validated_samplesheet.tsv', emit: validated_samplesheet
    path 'versions.yml', emit: versions

    script:
    "validate_input.py --input '${samplesheet}' --output validated_samplesheet.tsv"
}
