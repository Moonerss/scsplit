# scsplit 设计文档

## 1. 范围

`scsplit` 是一个 Nextflow DSL2 流程，按一个细胞 metadata 列拆分多个单细胞数据集，并为每次运行选择一种输出格式。

支持：

- H5AD / AnnData；
- SingleCellExperiment RDS；
- Seurat RDS；
- AnnData H5AD、SingleCellExperiment RDS、Seurat RDS 三种目标格式。

每个输入数据集使用 samplesheet 的 `name` 标识，输出独立目录和 split manifest。流程不修改原始输入。

## 2. 用户接口

### 2.1 Samplesheet

```csv
name,input
pbmc_01,/data/pbmc_01.h5ad
pbmc_02,/data/pbmc_02.rds
```

必须且只能包含 `name,input` 两列：

| 字段 | 说明 |
| --- | --- |
| `name` | 唯一数据集名；只能包含字母、数字、`_`、`-`、`.` |
| `input` | `.h5ad` 或 `.rds` 文件路径 |

### 2.2 参数

| 参数 | 必需 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `--input` | 是 | 无 | CSV samplesheet |
| `--split_column` | 是 | 无 | 所有输入对象中存在的细胞 metadata 列 |
| `--output_format` | 否 | `anndata` | `anndata`、`sce` 或 `seurat` |
| `--outdir` | 否 | `results` | 输出目录 |

`--split_column` 缺失或为空时，`main.nf` 在启动任何 process 前失败。指定的列不存在、包含缺失值或对象为空时，对应处理阶段失败。

WSL + Singularity 示例：

```bash
cd /mnt/d/code/Github/nextflow/scsplit
nextflow run . -profile singularity \
    --input tests/test_data/samplesheet_all.csv \
    --split_column donor \
    --output_format anndata \
    --outdir results/test_data
```

## 3. 数据和流程

| 输入 | 对象 | metadata 位置 | 原生拆分 |
| --- | --- | --- | --- |
| `.h5ad` | AnnData | `adata.obs` | `SPLIT_H5AD` |
| `.rds` | SingleCellExperiment | `colData(sce)` | `SPLIT_RDS` |
| `.rds` | Seurat | `obj[[]]` | `SPLIT_RDS` |

RDS 必须在运行时识别为 SingleCellExperiment 或 Seurat；其他对象直接失败。

```text
samplesheet
  -> VALIDATE_INPUT
  -> 按扩展名分流
     -> H5AD: SPLIT_H5AD
     -> RDS: CLASSIFY_RDS -> SPLIT_RDS
  -> 按 output_format 保留原生结果或执行转换
  -> 按数据集分组
  -> COLLECT_OUTPUTS
```

转换只在目标格式与原生格式不一致时执行：

```text
H5AD -> SCE RDS / Seurat RDS
SCE RDS -> Seurat RDS / AnnData H5AD
Seurat RDS -> SCE RDS / AnnData H5AD
```

## 4. 输出

每个数据集只创建所选格式目录：

```text
results/<name>/
├── anndata/       # output_format=anndata 时存在
├── sce/           # output_format=sce 时存在
├── seurat/        # output_format=seurat 时存在
└── split_manifest.tsv
```

分组值用于文件名时先安全化：非字母、数字、`_`、`-`、`.` 的字符替换为 `_`。安全化后发生冲突时追加稳定哈希，例如 `donor_A__<hash>.h5ad`。manifest 始终保留原始分组值。

Manifest 字段：

```text
name
input_file
input_format
input_object_type
split_column
split_value
output_format
output_object_type
output_file
n_cells
n_features
```

## 5. 模块契约

所有 process 的实现脚本位于仓库根目录 `bin/`，由 process 按命令名调用，通过 CLI 参数接收输入；不使用 `template` 插值。

### `VALIDATE_INPUT`

读取并校验 samplesheet，检查列名、数据集名、重复名、文件存在性和输入扩展名，输出标准化 TSV。

### `CLASSIFY_RDS`

识别 RDS 对象为 SingleCellExperiment 或 Seurat，并输出对象类型 metadata。

### `SPLIT_H5AD` / `SPLIT_RDS`

验证对象维度和拆分列，按唯一分组值生成子对象、split manifest 和 `versions.yml`。

输入契约：

```text
tuple val(meta), path(input), val(split_column)
```

### 转换模块

每个拆分对象单独转换，并生成与该对象对应的转换 manifest：

- `CONVERT_ANNDATA_TO_SCE`
- `CONVERT_ANNDATA_TO_SEURAT`
- `CONVERT_RDS_TO_H5AD`
- `CONVERT_SCE_TO_SEURAT`
- `CONVERT_SEURAT_TO_SCE`

### `COLLECT_OUTPUTS`

按 `meta.name` 创建数据集目录，复制最终对象，整理目标格式目录和最终 `split_manifest.tsv`。中间模块不负责最终发布路径。

## 6. 边界行为

| 场景 | 行为 |
| --- | --- |
| `--split_column` 缺失或为空 | 入口立即失败并提示参数格式 |
| metadata 列不存在 | 对应拆分 process 失败 |
| RDS 类型不支持 | `CLASSIFY_RDS` 失败 |
| 对象没有细胞或特征 | 拆分或转换失败 |
| 分组列有缺失值 | 拆分失败 |
| 没有有效分组 | 拆分失败 |
| 一个分组 | 正常输出一个文件 |
| 分组值含特殊字符 | 文件名安全化，manifest 保留原值 |
| 安全化文件名冲突 | 追加稳定后缀 |
| 输入后缀不支持 | 输入校验失败 |
| `output_format` 非法 | 工作流校验失败 |
| `name` 重复 | 输入校验失败 |

## 7. 项目结构

```text
scsplit/
├── main.nf
├── nextflow.config
├── nextflow_schema.json
├── README.md
├── DESIGN.md
├── AGENTS.md
├── bin/
├── workflows/scsplit.nf
├── modules/local/
├── containers/
├── conf/
├── assets/
└── tests/test_data/
```

关键文件：

- `main.nf`：入口、参数默认值和早期参数校验；
- `workflows/scsplit.nf`：路由、格式分支和聚合；
- `modules/local/`：process 定义；
- `bin/`：Python/R 运行脚本；
- `nextflow_schema.json`：CLI 参数约束；
- `containers/`：统一运行环境；
- `tests/test_data/`：确定性测试 fixture。

## 8. 环境和验证

模块 Conda 环境位于各模块的 `environment.yml`；统一容器依赖位于 `containers/environment.yml`。支持 `conda`、`docker`、`singularity` 和 `apptainer` profile。

当前可执行检查：

```bash
python3 -m py_compile bin/*.py
nextflow lint .
```

完整验证使用 WSL + Singularity 示例命令。仓库当前没有 nf-test 文件、snapshot、测试 harness 或 pre-commit 配置。新增测试应检查对象类型、细胞和特征数量、分组成员、manifest 映射、转换结果和数据集目录名。
