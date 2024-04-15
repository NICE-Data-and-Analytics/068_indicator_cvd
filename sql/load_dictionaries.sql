USE cprd2023;

SHOW TABLES;

/* --------------------------------------------------------------------------------------------------------------- */

-- medcode dictionary
DROP TABLE IF EXISTS medcodeid_aurum_202312;

CREATE TABLE medcodeid_aurum_202312 (
	medcodeid VARCHAR(18) PRIMARY KEY,
    observations BIGINT,
    original_read_code VARCHAR(19),
    cleansed_read_code VARCHAR(7),
    term VARCHAR(240),
    snomed_ct_concept_id VARCHAR(18),
    snomed_ct_description_id VARCHAR(18),
    -- release VARCHAR(5),
    emis_code_category_id INT
);

DESCRIBE medcodeid_aurum_202312;

	-- 1 file
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/cprd_files/code_browser/CPRDAurumMedical_202312_Aurum.txt'
INTO TABLE medcodeid_aurum_202312 
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS 
(@medcodeid, @observations, @original_read_code, @cleansed_read_code, @term, @snomed_ct_concept_id, @snomed_ct_description_id, @dummy, @emis_code_category_id) 
SET
	medcodeid = NULLIF(@medcodeid,''), 
    observations = NULLIF(@observations,''),  
    original_read_code = NULLIF(@original_read_code,''), 
    cleansed_read_code = NULLIF(@cleansed_read_code,''), 
    term = NULLIF(@term,''),  
    snomed_ct_concept_id = NULLIF(@snomed_ct_concept_id,''),  
    snomed_ct_description_id = NULLIF(@snomed_ct_description_id,''), 
    emis_code_category_id = NULLIF(@emis_code_category_id,'');

SELECT * FROM medcodeid_aurum_202312 LIMIT 10;

SELECT COUNT(*) FROM medcodeid_aurum_202312;

/* --------------------------------------------------------------------------------------------------------------- */

-- Code selection - INCOMPLETE

DROP TABLE IF EXISTS p068_codes;

CREATE TABLE p068_codes (
	cluster_id VARCHAR(25),
    cluster_description VARCHAR(240),
	medcodeid VARCHAR(18),
    term VARCHAR(240),
	include VARCHAR(25),
    category VARCHAR(50)
);

DESCRIBE p068_codes;

	-- 1 file
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/068_indicator_cvd/codes/tia_cprd_plus.txt'
INTO TABLE p068_codes 
FIELDS TERMINATED BY ' '
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(@cluster_id, @cluster_description, @dummy, @dummy, @dummy, @dummy, @medcodeid, @dummy, @dummy, @dummy, @term, @dummy, @dummy, @dummy, @include, @dummy, @category) 
SET
	cluster_id = NULLIF(@cluster_id,''), 
    cluster_description = NULLIF(@cluster_description,''),  
    medcodeid = NULLIF(@medcodeid,''), 
    term = NULLIF(@term,''), 
    include = NULLIF(@include,''),  
    category = NULLIF(@category,'');

SELECT * FROM p068_codes LIMIT 10;

SELECT COUNT(*) FROM p068_codes;