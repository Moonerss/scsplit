# 测试模拟数据

本目录包含用于 `scsplit` 本地验证的最小数据集：

- `simulated_cells.h5ad`：12 个细胞、6 个 feature 的 AnnData；
- `simulated_cells.rds`：内容对应的 12 个细胞、6 个 feature 的 `SingleCellExperiment`；
- `simulated_seurat.rds`：12 个细胞、6 个 feature 的 Seurat 对象；
- `samplesheet_h5ad.csv`：仅 H5AD 输入；
- `samplesheet_rds.csv`：仅 SCE RDS 输入；
- `samplesheet_seurat.csv`：仅 Seurat RDS 输入；
- `samplesheet_all.csv`：同时包含 AnnData、SingleCellExperiment 和 Seurat 输入；
- `generate_test_data.py`、`generate_test_data.R` 和 `generate_test_data_seurat.R`：可重复生成上述数据的脚本。

三个对象都使用 `donor` 作为拆分列，分组如下：

| `donor` 值 | 细胞数 | 文件名处理场景 |
| --- | ---: | --- |
| `donor A` | 4 | 空格替换为 `_` |
| `donor_A` | 4 | 与上一组清理后名称冲突，触发摘要后缀 |
| `donor/B` | 4 | `/` 替换为 `_` |

## 重新生成

在仓库根目录执行：

```powershell
& 'D:\software\uv_envs\analysis\.venv\Scripts\python.exe' tests/test_data/generate_test_data.py
& 'D:\software\R-4.6.1\bin\Rscript.exe' tests/test_data/generate_test_data.R
& 'D:\software\R-4.6.1\bin\Rscript.exe' tests/test_data/generate_test_data_seurat.R
```

脚本使用固定种子元数据 `20261027` 和固定矩阵值，不依赖随机数；三个生成脚本按顺序运行后会刷新包含 AnnData、SCE 和 Seurat 三种输入的 `samplesheet_all.csv`。

## 运行示例

```powershell
nextflow run . -profile singularity `
  --input tests/test_data/samplesheet_seurat.csv `
  --split_column donor `
  --output_format seurat `
  --outdir results/test_seurat
```

`--output_format` 必须且只能取 `anndata`、`sce` 或 `seurat`，每次运行只产生一种目标格式。运行前需已构建 `containers/scsplit.sif`；也可改用已配置好依赖的 `-profile conda`。

样本表中的路径由生成脚本写为当前仓库的绝对路径，因此在其他目录使用前应重新运行生成脚本。
