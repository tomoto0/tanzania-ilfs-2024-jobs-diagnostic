# Tanzania 2024 ILFS — Jobs Diagnostic Report

A jobs diagnostic of Tanzania based on the 2024 Integrated Labour Force Survey (ILFS), prepared as part of a short-term consulting engagement for **FCDO via ODI**. This repository contains the LaTeX report, BibTeX references, all figures cited in the report, and a self-contained Stata do-file that reproduces the underlying tabulations from the raw ILFS microdata.

## Engagement summary

**Short-Term Consultant — Tanzania Jobs Diagnostic** (Feb 2026 – Mar 2026)
*Labour economics consulting engagement, remote (UK).*

- Analysed the 2024 Tanzania Labour Force Survey for a 30-page jobs diagnostic paper, focusing on how employment status, informality, earnings, and labour-market attachment differ by gender and age.
- Wrote the report section on informal work in Tanzania using Gary Fields' high- and low-informality categories, linking survey evidence to policy-relevant discussion of vulnerability and job quality.
- Delivered clean, reproducible Stata and R code, regression tables, descriptive figures, and documented intermediate datasets for integration into the final diagnostic paper.
- Built practical knowledge of Tanzania's poverty, employment, and urbanisation context, including constraints facing youth, women, and informal workers.

## Repository contents

```
tanzania-ilfs-2024-jobs-diagnostic/
├── README.md
├── report_Tanzania_ilfs_2024.tex          # full LaTeX report
├── references_Tanzania_ilfs_2024.bib      # 21 BibTeX entries
├── consolidated_do_file_ilfs_2024.do      # Stata do-file (variable construction + tabulations)
└── figures/                               # 34 JPG figures (fig01–fig31, plus fig07b/14b/14c)
```

| File | Description |
|------|-------------|
| `report_Tanzania_ilfs_2024.tex` | Full LaTeX report. Compiles to a self-contained PDF using the bibliography and figures in this repository. |
| `references_Tanzania_ilfs_2024.bib` | Bibliography for the literature review (job-ladder framework, gender and informality, education and care, digital divide). |
| `consolidated_do_file_ilfs_2024.do` | Single-file Stata pipeline that loads `ilfs.dta`, constructs all derived variables, and writes every cross-tabulation used in the report to one multi-sheet Excel workbook. |
| `figures/` | All 34 JPG figures referenced in the report, named to match the `\includegraphics` paths in the `.tex` source. |

## Report contents

The report covers:

1. **Labour force status** — overall and by gender (LFPR, employment, unemployment, OLF).
2. **Work status composition** — eight-category reporting frame derived from a ten-category ICSE-93–aligned classification, with the gender breakdown across all categories.
3. **Education** — distribution by gender, by work status, and a focused view of the higher-tier categories.
4. **Youth (15–24)** — comparison of work status between youth and adults by gender.
5. **Out-of-labour-force reasons** — gendered drivers of non-participation (childcare, pregnancy, retirement, seasonal factors).
6. **Public/private sector and online work** — sector split by work status and digital participation gradients across status, gender, and education.
7. **Sectoral patterns** — ISIC 1-digit sector by work status (main and secondary jobs), manufacturing sub-sector deep-dive, gender segregation across sub-sectors.
8. **Informal enterprise motives and credit** — Q45B reasons for starting a business, Q47A/Q47B credit access and source by sector and gender.
9. **Secondary activity, location, and working time** — secondary activity prevalence, three-way split (rural / other urban / Dar es Salaam) for labour force status, work status composition, online work, and quarterly hours.

## Data source

The microdata file (`ilfs.dta`, ~209 MB) is **not redistributed** in this repository. It can be obtained directly from the **National Bureau of Statistics (NBS), Tanzania** at <https://www.nbs.go.tz>, subject to NBS's terms of access.

- **Survey:** Tanzania Integrated Labour Force Survey (ILFS) 2024.
- **Sample:** 35,829 respondents aged 15+ (population ≈ 37.3 million); employed sub-sample 27,458 (≈ 31.0 million).
- **Weights:** All percentages in the report are survey-weighted using the WEIGHT variable.

## Conceptual framework

The classification follows the job-ladder approach of Fields (2023) and the related UNU-WIDER work, separating wage employees from the self-employed and dividing each into formal, upper-tier informal, and lower-tier informal segments. The ten-category underlying construction is aligned with ILO ICSE-93; the eight-category display merges OA lower informal and contributing family workers for figure legibility.

## Reproducing the analysis

1. **Obtain the microdata.** Download the 2024 ILFS dataset from NBS Tanzania and save it as `ilfs.dta` at a location of your choice.
2. **Edit globals.** Open `consolidated_do_file_ilfs_2024.do` and set the `$root` and `$dta_file` globals at the top to match your local paths.
3. **Run the do-file.** In Stata 17+, execute the do-file end-to-end. It constructs all derived variables (work status, education bands, area3, secondary activity flags, etc.) and writes every numerical table that feeds the figures into a single Excel workbook (`polished_graphs_data.xlsx`).
4. **Compile the report.**

   ```bash
   pdflatex report_Tanzania_ilfs_2024.tex
   bibtex   report_Tanzania_ilfs_2024
   pdflatex report_Tanzania_ilfs_2024.tex
   pdflatex report_Tanzania_ilfs_2024.tex
   ```

The report's `.tex` source loads images from `figures/` and references the `.bib` file in the repository root, so no further configuration is needed once the figures and bibliography are alongside the `.tex`.

## Client and authorship

- **Client:** FCDO / ODI
- **Author:** Tomoto Masuda
- **Period:** February 2026 – March 2026

## License

The report text, do-file, and figures in this repository are made available for non-commercial reference. Underlying ILFS microdata is the property of NBS Tanzania and is **not redistributed here**; users must obtain it directly from NBS subject to its access terms.
