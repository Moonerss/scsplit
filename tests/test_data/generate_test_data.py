#!/usr/bin/env python3
"""Generate a small deterministic AnnData fixture for scsplit."""

from pathlib import Path

import anndata as ad
import numpy as np
import pandas as pd

output_dir = Path(__file__).resolve().parent
output_dir.mkdir(parents=True, exist_ok=True)

# Three groups deliberately exercise filename sanitization and collision handling:
# "donor A" and "donor_A" both sanitize to donor_A, while "donor/B" becomes donor_B.
cell_ids = [f"cell_{index:02d}" for index in range(1, 13)]
group_values = ["donor A"] * 4 + ["donor_A"] * 4 + ["donor/B"] * 4
batch_values = ["batch_1"] * 6 + ["batch_2"] * 6
counts = np.arange(1, 73, dtype=np.int32).reshape(12, 6)

obs = pd.DataFrame(
    {
        "donor": group_values,
        "batch": batch_values,
        "n_counts": counts.sum(axis=1),
    },
    index=cell_ids,
)
var = pd.DataFrame(
    {"gene_symbol": [f"Gene{index}" for index in range(1, 7)]},
    index=[f"gene_{index:02d}" for index in range(1, 7)],
)
adata = ad.AnnData(X=counts, obs=obs, var=var)
adata.uns["simulated"] = True
adata.uns["seed"] = 20261027
h5ad_path = output_dir / "simulated_cells.h5ad"
adata.write_h5ad(h5ad_path)

samplesheet_h5ad = output_dir / "samplesheet_h5ad.csv"
pd.DataFrame(
    [{"name": "simulated_h5ad", "input": str(h5ad_path.resolve())}]
).to_csv(samplesheet_h5ad, index=False)

rds_path = output_dir / "simulated_cells.rds"
if rds_path.exists():
    pd.DataFrame(
        [
            {"name": "simulated_h5ad", "input": str(h5ad_path.resolve())},
            {"name": "simulated_rds", "input": str(rds_path.resolve())},
        ]
    ).to_csv(output_dir / "samplesheet_all.csv", index=False)

print(f"wrote {h5ad_path} ({adata.n_obs} cells x {adata.n_vars} features)")
print(f"wrote {samplesheet_h5ad}")
if rds_path.exists():
    print(f"wrote {output_dir / 'samplesheet_all.csv'}")
