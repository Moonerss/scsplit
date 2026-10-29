nextflow.enable.dsl=2

include { VALIDATE_INPUT } from '../modules/local/validate_input'
include { CLASSIFY_RDS } from '../modules/local/classify_rds'
include { SPLIT_H5AD } from '../modules/local/split_h5ad'
include { SPLIT_RDS } from '../modules/local/split_rds'
include { CONVERT_ANNDATA_TO_SCE } from '../modules/local/convert_anndata_to_sce'
include { CONVERT_ANNDATA_TO_SEURAT } from '../modules/local/convert_anndata_to_seurat'
include { CONVERT_RDS_TO_H5AD } from '../modules/local/convert_rds_to_h5ad'
include { CONVERT_SCE_TO_SEURAT } from '../modules/local/convert_sce_to_seurat'
include { CONVERT_SEURAT_TO_SCE } from '../modules/local/convert_seurat_to_sce'
include { COLLECT_OUTPUTS } from '../modules/local/collect_outputs'
workflow SCSPLIT {
    take:
    samplesheet
    split_column
    output_format
    outdir

    main:
    if (!(output_format in ['anndata', 'sce', 'seurat'])) {
        error "Unsupported output_format '${output_format}'; expected one of: anndata, sce, seurat"
    }

    validated = VALIDATE_INPUT(samplesheet)
    rows = validated.validated_samplesheet
        .splitCsv(header: true, sep: '\t')
        .map { row ->
            def meta = [id: row.name, name: row.name, input_format: row.input_format,
                        input_object_type: row.input_format == 'h5ad' ? 'AnnData' : null]
            tuple(meta, file(row.input_file), split_column)
        }

    h5ad_split = SPLIT_H5AD(rows.filter { meta, input, column -> meta.input_format == 'h5ad' })

    rds_classified = CLASSIFY_RDS(rows.filter { meta, input, column -> meta.input_format == 'rds' })
    rds_rows = rds_classified.classified.map { meta, input, classified_metadata ->
        def records = classified_metadata.text.readLines()
        if (records.size() < 2) {
            error "RDS classifier returned no metadata for ${meta.name}"
        }
        def header = records[0].split('\t', -1).collect { it.replaceAll(/^"|"$/, '') }
        def values = records[1].split('\t', -1).collect { it.replaceAll(/^"|"$/, '') }
        def type_index = header.findIndexOf { it == 'input_object_type' }
        if (type_index < 0 || type_index >= values.size() || !values[type_index]) {
            error "RDS classifier returned no input_object_type for ${meta.name}"
        }
        tuple(meta + [input_object_type: values[type_index]], input, split_column)
    }
    rds_split = SPLIT_RDS(rds_rows)

    anndata_parts = h5ad_split.split_outputs.flatMap { meta, directory, manifest ->
        directory.listFiles().findAll { it.name.endsWith('.h5ad') }.collect { tuple(meta, it, manifest) }
    }
    rds_parts = rds_split.split_outputs.flatMap { meta, directory, manifest ->
        directory.listFiles().findAll { it.name.endsWith('.rds') }.collect { tuple(meta, it, manifest) }
    }

    if (output_format == 'anndata') {
        h5ad_native = anndata_parts.map { meta, part, manifest -> tuple(meta, part, manifest, 'anndata') }
        rds_converted = CONVERT_RDS_TO_H5AD(rds_parts)
            .converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'anndata') }
        output_parts = h5ad_native.mix(rds_converted)
    } else if (output_format == 'sce') {
        sce_native = rds_parts
            .filter { meta, part, manifest -> meta.input_object_type == 'SingleCellExperiment' }
            .map { meta, part, manifest -> tuple(meta, part, manifest, 'sce') }
        seurat_converted = CONVERT_SEURAT_TO_SCE(
            rds_parts.filter { meta, part, manifest -> meta.input_object_type == 'Seurat' }
        ).converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'sce') }
        anndata_converted = CONVERT_ANNDATA_TO_SCE(anndata_parts)
            .converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'sce') }
        output_parts = sce_native.mix(seurat_converted).mix(anndata_converted)
    } else {
        seurat_native = rds_parts
            .filter { meta, part, manifest -> meta.input_object_type == 'Seurat' }
            .map { meta, part, manifest -> tuple(meta, part, manifest, 'seurat') }
        sce_converted = CONVERT_SCE_TO_SEURAT(
            rds_parts.filter { meta, part, manifest -> meta.input_object_type == 'SingleCellExperiment' }
        ).converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'seurat') }
        anndata_converted = CONVERT_ANNDATA_TO_SEURAT(anndata_parts)
            .converted_outputs.map { meta, part, manifest -> tuple(meta, part, manifest, 'seurat') }
        output_parts = seurat_native.mix(sce_converted).mix(anndata_converted)
    }

    grouped_outputs = output_parts.map { meta, part, manifest, format -> tuple(meta.name, meta, part, manifest, format) }
        .groupTuple(by: 0)
        .map { name, metas, parts, manifests, formats -> tuple(metas[0], parts, manifests.unique(), formats) }
    COLLECT_OUTPUTS(grouped_outputs, outdir)
}
