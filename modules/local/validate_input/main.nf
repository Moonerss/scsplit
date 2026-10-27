process VALIDATE_INPUT {
    tag "$samplesheet.baseName"
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? "${projectDir}/containers/scsplit.sif"
        : params.container_image}"

    input:
    path samplesheet

    output:
    path 'validated_samplesheet.tsv', emit: validated_samplesheet
    path 'versions.yml', emit: versions

    script:
    """
    python ${projectDir}/modules/local/validate_input/templates/validate_input.py \\
        --input ${samplesheet} \\
        --output validated_samplesheet.tsv
    cat > versions.yml <<'EOF'
    VALIDATE_INPUT:
        python: \"\$(python --version 2>&1 | sed 's/^Python //')\"
    EOF
    """
}
