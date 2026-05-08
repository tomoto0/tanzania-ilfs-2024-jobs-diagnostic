# Tanzania 2024 ILFS — Jobs Diagnostic Report

A jobs diagnostic of Tanzania based on the 2024 Integrated Labour Force Survey (ILFS), prepared as part of a short-term consulting engagement for **FCDO via ODI**. The repository contains the full LaTeX report, BibTeX references, and the 34 figures referenced in the text.

## Engagement summary

**Short-Term Consultant — Tanzania Jobs Diagnostic** (Feb 2026 – Mar 2026)
*Labour economics consulting engagement, remote (UK).*

- Analysed the 2024 Tanzania Labour Force Survey for a 30-page jobs diagnostic paper, focusing on how employment status, informality, earnings, and labour-market attachment differ by gender and age.
- Wrote the report section on informal work in Tanzania using Gary Fields' high- and low-informality categories, linking survey evidence to policy-relevant discussion of vulnerability and job quality.
- Delivered clean, reproducible Stata and R code, regression tables, descriptive figures, and documented intermediate datasets for integration into the final diagnostic paper.
- Built practical knowledge of Tanzania's poverty, employment, and urbanisation context, including constraints facing youth, women, and informal workers.

## Report contents

The report (`report_Tanzania_ilfs_2024.tex`) covers:

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

- **Survey:** Tanzania Integrated Labour Force Survey (ILFS) 2024.
- **Sample:** 35,829 respondents aged 15+ (population ≈ 37.3 million); employed sub-sample 27,458 (≈ 31.0 million).
- All percentages are survey-weighted using the WEIGHT variable.

## Conceptual framework

The report uses the job-ladder approach of Fields (2023) and the related UNU-WIDER work, separating wage employees from the self-employed and dividing each into formal, upper-tier informal, and lower-tier informal segments. The ten-category underlying classification follows ILO ICSE-93, with the eight-category display merging OA lower informal and contributing family workers for figure legibility.

## Repository contents

```
tanzania-ilfs-2024-jobs-diagnostic/
├── README.md
├── report_Tanzania_ilfs_2024.tex      # full LaTeX report
├── references_Tanzania_ilfs_2024.bib  # 21 BibTeX entries
└── figures/                           # 34 JPG figures (fig01–fig31)
```

## Building the report

The report compiles with any standard LaTeX distribution. Both source files and the bibliography are in the repository root; figures are loaded from `figures/`.

```bash
pdflatex report_Tanzania_ilfs_2024.tex
bibtex   report_Tanzania_ilfs_2024
pdflatex report_Tanzania_ilfs_2024.tex
pdflatex report_Tanzania_ilfs_2024.tex
```

## Client and authorship

- **Client:** FCDO / ODI
- **Author:** Tomoto Masuda
- **Period:** February 2026 – March 2026

## License

The report text and figures are made available for non-commercial reference. Underlying ILFS microdata are not redistributed in this repository.
