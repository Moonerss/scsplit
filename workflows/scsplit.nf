nextflow.enable.dsl=2

include { VALIDATE_INPUT } from '../modules/local/validate_input'
include { SPLIT_H5AD } from '../modules/local/split_h5ad'
include { SPLIT_SCE_RDS } from '../modules/local/split_sce_rds'
include { CONVERT_H5AD_TO_RDS } from '../modules/local/convert_h5ad_to_rds'
include { CONVERT_RDS_TO_H5AD } from '../modules/local/convert_rds_to_h5ad'
include { COLLECT_OUTPUTS } from '../modules/local/collect_outputs'

workflow SCSPLIT {
    take:
    samplesheet
    split_column
    output_format
    outdir

    main:
    validated = VALIDATE_INPUT(samplesheet)
    rows = validated.validated_samplesheet
        .splitCsv(header: true, sep: '\t')
        .map { row ->
            def meta = [id: row.name, name: row.name, input_format: row.input_format]
            tuple(meta, file(row.input_file), split_column)
        }

    h5ad_split = SPLIT_H5AD(rows.filter { meta, input, column -> meta.input_format == 'h5ad' })
    rds_split = SPLIT_SCE_RDS(rows.filter { meta, input, column -> meta.input_format == 'rds' })

    h5ad_parts = h5ad_split.split_outputs.flatMap { meta, directory, manifest ->
        directory.listFiles().findAll { it.name.endsWith('.h5ad') }.collect { tuple(meta, it, manifest) }
    }
    rds_parts = rds_split.split_outputs.flatMap { meta, directory, manifest ->
        directory.listFiles().findAll { it.name.endsWith('.rds') }.collect { tuple(meta, it, manifest) }
    }

    if (output_format == 'h5ad' || output_format == 'both') {
        h5ad_native = h5ad_parts.map { meta, part, manifest -> tuple(meta, part, manifest, 'h5ad') }
        rds_converted = CONVERT_RDS_TO_H5AD(rds_parts)
            .converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'h5ad') }
        h5ad_outputs = h5ad_native.mix(rds_converted)
    }
    if (output_format == 'rds' || output_format == 'both') {
        rds_native = rds_parts.map { meta, part, manifest -> tuple(meta, part, manifest, 'rds') }
        h5ad_converted = CONVERT_H5AD_TO_RDS(h5ad_parts)
            .converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'rds') }
        rds_outputs = rds_native.mix(h5ad_converted)
    }

    output_parts = output_format == 'h5ad' ? h5ad_outputs : output_format == 'rds' ? rds_outputs : h5ad_outputs.mix(rds_outputs)
    grouped_outputs = output_parts.map { meta, part, manifest, format -> tuple(meta.name, meta, part, manifest, format) }
        .groupTuple(by: 0)
        .map { name, metas, parts, manifests, formats -> tuple(metas[0], parts, manifests.unique(), formats) }
    COLLECT_OUTPUTS(grouped_outputs, outdir)
}
