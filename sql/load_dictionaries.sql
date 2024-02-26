USE cprd2023;

SHOW TABLES;

/* --------------------------------------------------------------------------------------------------------------- */

-- medcode dictionary

CREATE TABLE IF NOT EXISTS medcodeid_aurum_202312 (
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