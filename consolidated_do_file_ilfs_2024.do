/*==============================================================================
  consolidated_do_file_ilfs_2024.do

  Purpose:
    For ilfs.dta, constructs all variable used in the 6-category report, 
	and exports all cross-tabulations to ONE Excel workbook. 
	After running this file, the workbook at $out_xlsx contains every numerical
	table that the polished graph book (polished_graphs_revised.xlsx) is built from.

  Usage:
    Edit the globals in Section 0, then run end-to-end.

  Output:
    $root/output/tables/polished_graphs_data.xlsx (multi-sheet workbook)

  Sample:
    Working-age population (Q06B_MEM_AGE >= 15) with non-missing LFS status,
    matching the rest of the project's pipeline (N ~= 35,829).

==============================================================================*/

clear all
set more off
capture log close
version 17

*------------------------------------------------------------------------------
* 0. GLOBALS — edit these two lines if paths change
*------------------------------------------------------------------------------
global root      "/Users/masuda_1/Desktop/Tanzania LFS"
global dta_file  "$root/ilfs.dta"
global out_xlsx  "$root/output/tables/polished_graphs_data.xlsx"

*------------------------------------------------------------------------------
* 1. LOAD DATA
*------------------------------------------------------------------------------
use "$dta_file", clear


*------------------------------------------------------------------------------
* 2. DEMOGRAPHICS
*------------------------------------------------------------------------------
* Sex: 1 = Female, 0 = Male.
gen byte female = (Q04_MEM_SEX == 2) if !missing(Q04_MEM_SEX)
label define female_lbl 0 "Male" 1 "Female", replace
label values female female_lbl

* Youth flag: ages 15-24.
gen byte youth = (Q06B_MEM_AGE >= 15 & Q06B_MEM_AGE <= 24) if !missing(Q06B_MEM_AGE)

* Education (Tanzania 7-4-2-3 system).
* Q11B == 4 = "Never attended"; remaining missing = young children.
gen byte educ_detail = .
replace educ_detail = 0 if Q11B == 4 | Q11D == 0
replace educ_detail = 1 if inrange(Q11D, 1, 6)
replace educ_detail = 2 if inlist(Q11D, 7, 8)
replace educ_detail = 3 if inlist(Q11D, 9, 10)
replace educ_detail = 4 if inrange(Q11D, 11, 13)
replace educ_detail = 5 if Q11D == 14
replace educ_detail = 6 if inlist(Q11D, 15, 16)
replace educ_detail = 7 if inlist(Q11D, 17, 18)
replace educ_detail = 8 if inrange(Q11D, 19, 22)

gen byte educ_level = .
replace educ_level = 0 if educ_detail == 0
replace educ_level = 1 if inlist(educ_detail, 1, 2, 3)   // Primary
replace educ_level = 2 if inlist(educ_detail, 4, 5)      // Lower secondary (O-Level)
replace educ_level = 3 if inlist(educ_detail, 6, 7)      // Upper secondary (A-Level)
replace educ_level = 4 if educ_detail == 8               // Higher education
label define educ_lbl 0 "No education" 1 "Primary" 2 "Lower secondary"  3 "Upper secondary" 4 "Higher education", replace
label values educ_level educ_lbl


*------------------------------------------------------------------------------
* 3. GEOGRAPHY (rural / other urban / Dar es Salaam)
*------------------------------------------------------------------------------
* Council type comes from the last digit of COUNCIL: 1=DC, 2=TC, 3=MC, 4=CC.
gen byte council_type = mod(COUNCIL, 10)
gen byte area3 = .
replace area3 = 1 if council_type == 1                   // Rural (DC)
replace area3 = 2 if inlist(council_type, 2, 3, 4) & REGION != 7  // Other urban
replace area3 = 3 if REGION == 7                         // Dar es Salaam
label define area3_lbl 1 "Rural" 2 "Other Urban" 3 "Dar es Salaam", replace
label values area3 area3_lbl


*------------------------------------------------------------------------------
* 4. LABOUR FORCE STATUS (employed / unemployed / out of labour force)
*------------------------------------------------------------------------------
* Employed: positive answer to any of Q13A, Q13C-E, Q14A-B, or Q14G.
gen byte employed = 0
replace employed = 1 if inrange(Q13A, 1, 7)
replace employed = 1 if Q13C == 1
replace employed = 1 if Q13D == 1
replace employed = 1 if Q13E == 1
replace employed = 1 if Q14A == 1 | Q14B == 1
replace employed = 1 if inrange(Q14G, 1, 4)
replace employed = . if missing(Q13A) & missing(Q13C) & missing(Q14A) & missing(Q15A)

* Unemployed: not employed, but searched for work in past 4 weeks (Q15A == 1).
gen byte unemployed = (employed == 0 & Q15A == 1)
replace unemployed = . if missing(employed)

* Out of labour force: not employed and not unemployed.
gen byte olf = (employed == 0 & unemployed == 0)
replace olf = . if missing(employed)

gen byte lfs_status = .
replace lfs_status = 1 if employed   == 1
replace lfs_status = 2 if unemployed == 1
replace lfs_status = 3 if olf        == 1
label define lfs_lbl 1 "Employed" 2 "Unemployed" 3 "Out of labour force", replace
label values lfs_status lfs_lbl

* Q15C: reason for not searching (used for gender analysis).
gen byte reason_no_search = Q15C if olf == 1


*------------------------------------------------------------------------------
* 5. EMPLOYMENT TYPE (ICSE-93, 6 categories)
*------------------------------------------------------------------------------
gen byte emp_type = .
replace emp_type = 1 if employed == 1 & Q25 == 1 & Q13C == 1            // Wage employee
replace emp_type = 2 if employed == 1 & inlist(Q25, 2, 3) & Q27A == 1   // Employer (SE w/ employees)
replace emp_type = 3 if employed == 1 & inlist(Q25, 2, 3) & Q27A == 2   // Own-account
replace emp_type = 4 if employed == 1 & inlist(Q25, 4, 5, 7)            // Family worker (CFW)
replace emp_type = 5 if employed == 1 & Q25 == 6                        // Apprentice
replace emp_type = 6 if employed == 1 & Q25 == 1 & Q13C != 1            // Wage absent
label define emp_lbl 1 "Wage" 2 "Employer" 3 "Own-account"  4 "Family worker" 5 "Apprentice" 6 "Wage absent", replace
label values emp_type emp_lbl


*------------------------------------------------------------------------------
* 6. WORK STATUS — 9 categories (CFW kept separate)
*------------------------------------------------------------------------------
* Fills sequentially; later replaces only run if previous left it missing.
gen byte work_status9 = .

* (1) Wage Formal — wage employee with social security (Q34 in {1,3}).
replace work_status9 = 1 if inlist(emp_type, 1, 6) & inlist(Q34, 1, 3)

* (2) Wage Informal Upper — benefits, contract, or upper occupation.
replace work_status9 = 2 if inlist(emp_type, 1, 6) & missing(work_status9) &  (Q30 == 1 | Q31A == 1 | Q31B == 1 | inlist(Q29B, 1, 2) | inrange(Q21B_MAIN_TASCO, 1, 4))

* (3) Wage Informal Lower — residual wage employees + apprentices.
replace work_status9 = 3 if inlist(emp_type, 1, 6) & missing(work_status9)
replace work_status9 = 3 if emp_type == 5

* (4) OA Formal — own-account, registered (Q38A in {1-5}).
replace work_status9 = 4 if emp_type == 3 & inrange(Q38A, 1, 5)

* (5) OA Upper Informal — unregistered own-account with upper occupation.
replace work_status9 = 5 if emp_type == 3 & missing(work_status9) & inrange(Q21B_MAIN_TASCO, 1, 4)

* (6) OA Lower Informal — residual unregistered own-account.
replace work_status9 = 6 if emp_type == 3 & missing(work_status9)

* (7) CFW Informal — contributing family workers (always informal).
replace work_status9 = 7 if emp_type == 4

* (8) Employer Formal — self-employed with employees, registered.
replace work_status9 = 8 if emp_type == 2 & inrange(Q38A, 1, 5)

* (9) Employer Informal Upper — self-employed with employees, unregistered.
replace work_status9 = 9 if emp_type == 2 & missing(work_status9)

label define ws9_lbl  1 "Wage Formal" 2 "Wage Inf. Upper" 3 "Wage Inf. Lower"  4 "OA Formal"   5 "OA Upper Inf."   6 "OA Inf. Lower"  7 "CFW Informal" 8 "Employer Formal" 9 "Employer Inf. Upper", replace
label values work_status9 ws9_lbl


*------------------------------------------------------------------------------
* 7. WORK STATUS — 6 categories (Employer merged into OA, CFW into OA Inf. Lower)
*------------------------------------------------------------------------------
gen byte work_status6 = .
replace work_status6 = 1 if work_status9 == 1                  // Wage formal
replace work_status6 = 2 if work_status9 == 2                  // Wage inf. upper
replace work_status6 = 3 if work_status9 == 3                  // Wage inf. lower
replace work_status6 = 4 if inlist(work_status9, 4, 8)         // OA formal (incl. Employer Formal)
replace work_status6 = 5 if inlist(work_status9, 5, 9)         // OA upper inf. (incl. Employer Inf.)
replace work_status6 = 6 if inlist(work_status9, 6, 7)         // OA inf. lower (incl. CFW)
label define ws6_lbl  1 "Wage formal"     2 "Wage inf. upper" 3 "Wage inf. lower"  4 "OA formal"       5 "OA upper inf."   6 "OA inf. lower", replace
label values work_status6 ws6_lbl


*------------------------------------------------------------------------------
* 8. OTHER INDICATORS
*------------------------------------------------------------------------------
* Online work (Q24).
gen byte online_work = (Q24 == 1) if !missing(Q24) & employed == 1

* Public sector (Q37 in {1,2,3}).
gen byte public_sector = inlist(Q37, 1, 2, 3) if !missing(Q37) & employed == 1

* Secondary activity flag.
gen byte has_secondary = (Q20 == 1 | Q48A == 1 | Q48B == 1) if employed == 1

* Non-wage flag (used for credit analysis).
gen byte is_nonwage = inlist(emp_type, 2, 3, 4, 5)

* Q47A credit access (asked of non-wage workers).
gen byte credit_q47a = (Q47A == 1) if is_nonwage == 1 & !missing(Q47A)

* Manufacturing 2-digit ISIC (top-level ISIC code 3).
gen int manuf2 = floor(Q22B_DETAILS_ISIC / 100) if Q22B_MAIN_ISIC == 3

* Hours worked total.
gen int hours_total = Q78A_SUM if employed == 1


*------------------------------------------------------------------------------
* 9. RESTRICT SAMPLE (working-age, valid LFS)
*------------------------------------------------------------------------------
keep if Q06B_MEM_AGE >= 15 & !missing(lfs_status)


*------------------------------------------------------------------------------
* 10. SURVEY WEIGHTS
*------------------------------------------------------------------------------
svyset [pw=WEIGHT]


*------------------------------------------------------------------------------
* 11. EXPORT TABLES — one workbook, many sheets
*------------------------------------------------------------------------------
* Each sub-section writes one sheet using putexcel. The first sheet
* uses replace; later ones use modify to append to the same workbook.
* Layout convention:
*   Row 1 = sheet title
*   Row 2 = column headers
*   From row 3 = data, with row labels in column A.

* ----- Sheet 1: LFS_Summary --------------------------------------------------
putexcel set "$out_xlsx", sheet("LFS_Summary") replace
putexcel A1 = "LFS status by gender — weighted % (working-age 15+)"
putexcel A2 = "LFS status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues s = 1/3 {
    qui count if lfs_status == `s'
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (lfs_status == `s')
    qui svy: mean __mi, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    capture drop __mi
    qui gen byte __mi = (lfs_status == `s')
    qui svy: mean __mi
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label lfs_lbl `s'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 2: WorkStatus6_x_Gender (Figure 5 / Figure 12) ------------------
putexcel set "$out_xlsx", sheet("WorkStatus6_x_Gender") modify
putexcel A1 = "Work status (6-cat) by gender — weighted % of employed"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues w = 1/6 {
    qui count if work_status6 == `w' & employed == 1
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1): mean __mi, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1): mean __mi
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 3: WorkStatus6_Composition (Figure 3) ---------------------------
putexcel set "$out_xlsx", sheet("WorkStatus6_Composition") modify
putexcel A1 = "Work status composition (6-cat) — weighted % of employed"
putexcel A2 = "Work status" B2 = "% Total" C2 = "N"

local row = 3
forvalues w = 1/6 {
    qui count if work_status6 == `w' & employed == 1
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1): mean __mi
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pt' C`row' = `n'
    local ++row
}

* ----- Sheet 4: WorkStatus9_x_Gender (CFW separate, used for sector tables) --
putexcel set "$out_xlsx", sheet("WorkStatus9_x_Gender") modify
putexcel A1 = "Work status (9-cat, CFW separate) by gender — weighted %"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues w = 1/9 {
    qui count if work_status9 == `w' & employed == 1
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (work_status9 == `w')
    qui svy, subpop(if employed == 1): mean __mi, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    capture drop __mi
    qui gen byte __mi = (work_status9 == `w')
    qui svy, subpop(if employed == 1): mean __mi
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws9_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 5: Education_x_Gender (Figure 6) --------------------------------
putexcel set "$out_xlsx", sheet("Education_x_Gender") modify
putexcel A1 = "Education by sex — weighted % (working-age 15+)"
putexcel A2 = "Education level" B2 = "Male %" C2 = "Female %" D2 = "N"

local row = 3
forvalues e = 0/4 {
    qui count if educ_level == `e'
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (educ_level == `e')
    qui svy: mean __mi, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    local lab : label educ_lbl `e'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `n'
    local ++row
}

* ----- Sheet 6: Education_x_WS_Gender (Figure 7) -----------------------------
* Education distribution within each (work_status6 × gender) cell.
putexcel set "$out_xlsx", sheet("Education_x_WS_Gender") modify
putexcel A1 = "Education distribution by work status (6-cat) and gender — row %"
putexcel A2 = "Work status" B2 = "Gender" C2 = "No education"  D2 = "Primary" E2 = "Lower secondary" F2 = "Upper secondary"  G2 = "Higher education" H2 = "N"

local row = 3
forvalues w = 1/6 {
    forvalues g = 0/1 {
        qui count if work_status6 == `w' & female == `g' & employed == 1
        local n = r(N)
        local lab_w : label ws6_lbl `w'
        local lab_g : label female_lbl `g'
        putexcel A`row' = "`lab_w'" B`row' = "`lab_g'" H`row' = `n'
        local col = 3
        forvalues e = 0/4 {
            capture drop __mi
            qui gen byte __mi = (educ_level == `e')
            qui svy, subpop(if work_status6 == `w' & female == `g' & employed == 1):  mean __mi
            matrix T = e(b)
            local p = 100 * T[1, 1]
            local clet = char(64 + `col')
            putexcel `clet'`row' = `p'
            local ++col
        }
        local ++row
    }
}

* ----- Sheet 7: Education_x_WS_Gender_Youth (Figure 7-2) ---------------------
putexcel set "$out_xlsx", sheet("Education_x_WS_Gender_Youth") modify
putexcel A1 = "Education by work status (6-cat) and gender — youth (15-24) only"
putexcel A2 = "Work status" B2 = "Gender" C2 = "No education"  D2 = "Primary" E2 = "Lower secondary" F2 = "Upper secondary"  G2 = "Higher education" H2 = "N"

local row = 3
forvalues w = 1/6 {
    forvalues g = 0/1 {
        qui count if work_status6 == `w' & female == `g' & employed == 1 & youth == 1
        local n = r(N)
        local lab_w : label ws6_lbl `w'
        local lab_g : label female_lbl `g'
        putexcel A`row' = "`lab_w'" B`row' = "`lab_g'" H`row' = `n'
        local col = 3
        forvalues e = 0/4 {
            capture drop __mi
            qui gen byte __mi = (educ_level == `e')
            capture qui svy, subpop(if work_status6 == `w' & female == `g' & employed == 1 & youth == 1):  mean __mi
            if !_rc {
                matrix T = e(b)
                local p = 100 * T[1, 1]
                local clet = char(64 + `col')
                putexcel `clet'`row' = `p'
            }
            local ++col
        }
        local ++row
    }
}

* ----- Sheet 8: WorkStatus6_Youth (Figure 8) ---------------------------------
putexcel set "$out_xlsx", sheet("WorkStatus6_Youth") modify
putexcel A1 = "Work status (6-cat) for youth (15-24) by gender — weighted %"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "N"

local row = 3
forvalues w = 1/6 {
    qui count if work_status6 == `w' & employed == 1 & youth == 1
    local n = r(N)
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1 & youth == 1): mean __mi, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `n'
    local ++row
}

* ----- Sheet 9: Q15C_Reasons (Figure 9 — full 17 codes) ----------------------
putexcel set "$out_xlsx", sheet("Q15C_Reasons") modify
putexcel A1 = "Q15C: Reasons for not searching for work — weighted % of OLF"
putexcel A2 = "Code" B2 = "Reason" C2 = "Male %" D2 = "Female %" E2 = "Total %" F2 = "N"

local row = 3
forvalues c = 1/17 {
    qui count if reason_no_search == `c'
    local n = r(N)
    if `n' > 0 {
        capture drop __mi
        qui gen byte __mi = (reason_no_search == `c')
        qui svy, subpop(if olf == 1): mean __mi, over(female)
        matrix M = e(b)
        local pm = 100 * M[1, 1]
        local pf = 100 * M[1, 2]
        capture drop __mi
        qui gen byte __mi = (reason_no_search == `c')
        qui svy, subpop(if olf == 1): mean __mi
        matrix T = e(b)
        local pt = 100 * T[1, 1]
        local lab : label (Q15C) `c'
        putexcel A`row' = `c' B`row' = "`lab'" C`row' = `pm' D`row' = `pf' E`row' = `pt' F`row' = `n'
        local ++row
    }
}

* ----- Sheet 10: Online_Work (Figure 14-2) -----------------------------------
putexcel set "$out_xlsx", sheet("Online_Work") modify
putexcel A1 = "Q24: Online work by work status (6-cat) and gender — weighted %"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues w = 1/6 {
    qui count if work_status6 == `w' & !missing(online_work)
    local n = r(N)
    qui svy, subpop(if work_status6 == `w'): mean online_work, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    qui svy, subpop(if work_status6 == `w'): mean online_work
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 11: Education_FormalUpper (Figure 15) ---------------------------
* Education distribution for formal + upper informal categories.
putexcel set "$out_xlsx", sheet("Education_FormalUpper") modify
putexcel A1 = "Education by formal & upper informal work status — weighted %"
putexcel A2 = "Work status" B2 = "No education" C2 = "Primary"  D2 = "Lower secondary" E2 = "Upper secondary" F2 = "Higher education" G2 = "N"

local row = 3
foreach w in 1 2 4 5 {
    qui count if work_status6 == `w' & employed == 1
    local n = r(N)
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" G`row' = `n'
    local col = 2
    forvalues e = 0/4 {
        capture drop __mi
        qui gen byte __mi = (educ_level == `e')
        qui svy, subpop(if work_status6 == `w'): mean __mi
        matrix T = e(b)
        local p = 100 * T[1, 1]
        local clet = char(64 + `col')
        putexcel `clet'`row' = `p'
        local ++col
    }
    local ++row
}

* ----- Sheet 12: Sector_x_WS6 (Figure 16) ------------------------------------
* ISIC 1-digit (Q22B_MAIN_ISIC) cross work_status6 — column %.
putexcel set "$out_xlsx", sheet("Sector_x_WS6") modify
putexcel A1 = "ISIC 1-digit sector × work status (6-cat) — column % of work status"
putexcel A2 = "Sector"
local col = 2
forvalues w = 1/6 {
    local lab : label ws6_lbl `w'
    local clet = char(64 + `col')
    putexcel `clet'2 = "`lab'"
    local ++col
}
putexcel H2 = "N (sector)"

levelsof Q22B_MAIN_ISIC if employed == 1, local(secs)
local row = 3
foreach s of local secs {
    qui count if Q22B_MAIN_ISIC == `s' & employed == 1
    local n = r(N)
    local lab : label (Q22B_MAIN_ISIC) `s'
    putexcel A`row' = "`lab'" H`row' = `n'
    local col = 2
    forvalues w = 1/6 {
        capture drop __mi
        qui gen byte __mi = (Q22B_MAIN_ISIC == `s')
        capture qui svy, subpop(if work_status6 == `w' & employed == 1): mean __mi
        if !_rc {
            matrix T = e(b)
            local p = 100 * T[1, 1]
            local clet = char(64 + `col')
            putexcel `clet'`row' = `p'
        }
        local ++col
    }
    local ++row
}

* ----- Sheet 13: Manufacturing_x_WS6 (Figure 17) -----------------------------
* Manufacturing 2-digit ISIC × work_status6 — row %.
putexcel set "$out_xlsx", sheet("Manufacturing_x_WS6") modify
putexcel A1 = "Manufacturing 2-digit ISIC by work status (6-cat) — row %"
putexcel A2 = "ISIC 2-digit"
local col = 2
forvalues w = 1/6 {
    local lab : label ws6_lbl `w'
    local clet = char(64 + `col')
    putexcel `clet'2 = "`lab'"
    local ++col
}
putexcel H2 = "N"

levelsof manuf2 if !missing(manuf2), local(mlist)
local row = 3
foreach m of local mlist {
    qui count if manuf2 == `m' & employed == 1
    local n = r(N)
    if `n' >= 30 {
        putexcel A`row' = `m' H`row' = `n'
        local col = 2
        forvalues w = 1/6 {
            capture drop __mi
            qui gen byte __mi = (work_status6 == `w')
            capture qui svy, subpop(if manuf2 == `m'): mean __mi
            if !_rc {
                matrix T = e(b)
                local p = 100 * T[1, 1]
                local clet = char(64 + `col')
                putexcel `clet'`row' = `p'
            }
            local ++col
        }
        local ++row
    }
}

* ----- Sheet 14: Secondary_x_WS_Gender (Figure 27) ---------------------------
putexcel set "$out_xlsx", sheet("Secondary_x_WS_Gender") modify
putexcel A1 = "Secondary activity by work status (6-cat) and gender — weighted %"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues w = 1/6 {
    qui count if work_status6 == `w' & !missing(has_secondary)
    local n = r(N)
    qui svy, subpop(if work_status6 == `w'): mean has_secondary, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    qui svy, subpop(if work_status6 == `w'): mean has_secondary
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 15: Secondary_x_Location (Fig 27b) ------------------------------
putexcel set "$out_xlsx", sheet("Secondary_x_Location") modify
putexcel A1 = "Secondary activity by location and gender — weighted %"
putexcel A2 = "Location" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
forvalues a = 1/3 {
    qui count if area3 == `a' & !missing(has_secondary)
    local n = r(N)
    qui svy, subpop(if area3 == `a' & employed == 1): mean has_secondary, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    qui svy, subpop(if area3 == `a' & employed == 1): mean has_secondary
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label area3_lbl `a'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 16: WS6_x_Location (Figure 29) ----------------------------------
* Column = location, row = work_status6, percentages within location.
putexcel set "$out_xlsx", sheet("WS6_x_Location") modify
putexcel A1 = "Work status (6-cat) composition by location — column %"
putexcel A2 = "Work status" B2 = "Rural %" C2 = "Other Urban %" D2 = "Dar %" E2 = "All TZ %"

local row = 3
forvalues w = 1/6 {
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'"
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1): mean __mi, over(area3)
    matrix M = e(b)
    putexcel B`row' = (100*M[1,1]) C`row' = (100*M[1,2]) D`row' = (100*M[1,3])
    capture drop __mi
    qui gen byte __mi = (work_status6 == `w')
    qui svy, subpop(if employed == 1): mean __mi
    matrix T = e(b)
    putexcel E`row' = (100*T[1,1])
    local ++row
}

* ----- Sheet 17: Hours_x_Location_Quarter (Figure 31) ------------------------
putexcel set "$out_xlsx", sheet("Hours_x_Location_Quarter") modify
putexcel A1 = "Mean hours worked (Q78A) by location, quarter and gender"
putexcel A2 = "Location" B2 = "Quarter" C2 = "Male mean" D2 = "Female mean" E2 = "Total mean" F2 = "N"

local row = 3
forvalues a = 1/3 {
    forvalues q = 1/4 {
        qui count if area3 == `a' & QTR == `q' & employed == 1 & !missing(hours_total)
        local n = r(N)
        if `n' > 0 {
            qui svy, subpop(if area3 == `a' & QTR == `q' & employed == 1): mean hours_total, over(female)
            matrix M = e(b)
            local mm = M[1, 1]
            local mf = M[1, 2]
            qui svy, subpop(if area3 == `a' & QTR == `q' & employed == 1): mean hours_total
            matrix T = e(b)
            local mt = T[1, 1]
            local lab : label area3_lbl `a'
            putexcel A`row' = "`lab'" B`row' = `q' C`row' = `mm' D`row' = `mf' E`row' = `mt' F`row' = `n'
        }
        local ++row
    }
}

* ----- Sheet 18: Q45B_Reasons_x_WS6 (Figure 23) ------------------------------
* Q45B is multi-response (A through M). Each option recorded as its own variable.
putexcel set "$out_xlsx", sheet("Q45B_Reasons_x_WS6") modify
putexcel A1 = "Q45B: reasons for choice of business by work status (6-cat) — % responding yes"
putexcel A2 = "Reason"
local col = 2
forvalues w = 1/6 {
    local lab : label ws6_lbl `w'
    local clet = char(64 + `col')
    putexcel `clet'2 = "`lab'"
    local ++col
}
putexcel H2 = "All non-wage %"

local row = 3
local letters A B C D E F G H I J K L M
local labA "Unable to find another job"
local labB "Dismissed/reduced hours"
local labC "Retirement"
local labD "Family needs additional income"
local labE "Good income opportunities"
local labF "Low start-up capital required"
local labG "Can reduce production costs"
local labH "Wants to be independent"
local labI "Choice of working time/location"
local labJ "Combine with family responsibilities"
local labK "Avoid bureaucracy of formalising"
local labL "Traditional family business"
local labM "Other"

foreach v of local letters {
    capture confirm variable Q45B`v'
    if !_rc {
        local lbl `lab`v''
        putexcel A`row' = "`lbl'"
        local col = 2
        forvalues w = 1/6 {
            capture drop __mi
            qui gen byte __mi = (Q45B`v' == 1)
            capture qui svy, subpop(if work_status6 == `w' & is_nonwage == 1): mean __mi
            if !_rc {
                matrix T = e(b)
                local p = 100 * T[1, 1]
                local clet = char(64 + `col')
                putexcel `clet'`row' = `p'
            }
            local ++col
        }
        capture drop __mi
        qui gen byte __mi = (Q45B`v' == 1)
        capture qui svy, subpop(if is_nonwage == 1): mean __mi
        if !_rc {
            matrix T = e(b)
            local pt = 100 * T[1, 1]
            putexcel H`row' = `pt'
        }
        local ++row
    }
}

* ----- Sheet 19: Q47A_Credit_x_Sector (Figure 24) ----------------------------
* Top-5 sectors plus "All other sectors" plus overall.
putexcel set "$out_xlsx", sheet("Q47A_Credit_x_Sector") modify
putexcel A1 = "Q47A: Received any loan/credit (last 12 months) by sector and sex"
putexcel A2 = "Sector" B2 = "N" C2 = "Male %" D2 = "Female %"

local secs 1 3 6 7 9
local row = 3
foreach s of local secs {
    qui count if Q22B_MAIN_ISIC == `s' & is_nonwage == 1 & !missing(credit_q47a)
    local n = r(N)
    qui svy, subpop(if Q22B_MAIN_ISIC == `s' & is_nonwage == 1): mean credit_q47a, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    local lab : label (Q22B_MAIN_ISIC) `s'
    putexcel A`row' = "`lab'" B`row' = `n' C`row' = `pm' D`row' = `pf'
    local ++row
}

* All other sectors
qui count if !inlist(Q22B_MAIN_ISIC, 1, 3, 6, 7, 9) & is_nonwage == 1 & !missing(credit_q47a)
local n = r(N)
qui svy, subpop(if !inlist(Q22B_MAIN_ISIC, 1, 3, 6, 7, 9) & is_nonwage == 1): mean credit_q47a, over(female)
matrix M = e(b)
putexcel A`row' = "All other sectors" B`row' = `n' C`row' = (100*M[1,1]) D`row' = (100*M[1,2])
local ++row

* Overall
qui count if is_nonwage == 1 & !missing(credit_q47a)
local n = r(N)
qui svy, subpop(if is_nonwage == 1): mean credit_q47a, over(female)
matrix M = e(b)
putexcel A`row' = "Overall (non-wage)" B`row' = `n' C`row' = (100*M[1,1]) D`row' = (100*M[1,2])

* ----- Sheet 20: Q47A_Credit_x_WS6 (Credit Q47A — OA only) -------------------
putexcel set "$out_xlsx", sheet("Q47A_Credit_x_WS6") modify
putexcel A1 = "Q47A: Received any loan/credit by work status — OA categories only"
putexcel A2 = "Work status" B2 = "Male %" C2 = "Female %" D2 = "Total %" E2 = "N"

local row = 3
foreach w in 4 5 6 {     // OA formal, OA upper inf., OA inf. lower
    qui count if work_status6 == `w' & is_nonwage == 1 & !missing(credit_q47a)
    local n = r(N)
    qui svy, subpop(if work_status6 == `w' & is_nonwage == 1): mean credit_q47a, over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    qui svy, subpop(if work_status6 == `w' & is_nonwage == 1): mean credit_q47a
    matrix T = e(b)
    local pt = 100 * T[1, 1]
    local lab : label ws6_lbl `w'
    putexcel A`row' = "`lab'" B`row' = `pm' C`row' = `pf' D`row' = `pt' E`row' = `n'
    local ++row
}

* ----- Sheet 21: Q47B_Source_x_Gender (Figure 25) ----------------------------
* Q47B is a multi-letter string; each letter = one credit source.
putexcel set "$out_xlsx", sheet("Q47B_Source_x_Gender") modify
putexcel A1 = "Q47B: Credit source by sex — % of credit recipients selecting each source"
putexcel A2 = "Source code" B2 = "Source label" C2 = "Male %" D2 = "Female %"

local letters A B C D E F G H I J K L M
local lab_A "Bank"
local lab_B "Microfinance institution"
local lab_C "SACCOS / Cooperatives"
local lab_D "VICOBA / Village savings groups"
local lab_E "Mobile money lender"
local lab_F "Government scheme / programme"
local lab_G "NGO"
local lab_H "Employer"
local lab_I "Family / friends"
local lab_J "Money lender"
local lab_K "Supplier credit"
local lab_L "Other formal"
local lab_M "Other informal"

local row = 3
foreach v of local letters {
    gen byte _src_`v' = (strpos(Q47B, "`v'") > 0) if !missing(Q47B)
    qui svy, subpop(if credit_q47a == 1): mean _src_`v', over(female)
    matrix M = e(b)
    local pm = 100 * M[1, 1]
    local pf = 100 * M[1, 2]
    local lbl `lab_`v''
    putexcel A`row' = "`v'" B`row' = "`lbl'" C`row' = `pm' D`row' = `pf'
    local ++row
    drop _src_`v'
}

* ----- Sheet 22: Q47B_Source_x_WS6 -------------------------------------------
putexcel set "$out_xlsx", sheet("Q47B_Source_x_WS6") modify
putexcel A1 = "Q47B: Credit source by work status (6-cat) — % of credit recipients"
putexcel A2 = "Source"
local col = 2
forvalues w = 1/6 {
    local lab : label ws6_lbl `w'
    local clet = char(64 + `col')
    putexcel `clet'2 = "`lab'"
    local ++col
}

local letters A B C D E F G H I J K L M
local row = 3
foreach v of local letters {
    gen byte _src_`v' = (strpos(Q47B, "`v'") > 0) if !missing(Q47B)
    local lbl `lab_`v''
    putexcel A`row' = "`v' — `lbl'"
    local col = 2
    forvalues w = 1/6 {
        capture qui svy, subpop(if work_status6 == `w' & credit_q47a == 1): mean _src_`v'
        if !_rc {
            matrix T = e(b)
            local p = 100 * T[1, 1]
            local clet = char(64 + `col')
            putexcel `clet'`row' = `p'
        }
        local ++col
    }
    drop _src_`v'
    local ++row
}

* ----- Sheet 23: README ------------------------------------------------------
putexcel set "$out_xlsx", sheet("README") modify
putexcel A1 = "polished_graphs_data.xlsx — sheet index"
putexcel A3 = "Sample" B3 = "Working-age 15+ with non-missing LFS status"
putexcel A4 = "Weights" B4 = "WEIGHT (svyset [pw=WEIGHT])"
putexcel A5 = "Source" B5 = "do/setup_vars.do"

putexcel A7 = "Sheet" B7 = "Description"
putexcel A8  = "LFS_Summary"                  B8  = "LFS status (employed/unemp/OLF) by gender"
putexcel A9  = "WorkStatus6_x_Gender"         B9  = "Work status (6-cat) by gender"
putexcel A10 = "WorkStatus6_Composition"      B10 = "Work status (6-cat) overall composition"
putexcel A11 = "WorkStatus9_x_Gender"         B11 = "Work status (9-cat, CFW separate) by gender"
putexcel A12 = "Education_x_Gender"           B12 = "Education level by sex (Fig 6)"
putexcel A13 = "Education_x_WS_Gender"        B13 = "Education by work status × gender (Fig 7)"
putexcel A14 = "Education_x_WS_Gender_Youth"  B14 = "As above, youth (15-24) only (Fig 7-2)"
putexcel A15 = "WorkStatus6_Youth"            B15 = "Work status for youth by gender (Fig 8)"
putexcel A16 = "Q15C_Reasons"                 B16 = "Reasons for not searching for work (Fig 9)"
putexcel A17 = "Online_Work"                  B17 = "Q24 online work by work status & gender (Fig 14-2)"
putexcel A18 = "Education_FormalUpper"        B18 = "Education for formal & upper-informal (Fig 15)"
putexcel A19 = "Sector_x_WS6"                 B19 = "ISIC 1-digit by work status (Fig 16)"
putexcel A20 = "Manufacturing_x_WS6"          B20 = "Manufacturing 2-digit by work status (Fig 17)"
putexcel A21 = "Secondary_x_WS_Gender"        B21 = "Secondary activity by work status & gender (Fig 27)"
putexcel A22 = "Secondary_x_Location"         B22 = "Secondary activity by location & gender (Fig 27b)"
putexcel A23 = "WS6_x_Location"               B23 = "Work status by location (Fig 29)"
putexcel A24 = "Hours_x_Location_Quarter"     B24 = "Hours worked by location, quarter and gender (Fig 31)"
putexcel A25 = "Q45B_Reasons_x_WS6"           B25 = "Q45B reasons for starting business (Fig 23)"
putexcel A26 = "Q47A_Credit_x_Sector"         B26 = "Q47A credit access by sector × sex (Fig 24)"
putexcel A27 = "Q47A_Credit_x_WS6"            B27 = "Q47A credit access by work status (OA only)"
putexcel A28 = "Q47B_Source_x_Gender"         B28 = "Q47B credit source by sex (Fig 25)"
putexcel A29 = "Q47B_Source_x_WS6"            B29 = "Q47B credit source by work status"

