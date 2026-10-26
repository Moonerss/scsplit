# scsplit 设计文档

## 1. 项目概述

`scsplit` 是一个严格遵循 nf-core 社区项目构建风格的 Nextflow 流程，用于对包含多个样本的单细胞测序数据对象进行拆分。

流程根据用户指定的细胞元数据列对输入对象分组，并为每个分组生成独立的单细胞数据对象文件。

第一版支持以下输入和输出：

- H5AD 输入，内部对象为 AnnData；
- RDS 输入，内部对象限定为 SingleCellExperiment；
- H5AD 输出；
- SingleCellExperiment RDS 输出；
- 同时输出 H5AD 和 RDS。

项目将复用 `D:/code/Github/nextflow/scdownstream` 中已有的文件格式转换模块、软件环境配置和 nf-test 组织模式。

---

## 2. 目标与非目标

### 2.1 目标

- 支持 H5AD 和 SingleCellExperiment RDS 文件；
- 根据一个指定的细胞元数据列进行拆分；
- 支持多个输入数据集；
- 使用 samplesheet 中的 `name` 作为数据集唯一标识；
- 为每个输入数据集创建独立的输出目录；
- 支持 H5AD、RDS 或两种格式输出；
- 输出可追踪的拆分结果 manifest；
- 遵循 nf-core 的目录结构、参数 schema、模块化和测试规范；
- 支持 Docker、Conda 等可复现运行环境。

### 2.2 第一版非目标

第一版暂不支持：

- Seurat 或其他 RDS 对象类型；
- 多列联合拆分；
- 按基因元数据拆分；
- 按表达矩阵数值拆分；
- 自动推断拆分列；
- 自定义嵌套元数据路径；
- 运行时修改原始输入对象。

---

## 3. 支持的数据对象

| 输入格式 | 支持的对象 | 拆分元数据位置 |
| --- | --- | --- |
| `.h5ad` | AnnData | `adata.obs` |
| `.rds` | SingleCellExperiment | `colData(sce)` |

RDS 文件仅根据扩展名无法确定内部对象类型，因此流程必须在运行时检查对象是否为 `SingleCellExperiment`。如果对象类型不符合要求，流程应明确失败，而不是尝试静默转换或继续运行。

---

## 4. 用户接口

### 4.1 Samplesheet

流程使用 nf-core 风格的 CSV samplesheet。

```csv
name,input
pbmc_01,/data/pbmc_01.h5ad
pbmc_02,/data/pbmc_02.rds
```

字段定义：

| 字段 | 必需 | 说明 |
| --- | --- | --- |
| `name` | 是 | 输入数据集名称，同时用于输出目录和文件命名 |
| `input` | 是 | H5AD 或 RDS 文件路径 |

`name` 必须在 samplesheet 中唯一，并且应满足安全文件名要求。建议只允许字母、数字、下划线、短横线和点号，避免路径分隔符、空格或其他特殊字符。

### 4.2 核心参数

| 参数 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `--input` | 是 | 无 | 输入 samplesheet |
| `--split_column` | 是 | 无 | 用于拆分的细胞元数据列 |
| `--output_format` | 否 | `h5ad` | 输出格式：`h5ad`、`rds` 或 `both` |
| `--outdir` | 否 | `results` | 输出目录 |

运行示例：

```bash
nextflow run nf-core/scsplit \\
    --input samplesheet.csv \\
    --split_column donor \\
    --output_format h5ad \\
    --outdir results
```

同时输出 H5AD 和 RDS：

```bash
nextflow run nf-core/scsplit \\
    --input samplesheet.csv \\
    --split_column donor \\
    --output_format both \\
    --outdir results
```

### 4.3 第一版可选参数

后续可加入以下参数：

```text
--missing_value_policy error|drop|label
--keep_intermediate
--overwrite
```

第一版建议只实现 `missing_value_policy=error` 的默认行为，其他策略可在基础流程稳定后增加。

---

## 5. 核心处理逻辑

总体数据流如下：

```text
samplesheet
    |
    v
输入校验
    |
    v
按扩展名分流
    |
    +----------------------+
    |                      |
    v                      v
  H5AD                   RDS
    |                      |
    |                      v
    |              检查 SingleCellExperiment
    |                      |
    v                      v
按 obs 列拆分        按 colData 列拆分
    |                      |
    +----------+-----------+
               |
               v
       根据 output_format 分支
               |
        +------+------+
        |             |
        v             v
      H5AD          RDS
        |             |
        +------+------+
               |
               v
       整理输出并生成 manifest
```

### 5.1 H5AD 分支

```text
H5AD -> AnnData -> 根据 adata.obs[split_column] 拆分 -> 多个 H5AD
                                                     -> 可选转换为 RDS
```

### 5.2 RDS 分支

```text
RDS -> SingleCellExperiment -> 根据 colData(sce)[[split_column]] 拆分 -> 多个 RDS
                                                                     -> 可选转换为 H5AD
```

H5AD 和 RDS 优先分别使用其原生生态完成拆分，避免不必要的跨语言转换。跨格式转换只在用户请求的输出格式与输入格式不一致时执行。

---

## 6. 输出设计

### 6.1 输出目录

输出目录按照输入数据的 `name` 组织：

```text
results/
├── pbmc_01/
│   ├── h5ad/
│   │   ├── donor_A.h5ad
│   │   └── donor_B.h5ad
│   ├── rds/
│   │   ├── donor_A.rds
│   │   └── donor_B.rds
│   └── split_manifest.tsv
├── pbmc_02/
│   ├── h5ad/
│   │   ├── donor_A.h5ad
│   │   └── donor_C.h5ad
│   ├── rds/
│   │   ├── donor_A.rds
│   │   └── donor_C.rds
│   └── split_manifest.tsv
└── pipeline_info/
    ├── execution_report.html
    ├── execution_timeline.html
    ├── execution_trace.txt
    ├── pipeline_dag.svg
    └── software_versions.yml
```

其中：

- 顶层数据集目录来自 samplesheet 的 `name`；
- 不使用输入文件名作为顶层输出目录；
- `h5ad/` 只存放 H5AD 输出；
- `rds/` 只存放 RDS 输出；
- `both` 模式同时生成两个目录；
- 每个数据集生成一个独立的 `split_manifest.tsv`。

### 6.2 输出文件命名

默认使用拆分列的分组值作为文件名：

```text
donor_A.h5ad
donor_B.h5ad
```

原始分组值如果包含不适合作为文件名的字符，应进行安全化处理。例如：

```text
原始值：donor/A
文件名：donor_A.h5ad
```

安全化后发生文件名冲突时，必须使用稳定后缀消除冲突，例如：

```text
donor_A__<hash>.h5ad
```

manifest 必须保留原始分组值，不能只保存安全化后的文件名。

### 6.3 Split manifest

每个输入数据集输出：

```text
results/<name>/split_manifest.tsv
```

建议字段：

```text
name
input_file
input_format
split_column
split_value
output_format
output_file
n_cells
n_features
```

示例：

```text
name\tinput_file\tinput_format\tsplit_column\tsplit_value\toutput_format\toutput_file\tn_cells\tn_features
pbmc_01\tpbmc_01.h5ad\th5ad\tdonor\tdonor_A\th5ad\tdonor_A.h5ad\t3421\t18642
pbmc_01\tpbmc_01.h5ad\th5ad\tdonor\tdonor_B\th5ad\tdonor_B.h5ad\t2987\t18642
```

当 `output_format=both` 时，同一个分组可对应两行输出：

```text
pbmc_01\t...\tdonor_A\th5ad\tdonor_A.h5ad\t3421\t18642
pbmc_01\t...\tdonor_A\trds\tdonor_A.rds\t3421\t18642
```

---

## 7. 模块设计

### 7.1 `VALIDATE_INPUT`

职责：

- 读取并校验 samplesheet；
- 检查 `name` 和 `input` 字段；
- 检查 `name` 是否唯一；
- 检查输入文件是否存在；
- 检查输入扩展名是否为 `.h5ad` 或 `.rds`；
- 检查 `name` 是否可以安全用于输出路径；
- 生成标准化 metadata。

建议的 metadata：

```groovy
[
    id: name,
    name: name,
    input_format: 'h5ad',
    filename: file.baseName
]
```

其中 `name` 是整个流程的数据集级唯一标识。

### 7.2 `SPLIT_H5AD`

输入：

```text
tuple val(meta), path(input), val(split_column)
```

处理：

- 使用 AnnData 读取 H5AD；
- 验证 `split_column` 存在于 `adata.obs`；
- 获取分组值；
- 为每个分组生成子集；
- 写出 H5AD；
- 统计细胞数和特征数；
- 生成 manifest；
- 输出 `versions.yml`。

输出：

```text
tuple val(meta), path('*.h5ad'), path('split_manifest.tsv')
```

该模块应优先参考并改造：

```text
scdownstream/modules/local/adata/splitcol/
```

### 7.3 `SPLIT_SCE_RDS`

输入：

```text
tuple val(meta), path(input), val(split_column)
```

处理：

- 使用 R 读取 RDS；
- 验证对象为 `SingleCellExperiment`；
- 验证 `split_column` 存在于 `colData`；
- 获取分组值；
- 对列进行子集化；
- 保留 assays、colData、rowData 和 reducedDims；
- 写出 RDS；
- 生成 manifest；
- 输出 `versions.yml`。

输出：

```text
tuple val(meta), path('*.rds'), path('split_manifest.tsv')
```

### 7.4 `CONVERT_H5AD_TO_SCE_RDS`

处理：

```text
H5AD -> AnnData -> SingleCellExperiment -> RDS
```

建议先完成 H5AD 拆分，再对每个拆分后的 H5AD 单独转换：

```text
input.h5ad -> donor_A.h5ad -> donor_A.rds
```

转换实现和软件环境优先复用 `scdownstream` 中已有的 H5AD/RDS 转换模块。

需要明确记录转换后的数据保留情况，包括：

- `obs` 到 `colData`；
- `var` 到 `rowData`；
- `X` 到主 assay；
- `layers` 到 additional assays（如果转换工具支持）；
- `obsm` 到 `reducedDims`（如果转换工具支持）。

### 7.5 `CONVERT_SCE_RDS_TO_H5AD`

处理：

```text
RDS -> SingleCellExperiment -> AnnData -> H5AD
```

建议对每个拆分后的 RDS 文件单独转换：

```text
input.rds -> donor_A.rds -> donor_A.h5ad
```

该模块复用 `scdownstream` 中已有的转换模块和环境定义，并将 metadata 适配到 `scsplit` 的数据集目录结构。

### 7.6 `COLLECT_OUTPUTS`

职责：

- 根据 `meta.name` 创建数据集级输出目录；
- 将 H5AD 输出放入 `${name}/h5ad/`；
- 将 RDS 输出放入 `${name}/rds/`；
- 生成或整理 `split_manifest.tsv`；
- 汇总输出文件数量、细胞数和特征数；
- 发布最终结果。

中间模块不应直接硬编码最终输出路径，最终路径由统一的输出整理步骤负责。

---

## 8. 异常和边界行为

| 场景 | 第一版行为 |
| --- | --- |
| `split_column` 不存在 | 流程失败 |
| RDS 对象不是 SingleCellExperiment | 流程失败 |
| 输入对象没有细胞 | 流程失败 |
| 没有有效分组 | 流程失败 |
| 只有一个分组 | 正常输出一个文件 |
| 一个分组只有一个细胞 | 正常输出 |
| 分组值包含特殊字符 | 文件名安全化，manifest 保留原始值 |
| 安全化后文件名冲突 | 增加稳定后缀 |
| 分组列包含缺失值 | 默认流程失败 |
| 输入扩展名不支持 | schema 或输入校验阶段失败 |
| `output_format` 非法 | schema 校验阶段失败 |
| `name` 重复 | 输入校验阶段失败 |

---

## 9. 项目结构

```text
scsplit/
├── main.nf
├── nextflow.config
├── nextflow_schema.json
├── README.md
├── LICENSE
├── CITATIONS.md
├── assets/
│   └── schema_input.json
├── conf/
│   ├── base.config
│   └── modules.config
├── workflows/
│   └── scsplit.nf
├── modules/
│   ├── local/
│   │   ├── validate_input/
│   │   ├── split_h5ad/
│   │   ├── split_sce_rds/
│   │   ├── convert_h5ad_to_rds/
│   │   ├── convert_rds_to_h5ad/
│   │   └── collect_outputs/
│   └── nf-core/
├── subworkflows/
│   ├── local/
│   │   ├── split_h5ad/
│   │   ├── split_sce_rds/
│   │   └── convert_outputs/
│   └── nf-core/
├── tests/
│   ├── test_data/
│   ├── default.nf.test
│   ├── default.nf.test.snap
│   ├── h5ad.nf.test
│   ├── rds.nf.test
│   └── invalid_input.nf.test
├── docs/
└── .github/
    └── workflows/
```

---

## 10. 主工作流设计

主入口保持 nf-core 标准形式：

```text
main.nf
```

具体流程位于：

```text
workflows/scsplit.nf
```

逻辑上包含以下步骤：

```groovy
workflow SCSPLIT {

    take:
    input
    split_column

    main:

    validated_input = VALIDATE_INPUT(input)

    h5ad_input = validated_input
        .filter { meta, file -> meta.input_format == 'h5ad' }

    rds_input = validated_input
        .filter { meta, file -> meta.input_format == 'rds' }

    split_h5ad = SPLIT_H5AD(h5ad_input, split_column)
    split_sce_rds = SPLIT_SCE_RDS(rds_input, split_column)

    // 根据 output_format 选择原生输出或跨格式转换
    // 最终由 COLLECT_OUTPUTS 统一整理目录和 manifest
}
```

实际实现中，`output_format` 的分支逻辑应封装到本地子工作流或清晰的 workflow channel 操作中，避免主工作流承担过多格式转换细节。

---

## 11. 测试策略

### 11.1 基础测试

至少覆盖：

1. H5AD 输入，输出 H5AD；
2. RDS 输入，输出 RDS；
3. H5AD 输入，输出 RDS；
4. RDS 输入，输出 H5AD；
5. `both` 模式；
6. 多个 samplesheet 输入；
7. 每个输入数据集使用独立的 `name` 目录。

### 11.2 错误测试

至少覆盖：

1. 不支持的输入后缀；
2. samplesheet 缺少 `name`；
3. `name` 重复；
4. `split_column` 不存在；
5. RDS 对象不是 SingleCellExperiment；
6. 输入对象没有细胞；
7. 分组列存在缺失值；
8. `output_format` 非法。

### 11.3 输出验证

测试不能只验证输出文件是否存在，还需要验证：

- 输出细胞数；
- 输出分组列只包含目标分组；
- 输出对象格式；
- H5AD 的 `obs`；
- SCE 的 `colData`；
- manifest 中的分组和文件映射；
- RDS/H5AD 转换前后细胞数量是否一致；
- 输出目录是否使用 samplesheet 的 `name`。

### 11.4 测试工具

项目使用：

```bash
nf-test test
nf-core lint
pre-commit run --all-files
```

模块、子工作流和完整流程均应提供相应的测试与 snapshot。测试数据应尽量使用小型、可公开分发的数据对象。

---

## 12. 软件环境和代码复用

`scsplit` 优先复用 `scdownstream` 中已有的：

- H5AD 读取和写出模块；
- RDS 读取和写出模块；
- H5AD/RDS 转换模块；
- Python 和 R 的容器或 Conda 环境；
- `versions.yml` 输出模式；
- module `meta.yml` 结构；
- nf-test 测试和 stub 模式。

复用代码时需要进行以下适配：

- 将输入 metadata 改为 `name` 驱动；
- 将输出目录改为 `results/<name>/h5ad` 和 `results/<name>/rds`；
- 增加拆分值和输出文件之间的 manifest 映射；
- 确保拆分后的多个输出文件可以被 Nextflow 正确展开；
- 保留原始分组值，避免安全化文件名丢失信息。

---

## 13. 开发顺序

### 阶段一：初始化 nf-core 项目骨架

建立：

- `main.nf`；
- `workflows/scsplit.nf`；
- `nextflow_schema.json`；
- `assets/schema_input.json`；
- `conf/`；
- `modules/`；
- `subworkflows/`；
- `tests/`；
- 文档和 CI 配置。

### 阶段二：实现 H5AD 到 H5AD

```text
H5AD -> 按 obs 列拆分 -> 多个 H5AD
```

这是第一条最小可用路径。

### 阶段三：实现 SingleCellExperiment RDS 到 RDS

```text
SCE RDS -> 按 colData 列拆分 -> 多个 SCE RDS
```

### 阶段四：复用并接入跨格式转换

实现：

```text
H5AD -> RDS
RDS -> H5AD
```

### 阶段五：完成数据集级输出目录和 manifest

统一输出为：

```text
results/<name>/h5ad/
results/<name>/rds/
results/<name>/split_manifest.tsv
```

### 阶段六：完善测试和 nf-core 质量检查

执行：

```bash
nf-test test
nf-core lint
pre-commit run --all-files
```

---

## 14. 第一版设计结论

第一版 `scsplit` 的正式设计边界如下：

```text
输入：
  samplesheet.csv
  name,input

数据类型：
  H5AD / AnnData
  RDS / SingleCellExperiment

拆分方式：
  --split_column 指定细胞元数据列

输出格式：
  h5ad、rds 或 both

输出目录：
  results/<name>/h5ad/
  results/<name>/rds/
  results/<name>/split_manifest.tsv

代码复用：
  复用 scdownstream 的 H5AD/RDS 转换模块、软件环境和测试模式

默认行为：
  默认输出 H5AD
  缺失拆分列直接失败
  RDS 非 SingleCellExperiment 直接失败
  缺失分组值默认直接失败
  单一分组正常输出
```

该设计优先保证对象类型、输入输出关系、目录结构和可追踪性明确，为后续扩展 Seurat、多列拆分或更多对象类型保留空间，但不在第一版引入这些复杂性。
