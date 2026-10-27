#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { SCSPLIT } from './workflows/scsplit'

params.input = null
params.split_column = null
params.output_format = 'h5ad'
params.outdir = 'results'


workflow {
    samplesheet = Channel.fromPath(params.input, checkIfExists: true)

    SCSPLIT(
        samplesheet,
        params.split_column,
        params.output_format,
        params.outdir
    )
}
