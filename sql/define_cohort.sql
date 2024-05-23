USE cprd2023;

/*
*/
# Drop table if exists
DROP TABLE IF EXISTS aurum_practices_2023_12;

# Create practice table
CREATE TABLE IF NOT EXISTS aurum_practices_2023_12 (
        pracid INT PRIMARY KEY,
        lcd DATE,
        uts DATE,
        region INT
    );

# Load file
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/cprd_files/202312_CPRDAurum/202312_CPRDAurum_Practices.txt'
    INTO TABLE aurum_practices_2023_12
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (@pracid, @lcd, @uts, @region)
    SET
    	pracid = NULLIF(@pracid,''),
    	lcd = NULLIF(STR_TO_DATE(@lcd, '%d/%m/%Y'), '0000-00-00'),
        uts = NULLIF(STR_TO_DATE(@uts, '%d/%m/%Y'), '0000-00-00'),
        region = NULLIF(@region,'');
        
SELECT * 
FROM aurum_practices_2023_12
LIMIT 10;

/* Identify base population for IND2023-165 and IND2023-166
The denominator is every person who, on 31st March 2023 (the end date), meets the following inclusion criteria: 
•	Aged 43 to 84
•	Registered at a CPRD-contributing practice,
*/
DROP TABLE IF EXISTS p068_cohort_43_84;

CREATE TABLE p068_cohort_43_84 (
	SELECT patid, gender, regstartdate, regenddate, pracid, cprd_ddate, mock_yob AS yob, age 
	FROM ( -- Calculate age at 2023-03-31 (end/achievement date)
		SELECT *, TIMESTAMPDIFF(YEAR, mock_yob, '2023-03-31') AS age 
		FROM ( -- Get approximate date of birth using July 1st of year of birth
			SELECT *, STR_TO_DATE(CONCAT(yob, "-07-01"), "%Y-%m-%d") AS mock_yob 
            -- Join with patient info 
			FROM acceptable_pats_2023_12 AS t1
			) AS t2
		) AS t3
	WHERE age BETWEEN 43 AND 84
	AND (regenddate IS NULL OR regenddate > "2023-03-31")
    AND (cprd_ddate IS NULL OR cprd_ddate > "2023-03-31")
	AND pracid NOT IN ( -- Not in absorbed practices
		SELECT pracid
		FROM absorbed_practices_2023_12)
	AND pracid IN ( -- last collection date for practice after 
		SELECT pracid
		FROM aurum_practices_2023_12
		WHERE lcd > "2023-03-31")	
);
    
SELECT COUNT(DISTINCT patid) -- 6691383
FROM p068_cohort_43_84;

SELECT MIN(regenddate), MIN(age), MAX(age)
FROM p068_cohort_43_84;

SELECT *
FROM p068_cohort_43_84
LIMIT 10;

/* Identify cohort for IND2023-164
For IND2023-164, the denominator is every person who meets the following inclusion criteria on 31st March 2023 (the end date):
•	Aged 45 to 84 
•	Registered at a CPRD-contributing practice 
*/

DROP TABLE IF EXISTS p068_cohort_45_84;

CREATE TABLE p068_cohort_45_84
	SELECT *
    FROM p068_cohort_43_84
    WHERE age BETWEEN 45 AND 84;
    
SELECT COUNT(DISTINCT patid) -- 6258481
FROM p068_cohort_45_84;

SELECT MIN(regenddate), MIN(age), MAX(age)
FROM p068_cohort_45_84;

SELECT *
FROM p068_cohort_45_84
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

-- Number of practices
SELECT COUNT(DISTINCT pracid)
FROM p068_cohort_43_84; -- 1609

SELECT COUNT(DISTINCT pracid)
FROM p068_cohort_45_84; -- 1609