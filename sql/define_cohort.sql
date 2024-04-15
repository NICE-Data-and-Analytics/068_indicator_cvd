USE cprd2023;

/* Identify cohort for IND2023-164
For IND2023-164, the denominator is every person who meets the following inclusion criteria on 31st March 2023 (the end date):
•	Aged 45 to 84 
•	Registered at a CPRD-contributing practice 
*/

DROP TABLE IF EXISTS p068_cohort_45_84;

CREATE TABLE p068_cohort_45_84
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
	FROM absorbed_practices_2023_12);
    
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

CREATE TABLE p068_cohort_43_84
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
	FROM absorbed_practices_2023_12);
    
SELECT COUNT(DISTINCT patid) -- 7114713
FROM p068_cohort_43_84;

SELECT MIN(regenddate), MIN(age), MAX(age)
FROM p068_cohort_43_84;

SELECT *
FROM p068_cohort_43_84
LIMIT 10;