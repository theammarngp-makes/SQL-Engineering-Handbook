# 🗃️ Datasets

*Part of the [Resources Library](README.md) — [SQL Engineering Handbook](../README.md)*

For practice beyond this repo's own [`datasets/`](../datasets/) folder (employee_management, ecommerce, sales, finance, healthcare, nagpurlens). Once the Handbook's own schema feels comfortable, importing one of these into a local database is the natural next step — real data is messier than curated exercise data on purpose.

---

| Dataset Source | What It Is | Best For | Free / Paid |
|---|---|---|---|
| **Kaggle Datasets** | The largest general-purpose public dataset hub, spanning every domain | Broad selection with community notebooks showing how others approached the same data | Free |
| **data.gov** | The U.S. government's open data portal | Large, realistic government/civic datasets — good for practicing messy real-world joins | Free |
| **UCI Machine Learning Repository** | Long-standing academic dataset repository, originally built for ML research | Clean, well-documented classic datasets with clear schemas | Free |
| **NYC Open Data** | New York City's open government data portal | City-scale operational data (transit, permits, 311 calls) — excellent for `GROUP BY` and date-function practice | Free |
| **data.gov.in** | India's open government data portal | Practicing SQL against Indian civic/government datasets, directly relevant if projects like `nagpurlens` are on your mind | Free |

> [!TIP]
> Pick a dataset with at least three related tables before importing it — single flat CSVs don't exercise joins, which is most of what real SQL work actually is.

---

*Next: [`playgrounds.md`](playgrounds.md). Back to [Resources Library](README.md).*
