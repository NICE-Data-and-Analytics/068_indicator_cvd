USE cprd2023;

/* 
Previous CVD risk assessment score of 20% or more
any record of a CVD risk assessment 
(QRISK, QRISK2, QRISK3, Joint British Societies, Framingham, ASSIGN) 
where the 10-year CVD risk score is 20% or more, 
before the start date (1st April 2020 for IND2023-164, 
1st April 2018 for IND2023-165 and IND2023-166)
*/

SELECT * FROM p068_cvdriskass_define LIMIT 10;

SELECT obstypeid, COUNT(*)
FROM p068_cvdriskass_define
GROUP BY obstypeid;

-- Label medcodeid, numunitid, obstypeid
-- Drop unusual obstypeid
DROP TEMPORARY TABLE IF EXISTS p068_cvdriskass_mod;

CREATE TEMPORARY TABLE p068_cvdriskass_mod AS
SELECT 
	patid, 
    pracid, 
    obsid, 
    obsdate, 
    medcodeid, 
    term AS medcodeid_desc,
    value, 
    description AS numunitid, 
    obstypeid_desc AS obstypeid
FROM p068_cvdriskass_define AS p
-- Get units
LEFT JOIN lookup_numunitid AS n ON p.numunitid = n.code
-- Label obstype
LEFT JOIN (
	SELECT code, description AS obstypeid_desc
	FROM lookup_obstypeid
    ) AS o ON p.obstypeid = o.code
-- Label medcodes
LEFT JOIN (
	SELECT medcodeid AS medcode, term
    FROM medcodeid_aurum_202312
	) AS d ON p.medcodeid = d.medcode
-- Drop records where obstype is 1 - Allergy, 4 - Family history, 8 - Referral
WHERE obstypeid NOT IN (1, 4, 8);

SELECT *
FROM p068_cvdriskass_mod
LIMIT 20;

-- Replace original table
DROP TABLE IF EXISTS p068_cvdriskass_define;

CREATE TABLE p068_cvdriskass_define AS
SELECT * FROM p068_cvdriskass_mod;

-- Previous CVD risk assessment score of 20% or more any record of a CVD risk assessment 
-- before the start date (1st April 2020 for IND2023-164, 
-- 1st April 2018 for IND2023-165 and IND2023-166)

SELECT numunitid, COUNT(*)
FROM p068_cvdriskass_define
GROUP BY numunitid
ORDER BY COUNT(*) DESC;

SELECT medcodeid_desc, medcodeid, COUNT(*)
FROM p068_cvdriskass_define
GROUP BY medcodeid_desc, medcodeid
ORDER BY COUNT(*) DESC;

SELECT *
FROM p068_cvdriskass_define
WHERE numunitid IN ("Unk UoM");

-- Some negative values and some very large values
SELECT COUNT(*), MIN(value), AVG(value), MAX(value)
FROM p068_cvdriskass_define;
-- 31515157	-2147480000	-911.8656535008084	231113

SELECT COUNT(*), MIN(value), AVG(value), MAX(value)
FROM p068_cvdriskass_define
WHERE value BETWEEN 0 AND 100;
-- 27871191	0	12.319821410646313	100

-- Potential for values to be recorded as decimals rather than percentages
-- Would need to adjust threshold to 
SELECT *
FROM p068_cvdriskass_define
WHERE value > 0 and value <= 1
LIMIT 100;

SELECT COUNT(*), MIN(value), AVG(value), MAX(value)
FROM p068_cvdriskass_define
WHERE value > 0 AND value <= 1;

-- See units for records with value between 0 and 1
SELECT numunitid, COUNT(*)
FROM p068_cvdriskass_define
WHERE value > 0 AND value <= 1
GROUP BY numunitid
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS p068_cvdriskass_exclusion;

-- All records of 10-year risk score 20% or more prior to 2020-04
	-- Will need to filter on obsdate for 2018-04 for IND2023-165 and IND2023-166
    -- Using one table only as don't want to hog space
-- Exclude risk assessments that have units in years
	-- May want to drop more units - some are unintelligable
-- Exclude records specifically recording heart age or 5 year risk
	-- Only want 10-year risk
	-- Assumes medcodes that don't specify 5/10-year risk are recording 10 year risk
-- 
CREATE TABLE p068_cvdriskass_exclusion_202004 AS
WITH temp AS (
	SELECT c.*,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_cvdriskass_define AS c
    -- Drop records with units in years
	WHERE numunitid NOT IN ("year", "years")
    -- Drop records recording heart age or 5 year risk
	AND medcodeid NOT IN ("2115691000000116", -- QRISK2 calculated heart age
		"2115711000000119", -- Difference between actual and QRISK2 calculated heart age
		"434881000006116", -- 5 yr CHD risk (Framingham)
		"459503011", -- Framingham Coronary Heart Disease 5 year risk score
		"987511000006110" -- Joint British Societies cardiovascular disease 5 yr risk score
		)
	-- Only the records before the time period the indicators are interested in
	AND obsdate < "2020-04-01"
    -- Score thresholds
	AND (value BETWEEN 20 AND 100
		OR medcodeid IN (
			"977791000006118", -- JBS score 20-30%
			"977801000006117" -- JBS score >30%
			)
		)
	AND patid IN (SELECT patid FROM p068_cohort_43_84) -- Rmb all members of 45-84 cohort are in 43-84
)
SELECT * FROM temp WHERE rn = 1;

SELECT COUNT(DISTINCT patid)
FROM p068_cvdriskass_exclusion; -- 619590

SELECT MIN(value), AVG(value), MAX(value) -- Min value is 0 as used some JBS medcodes that specify result
FROM p068_cvdriskass_exclusion;

/* 
CVD – any record of coronary heart disease, stroke (excluding haemorrhagic stroke), 
transient ischaemic attack or peripheral arterial disease on or before the end date
*/

SELECT obstypeid, COUNT(*)
FROM p068_cvd_define
GROUP BY obstypeid
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS p068_cvd_exclusion;

CREATE TABLE p068_cvd_exclusion AS
WITH temp AS (
	SELECT 
		c.patid, 
		c.pracid, 
		c.obsid, 
		c.obsdate, 
		c.medcodeid, 
		d.term AS medcodeid_desc,
        d.include, 
        d.category, 
        d.cluster_id,
		o.obstypeid_desc AS obstypeid,
		ROW_NUMBER() OVER (PARTITION BY patid, category, cluster_id ORDER BY obsdate DESC) AS rn
	FROM p068_cvd_define AS c
    LEFT JOIN (
		SELECT medcodeid AS medcode, term, include, category, cluster_id
		FROM p068_codes
        WHERE category IN ("CHD", "Stroke", "PAD", "TIA")
	) AS d ON c.medcodeid = d.medcode
    LEFT JOIN (
		SELECT code, description AS obstypeid_desc
		FROM lookup_obstypeid
    ) AS o ON c.obstypeid = o.code
	WHERE c.patid IN (SELECT patid FROM p068_cohort_43_84)
    AND c.obstypeid NOT IN (1, 4)
)
SELECT * FROM temp WHERE rn = 1;

SELECT COUNT(*), COUNT(DISTINCT patid)
FROM p068_cvd_exclusion;
-- 1844887	979829

SELECT COUNT(*), COUNT(DISTINCT patid)
FROM p068_cvd_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_45_84);
-- 1825101	964767

SELECT COUNT(*), COUNT(DISTINCT patid)
FROM p068_cvd_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_43_84);
-- 1844887	979829
-- Same as all, as expected

SELECT *
FROM p068_cvd_exclusion
LIMIT 10;

/* 
Familial hypercholesterolaemia
any record of familial hypercholesterolaemia on or before the end date
*/

SELECT obstypeid, COUNT(*)
FROM p068_fhyp_define
GROUP BY obstypeid
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS p068_fhyp_exclusion;

CREATE TABLE p068_fhyp_exclusion AS
WITH temp AS (
	SELECT 
		c.patid, 
		c.pracid, 
		c.obsid, 
		c.obsdate, 
		c.medcodeid, 
		d.term AS medcodeid_desc,
        d.include, 
        d.category, 
        d.cluster_id,
		o.obstypeid_desc AS obstypeid,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_fhyp_define AS c
    LEFT JOIN (
		SELECT medcodeid AS medcode, term, include, category, cluster_id
		FROM p068_codes
        WHERE category IN ("Familial hypercholesterolaemia")
	) AS d ON c.medcodeid = d.medcode
    LEFT JOIN (
		SELECT code, description AS obstypeid_desc
		FROM lookup_obstypeid
    ) AS o ON c.obstypeid = o.code
	WHERE c.patid IN (SELECT patid FROM p068_cohort_43_84)
    AND c.obstypeid NOT IN (1, 4)
)
SELECT * FROM temp WHERE rn = 1;

SELECT COUNT(*)
FROM p068_fhyp_exclusion;
-- 45414

SELECT COUNT(*)
FROM p068_fhyp_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_45_84);
-- 44100

SELECT COUNT(*)
FROM p068_fhyp_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_43_84);
-- 45414

SELECT *
FROM p068_fhyp_exclusion
LIMIT 10;

/* 
Type 1 diabetes – any record of type 1 diabetes on or before the end date
*/

SELECT obstypeid, COUNT(*)
FROM p068_t1dm_define
GROUP BY obstypeid
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS p068_t1dm_exclusion;

CREATE TABLE p068_t1dm_exclusion AS
WITH temp AS (
	SELECT 
		c.patid, 
		c.pracid, 
		c.obsid, 
		c.obsdate, 
		c.medcodeid, 
		d.term AS medcodeid_desc,
        d.include, 
        d.category, 
        d.cluster_id,
		o.obstypeid_desc AS obstypeid,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_t1dm_define AS c
    LEFT JOIN (
		SELECT medcodeid AS medcode, term, include, category, cluster_id
		FROM p068_codes
        WHERE category IN ("Type 1 diabetes")
	) AS d ON c.medcodeid = d.medcode
    LEFT JOIN (
		SELECT code, description AS obstypeid_desc
		FROM lookup_obstypeid
    ) AS o ON c.obstypeid = o.code
	WHERE (c.patid IN (SELECT patid FROM p068_cohort_45_84)
		OR c.patid IN (SELECT patid FROM p068_cohort_43_84))
    AND c.obstypeid NOT IN (1, 4)
)
SELECT * FROM temp WHERE rn = 1;

SELECT COUNT(*)
FROM p068_t1dm_exclusion;
-- 48401

SELECT COUNT(*)
FROM p068_t1dm_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_45_84);
-- 45920

SELECT COUNT(*)
FROM p068_t1dm_exclusion
WHERE patid IN (SELECT patid FROM p068_cohort_43_84);
-- 48401

SELECT *
FROM p068_t1dm_exclusion
LIMIT 10;

/* 
CKD stage 3a to 5 – any record of CKD stage 3 to 5, 
with no subsequent code for CKD resolved or CKD stage 1 to 2, 
on or before the end date
*/

SELECT obstypeid, COUNT(*)
FROM p068_ckd_define
GROUP BY obstypeid
ORDER BY COUNT(*) DESC;

DROP TABLE IF EXISTS p068_ckd_exclusion;

-- Keep latest record per patient
-- If latest record is not stage 3 to 5, drop
CREATE TABLE p068_ckd_exclusion AS
WITH temp AS (
	SELECT 
		c.patid, 
		c.pracid, 
		c.obsid, 
		c.obsdate, 
		c.medcodeid, 
		d.term AS medcodeid_desc,
        d.include, 
        d.category, 
        d.cluster_id,
		o.obstypeid_desc AS obstypeid,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_ckd_define AS c
    LEFT JOIN (
		SELECT medcodeid AS medcode, term, include, category, cluster_id
		FROM p068_codes
        WHERE category IN ("CKD stage 3 to 5", "CKD stage 1 and 2", "CKD resolved")
	) AS d ON c.medcodeid = d.medcode
    LEFT JOIN (
		SELECT code, description AS obstypeid_desc
		FROM lookup_obstypeid
    ) AS o ON c.obstypeid = o.code
	WHERE (c.patid IN (SELECT patid FROM p068_cohort_45_84)
		OR c.patid IN (SELECT patid FROM p068_cohort_43_84))
    AND c.obstypeid NOT IN (1, 4)
),
latest AS (
	SELECT * FROM temp WHERE rn = 1
)
SELECT *
FROM latest
WHERE category = "CKD stage 3 to 5";

SELECT COUNT(*), COUNT(DISTINCT patid)
FROM p068_ckd_exclusion;
-- 441291	441291

SELECT *
FROM p068_ckd_exclusion
LIMIT 20;