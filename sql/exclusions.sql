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
LEFT JOIN lookup_numunitid AS n ON p.numunitid = n.code
LEFT JOIN (
	SELECT code, description AS obstypeid_desc
	FROM lookup_obstypeid
    ) AS o ON p.obstypeid = o.code
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

SELECT MIN(value), AVG(value), MAX(value)
FROM p068_cvdriskass_define;

-- 1st April 2020 for IND2023-164
DROP TABLE IF EXISTS p068_cvdriskass_202004_exclusion;

CREATE TABLE p068_cvdriskass_202004_exclusion AS
WITH temp AS (
	SELECT c.*,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_cvdriskass_define AS c
	WHERE numunitid NOT IN ("year", "years")
	AND medcodeid NOT IN ("2115691000000116", -- QRISK2 calculated heart age
		"2115711000000119", -- Difference between actual and QRISK2 calculated heart age
		"434881000006116", -- 5 yr CHD risk (Framingham)
		"459503011", -- Framingham Coronary Heart Disease 5 year risk score
		"987511000006110" -- Joint British Societies cardiovascular disease 5 yr risk score
		)
	AND obsdate < "2020-04-01"
	AND (value BETWEEN 20 AND 100
		OR medcodeid IN (
			"977791000006118", -- JBS score 20-30%
			"977801000006117" -- JBS score >30%
			)
		)
	AND patid IN (SELECT patid FROM p068_cohort_45_84)
)
SELECT * FROM temp WHERE rn = 1;
    
SELECT numunitid, COUNT(*)
FROM p068_cvdriskass_202004_exclusion
GROUP BY numunitid
ORDER BY COUNT(*) DESC;

SELECT COUNT(DISTINCT patid)
FROM p068_cvdriskass_202004_exclusion; -- 777001

SELECT medcodeid_desc, medcodeid, COUNT(*)
FROM p068_cvdriskass_202004_exclusion
GROUP BY medcodeid_desc, medcodeid
ORDER BY COUNT(*) DESC;

SELECT MIN(value), AVG(value), MAX(value) -- Min value is 0 as used some JBS medcodes that specify result
FROM p068_cvdriskass_202004_exclusion;

-- 1st April 2018 for IND2023-165 and IND2023-166
DROP TABLE IF EXISTS p068_cvdriskass_201804_exclusion;

CREATE TABLE p068_cvdriskass_201804_exclusion AS
WITH temp AS (
	SELECT c.*,
		ROW_NUMBER() OVER (PARTITION BY patid ORDER BY obsdate DESC) AS rn
	FROM p068_cvdriskass_define AS c
	WHERE numunitid NOT IN ("year", "years")
	AND medcodeid NOT IN ("2115691000000116", -- QRISK2 calculated heart age
		"2115711000000119", -- Difference between actual and QRISK2 calculated heart age
		"434881000006116", -- 5 yr CHD risk (Framingham)
		"459503011", -- Framingham Coronary Heart Disease 5 year risk score
		"987511000006110" -- Joint British Societies cardiovascular disease 5 yr risk score
		)
	AND obsdate < "2018-04-01"
	AND (value BETWEEN 20 AND 100
		OR medcodeid IN (
			"977791000006118", -- JBS score 20-30%
			"977801000006117" -- JBS score >30%
			)
		)
	AND patid IN (SELECT patid FROM p068_cohort_43_84)
)
SELECT * FROM temp WHERE rn = 1;

SELECT COUNT(DISTINCT patid)
FROM p068_cvdriskass_201804_exclusion; -- 619590

SELECT MIN(value), AVG(value), MAX(value) -- Min value is 0 as used some JBS medcodes that specify result
FROM p068_cvdriskass_201804_exclusion;

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
	WHERE (c.patid IN (SELECT patid FROM p068_cohort_45_84)
		OR c.patid IN (SELECT patid FROM p068_cohort_43_84))
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
	WHERE (c.patid IN (SELECT patid FROM p068_cohort_45_84)
		OR c.patid IN (SELECT patid FROM p068_cohort_43_84))
    AND c.obstypeid NOT IN (4)
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

