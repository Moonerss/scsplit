#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { SCSPLIT } from './workflows/scsplit'

params.input = null
params.split_column = null
params.output_format = 'anndata'
params.outdir = 'results'


workflow {
    if (!params.split_column || params.split_column.toString().trim() in ['', 'null']) {
        error "Missing required parameter '--split_column'; specify a cell metadata column, for example '--split_column donor'"
    }

    samplesheet = Channel.fromPath(params.input, checkIfExists: true)

    SCSPLIT(
        samplesheet,
        params.split_column,
        params.output_format,
        params.outdir
    )
}
