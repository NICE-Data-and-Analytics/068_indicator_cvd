USE cprd2023;

SHOW TABLES;

/* ---------------------------------------------------------------------------------------------------*/
/* Define lupus population */

-- Get count of obstype
SELECT obstypeid, COUNT(*) AS count
FROM p068_slupus_define
GROUP BY obstypeid
ORDER BY count DESC;

-- Filter for observation records for SLE only as want the diagnosis
-- Join with patient info
-- Calculate rough date of birth and age at achievement date
-- Filter for those aged 43 to 84 at achievement date
-- Filter for those still registered at achievement date

DROP TEMPORARY TABLE IF EXISTS p068_slupus_pop;

CREATE TEMPORARY TABLE p068_slupus_pop
SELECT * 
FROM ( -- Calculate age at 2023-03-31 (end/achievement date)
	SELECT *, TIMESTAMPDIFF(YEAR, mock_yob, '2023-03-31') AS age 
    FROM ( -- Get approximate date of birth using July 1st of year of birth
		SELECT *, STR_TO_DATE(CONCAT(yob, "-07-01"), "%Y-%m-%d") AS mock_yob 
		FROM ( -- Join with patient info 
			SELECT d.*, p.gender, p.yob, p.regstartdate, p.regenddate
			FROM ( -- Filter for observation records only
				SELECT *
				FROM p068_slupus_define
				WHERE obstypeid = 7
				) AS d
			LEFT JOIN acceptable_pats_2023_12 AS p ON d.patid = p.patid
			) AS t1
        ) AS t2
	) AS t3
WHERE age BETWEEN 43 AND 84
AND (regenddate IS NULL OR regenddate > "2023-03-31")
AND pracid NOT IN (
	SELECT pracid
	FROM absorbed_practices_2023_12);
    
-- Check data
SELECT *
FROM p068_slupus_pop
LIMIT 20;

SELECT MIN(age), MAX(age), MIN(regenddate)
FROM p068_slupus_pop;

SELECT obstypeid, COUNT(*)
FROM p068_slupus_pop
GROUP BY obstypeid;

-- Count number of patients
SELECT COUNT(DISTINCT(patid))
FROM p068_slupus_pop; -- 11865

-- Get most recent record for each patient so left with one record per patient
DROP TABLE IF EXISTS p068_slupus_latest_record;

CREATE TABLE p068_slupus_latest_record AS
WITH s AS (
  SELECT t.*, ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
  FROM p068_slupus_pop AS t
)
SELECT 
	s.patid,
    s.gender,
    s.age AS age_achdate,
    s.obsdate AS slupus_obsdate,
    s.medcodeid AS slupus_medcodeid,
    d.term AS slupus_medcodeid_term
FROM s 
LEFT JOIN (-- Join to get term for medcodeid
	SELECT medcodeid, term
    FROM medcodeid_aurum_202312
	) AS d ON s.medcodeid = d.medcodeid
WHERE rn = 1;

SELECT *
FROM p068_slupus_latest_record
LIMIT 10;

-- Check number of patients hasn't changed and that only one record per patient
SELECT COUNT(*), COUNT(DISTINCT(patid))
FROM p068_slupus_latest_record;

/* ---------------------------------------------------------------------------------------------------*/
/* Save CVD risk assessments between 2018-04-01 and 2023-03-31 separately */

-- Keep only records which are of obstype value, observation, document or investigation
-- Filter for records between 2018-04-01 and 2023-03-31
-- Keep most recent record per patient
DROP TABLE IF EXISTS p068_cvdriskass_201804_202303_latest;

CREATE TABLE p068_cvdriskass_201804_202303_latest AS
WITH c AS (
	SELECT 
		p.patid,
        p.obsdate,
        p.medcodeid,
        p.value,
        n.description AS numunitid,
        ROW_NUMBER() OVER (PARTITION BY p.patid ORDER BY p.obsdate DESC) AS rn
	FROM (
		SELECT * FROM
		p068_cvdriskass_define
		WHERE obstypeid IN (10, 7, 3, 6) -- 10 - value, 7 - observation, 3 - document, 6 - investigation)
		AND obsdate BETWEEN "2018-04-01" AND "2023-03-31") AS p
	LEFT JOIN lookup_numunitid AS n ON p.numunitid = n.code 
)
SELECT 
	c.patid,
    c.obsdate AS cvdriskass_obsdate,
    c.medcodeid AS cvdriskass_medcodeid,
    d.term AS cvdriskass_medcodeid_term,
    c.value AS cvdriskass_value,
    c.numunitid AS cvdriskass_numunitid
FROM c 
LEFT JOIN (-- Join to get term for medcodeid
	SELECT medcodeid, term
    FROM medcodeid_aurum_202312
	) AS d ON c.medcodeid = d.medcodeid
WHERE rn = 1;

-- Checks
SELECT *
FROM p068_cvdriskass_201804_202303_latest
LIMIT 10;

-- Check if only one record per patient
-- Check min and max obsdate
-- Not checking obstypeid as not selected column
SELECT COUNT(*), COUNT(DISTINCT(patid)), MIN(cvdriskass_obsdate), MAX(cvdriskass_obsdate)
FROM p068_cvdriskass_201804_202303_latest;

/* ---------------------------------------------------------------------------------------------------*/
/* Join CVD risk assessment onto SLE */
DROP TABLE IF EXISTS p068_slupus_cvdriskass;

-- Left join lupus population with CVD risk assessments between April 2018 and March 2023
CREATE TABLE p068_slupus_cvdriskass AS
SELECT 
	s.*, 
    c.cvdriskass_obsdate, 
    c.cvdriskass_medcodeid, 
    c.cvdriskass_medcodeid_term, 
    c.cvdriskass_value, 
    c.cvdriskass_numunitid,
    CASE 
		WHEN c.cvdriskass_obsdate IS NOT NULL THEN 1
        ELSE 0
	END AS indicator
FROM p068_slupus_latest_record AS s
LEFT JOIN p068_cvdriskass_201804_202303_latest AS c ON s.patid = c.patid;

SELECT *
FROM p068_slupus_cvdriskass
LIMIT 200;

-- Calculate proportion
SELECT COUNT(*), COUNT(DISTINCT(patid)), SUM(indicator), SUM(indicator)/COUNT(DISTINCT(patid))
FROM p068_slupus_cvdriskass;