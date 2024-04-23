USE cprd2023;

/* Identify cohort for IND2023-164
For IND2023-164, the denominator is every person who meets the following inclusion criteria on 31st March 2023 (the end date):
•	Aged 45 to 84 
•	Registered at a CPRD-contributing practice 
*/

DROP TABLE IF EXISTS p068_cohort_45_84;

CREATE TABLE p068_cohort_45_84 (
	SELECT patid, gender, regstartdate, regenddate, pracid, mock_yob AS yob, age 
	FROM ( -- Calculate age at 2023-03-31 (end/achievement date)
		SELECT *, TIMESTAMPDIFF(YEAR, mock_yob, '2023-03-31') AS age 
		FROM ( -- Get approximate date of birth using July 1st of year of birth
			SELECT *, STR_TO_DATE(CONCAT(yob, "-07-01"), "%Y-%m-%d") AS mock_yob 
			FROM ( -- Join with patient info 
				SELECT patid, gender, yob, regstartdate, regenddate, pracid
				FROM acceptable_pats_2023_12
				) AS t1
			) AS t2
		) AS t3
	WHERE age BETWEEN 45 AND 84
	AND (regenddate IS NULL OR regenddate > "2023-03-31")
	AND pracid NOT IN ( -- Not in absorbed practices
		SELECT pracid
		FROM absorbed_practices_2023_12)
);
    
SELECT COUNT(DISTINCT patid) -- 6659529
FROM p068_cohort_45_84;

SELECT MIN(regenddate), MIN(age), MAX(age)
FROM p068_cohort_45_84;

SELECT *
FROM p068_cohort_45_84
LIMIT 10;

/* Identify base population for IND2023-165 and IND2023-166
The denominator is every person who, on 31st March 2023 (the end date), meets the following inclusion criteria: 
•	Aged 43 to 84
•	Registered at a CPRD-contributing practice,
*/
DROP TABLE IF EXISTS p068_cohort_43_84;

CREATE TABLE p068_cohort_43_84 (
	SELECT patid, gender, regstartdate, regenddate, pracid, mock_yob AS yob, age 
	FROM ( -- Calculate age at 2023-03-31 (end/achievement date)
		SELECT *, TIMESTAMPDIFF(YEAR, mock_yob, '2023-03-31') AS age 
		FROM ( -- Get approximate date of birth using July 1st of year of birth
			SELECT *, STR_TO_DATE(CONCAT(yob, "-07-01"), "%Y-%m-%d") AS mock_yob 
			FROM ( -- Join with patient info 
				SELECT patid, gender, yob, regstartdate, regenddate, pracid
				FROM acceptable_pats_2023_12
				) AS t1
			) AS t2
		) AS t3
	WHERE age BETWEEN 43 AND 84
	AND (regenddate IS NULL OR regenddate > "2023-03-31")
	AND pracid NOT IN ( -- Not in absorbed practices
		SELECT pracid
		FROM absorbed_practices_2023_12)
);
    
SELECT COUNT(DISTINCT patid) -- 7114713
FROM p068_cohort_43_84;

SELECT MIN(regenddate), MIN(age), MAX(age)
FROM p068_cohort_43_84;

SELECT *
FROM p068_cohort_43_84
LIMIT 10;

/* Check if all patients in p068_cohort_45_84 are in p068_cohort_43_84 */

SELECT COUNT(*)
FROM p068_cohort_45_84; -- 6659529

-- Returns 6659529, same as number of rows = All good
WITH t AS (
	SELECT t1.patid, t2.marker_43_84
	FROM p068_cohort_45_84 AS t1
	LEFT JOIN (
		SELECT patid, 
			"t2" AS marker_43_84 -- dummy column
		FROM p068_cohort_43_84
	) AS t2 ON t1.patid = t2.patid
)
SELECT COUNT(marker_43_84)
FROM t;

/* Save cohort for extraction*/
SELECT *
FROM p068_cohort_43_84
LIMIT 1000000 OFFSET 3000000;

/* Get patients eligible for IMD linkage */
SELECT *
FROM linkage_eligibility_2022_01
LIMIT 10;

-- Patients are eligible for inclusion if ALL the following criteria are satisfied:
-- - they are registered with a practice which has consented to participate in the CPRD patient-level
-- 	linkage scheme. Currently the linkage scheme is restricted to practices in England.
-- - the patient has no record indicating dissent from the transmission of personal confidential data to
-- 	NHS Digital, formerly known as the Health and Social Care Information Centre (HSCIC).
-- a full postcode of residence is recorded for the patient in the primary care data and has a valid format.

--  [lsoa_e]: this flag is set to 1 if the patient if eligible for inclusion 
-- in linkages based on patient postcode of residence 
-- (based on eligibility criteria above), and 0 otherwise
DROP TABLE IF EXISTS p068_cohort_43_84_lsoa;

CREATE TABLE p068_cohort_43_84_lsoa (
	SELECT j.patid,
		j.lsoa_e
	FROM (
		SELECT t.*,
			e.lsoa_e,
			e.linkdate
		FROM p068_cohort_43_84 AS t
		LEFT JOIN linkage_eligibility_2022_01 AS e ON t.patid = e.patid
		) AS j
	WHERE j.lsoa_e = 1
);

SELECT *
FROM p068_cohort_43_84_lsoa
LIMIT 10;

SELECT COUNT(*)
FROM p068_cohort_43_84_lsoa; -- 5247298

-- Proportion with lsoa for 43-84 cohort
-- SELECT 5247298/7114713; 
-- 0.7375

SELECT COUNT(*)
FROM p068_cohort_43_84_lsoa
WHERE patid IN (SELECT patid FROM p068_cohort_45_84);

SELECT COUNT(*)
FROM p068_cohort_45_84;

-- Proportion with lsoa for 45-84 cohort
-- SELECT 4927552/6659529; 
-- 0.7399

-- Look at distribution of linkdate
-- All 2021-04-05
-- SELECT MIN(linkdate), MAX(linkdate)
-- FROM p068_cohort_45_84_lsoa;

SELECT *
FROM p068_cohort_43_84_lsoa;