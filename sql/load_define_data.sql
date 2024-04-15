USE cprd2023;

/* --------------------------------------------------------------------------------------------------------------- */

-- p068_cvdriskass_define

DROP TABLE IF EXISTS p068_cvdriskass_define;

CREATE TABLE IF NOT EXISTS p068_cvdriskass_define (
	patid VARCHAR(19),
    consid VARCHAR(19),
    pracid INT,
    obsid VARCHAR(19) PRIMARY KEY,
    obsdate DATE,
    enterdate DATE,
    staffid VARCHAR(10),
    parentobsid VARCHAR(19),
    medcodeid VARCHAR(18),
    value FLOAT,
    numunitid INT,
    obstypeid INT,
    numrangehigh FLOAT,
    numrangelow FLOAT,
    probobsid VARCHAR(19)
);

DESCRIBE p068_cvdriskass_define;

	-- 9 files
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/068_indicator_cvd/data/cvdriskass_Define_Inc1_Observation_009.txt'
INTO TABLE p068_cvdriskass_define 
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS 
(@patid, @consid, @pracid, @obsid, @obsdate, @enterdate, @staffid, @parentobsid, @medcodeid, @value, @numunitid, @obstypeid, @numrangehigh, @numrangelow, @probobsid) 
SET
	patid = NULLIF(@patid,''), 
    consid = NULLIF(@consid,''),  
    pracid = NULLIF(@pracid,''), 
    obsid = NULLIF(@obsid,''), 
	obsdate = NULLIF(STR_TO_DATE(@obsdate, '%d/%m/%Y'), '0000-00-00'), 
    enterdate = NULLIF(STR_TO_DATE(@enterdate, '%d/%m/%Y'), '0000-00-00'),
    staffid = NULLIF(@staffid,''),  
    parentobsid = NULLIF(@parentobsid,''),  
    medcodeid = NULLIF(@medcodeid,''), 
    value = NULLIF(@value,''),  
    numunitid = NULLIF(@numunitid,''),  
    obstypeid = NULLIF(@obstypeid,''),  
    numrangehigh = NULLIF(@numrangehigh,''),  
    numrangelow = NULLIF(@numrangelow,''),  
    probobsid = NULLIF(@probobsid,'');

SELECT * FROM p068_cvdriskass_define LIMIT 10;

SELECT COUNT(*) FROM p068_cvdriskass_define; -- 31515737

/* --------------------------------------------------------------------------------------------------------------- */

-- p068_cvd_define

DROP TABLE IF EXISTS p068_cvd_define;

CREATE TABLE IF NOT EXISTS p068_cvd_define (
	patid VARCHAR(19),
    consid VARCHAR(19),
    pracid INT,
    obsid VARCHAR(19) PRIMARY KEY,
    obsdate DATE,
    enterdate DATE,
    staffid VARCHAR(10),
    parentobsid VARCHAR(19),
    medcodeid VARCHAR(18),
    value FLOAT,
    numunitid INT,
    obstypeid INT,
    numrangehigh FLOAT,
    numrangelow FLOAT,
    probobsid VARCHAR(19)
);

DESCRIBE p068_cvd_define;

	-- 6 files for CHD
    -- 2 files for stroke
    -- 1 file for TIA
    -- 1 file for PAD
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/068_indicator_cvd/data/tia_Define_Inc1_Observation_001.txt'
INTO TABLE p068_cvd_define 
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS 
(@patid, @consid, @pracid, @obsid, @obsdate, @enterdate, @staffid, @parentobsid, @medcodeid, @value, @numunitid, @obstypeid, @numrangehigh, @numrangelow, @probobsid) 
SET
	patid = NULLIF(@patid,''), 
    consid = NULLIF(@consid,''),  
    pracid = NULLIF(@pracid,''), 
    obsid = NULLIF(@obsid,''), 
	obsdate = NULLIF(STR_TO_DATE(@obsdate, '%d/%m/%Y'), '0000-00-00'), 
    enterdate = NULLIF(STR_TO_DATE(@enterdate, '%d/%m/%Y'), '0000-00-00'),
    staffid = NULLIF(@staffid,''),  
    parentobsid = NULLIF(@parentobsid,''),  
    medcodeid = NULLIF(@medcodeid,''), 
    value = NULLIF(@value,''),  
    numunitid = NULLIF(@numunitid,''),  
    obstypeid = NULLIF(@obstypeid,''),  
    numrangehigh = NULLIF(@numrangehigh,''),  
    numrangelow = NULLIF(@numrangelow,''),  
    probobsid = NULLIF(@probobsid,'');

SELECT * FROM p068_cvd_define LIMIT 10;

SELECT COUNT(*) FROM p068_cvd_define;

/* --------------------------------------------------------------------------------------------------------------- */

-- p068_fhyp_define

DROP TABLE IF EXISTS p068_fhyp_define;

CREATE TABLE IF NOT EXISTS p068_fhyp_define (
	patid VARCHAR(19),
    consid VARCHAR(19),
    pracid INT,
    obsid VARCHAR(19) PRIMARY KEY,
    obsdate DATE,
    enterdate DATE,
    staffid VARCHAR(10),
    parentobsid VARCHAR(19),
    medcodeid VARCHAR(18),
    value FLOAT,
    numunitid INT,
    obstypeid INT,
    numrangehigh FLOAT,
    numrangelow FLOAT,
    probobsid VARCHAR(19)
);

DESCRIBE p068_fhyp_define;

	-- 1 file for familial hypercholesterolaemia
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/068_indicator_cvd/data/fhyp_Define_Inc1_Observation_001.txt'
INTO TABLE p068_fhyp_define 
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS 
(@patid, @consid, @pracid, @obsid, @obsdate, @enterdate, @staffid, @parentobsid, @medcodeid, @value, @numunitid, @obstypeid, @numrangehigh, @numrangelow, @probobsid) 
SET
	patid = NULLIF(@patid,''), 
    consid = NULLIF(@consid,''),  
    pracid = NULLIF(@pracid,''), 
    obsid = NULLIF(@obsid,''), 
	obsdate = NULLIF(STR_TO_DATE(@obsdate, '%d/%m/%Y'), '0000-00-00'), 
    enterdate = NULLIF(STR_TO_DATE(@enterdate, '%d/%m/%Y'), '0000-00-00'),
    staffid = NULLIF(@staffid,''),  
    parentobsid = NULLIF(@parentobsid,''),  
    medcodeid = NULLIF(@medcodeid,''), 
    value = NULLIF(@value,''),  
    numunitid = NULLIF(@numunitid,''),  
    obstypeid = NULLIF(@obstypeid,''),  
    numrangehigh = NULLIF(@numrangehigh,''),  
    numrangelow = NULLIF(@numrangelow,''),  
    probobsid = NULLIF(@probobsid,'');

SELECT * FROM p068_fhyp_define LIMIT 10;

SELECT COUNT(*) FROM p068_fhyp_define;

/* --------------------------------------------------------------------------------------------------------------- */

-- p068_slupus_define

CREATE TABLE IF NOT EXISTS p068_slupus_define (
	patid VARCHAR(19),
    consid VARCHAR(19),
    pracid INT,
    obsid VARCHAR(19) PRIMARY KEY,
    obsdate DATE,
    enterdate DATE,
    staffid VARCHAR(10),
    parentobsid VARCHAR(19),
    medcodeid VARCHAR(18),
    value FLOAT,
    numunitid INT,
    obstypeid INT,
    numrangehigh FLOAT,
    numrangelow FLOAT,
    probobsid VARCHAR(19)
);

DESCRIBE p068_slupus_define;

	-- 1 file
    -- NULLIF to help read null values
LOAD DATA LOCAL INFILE 'C:/Users/Public/Documents/068_indicator_cvd/data/slupus_Define_Inc1_Observation_001.txt'
INTO TABLE p068_slupus_define 
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS 
(@patid, @consid, @pracid, @obsid, @obsdate, @enterdate, @staffid, @parentobsid, @medcodeid, @value, @numunitid, @obstypeid, @numrangehigh, @numrangelow, @probobsid) 
SET
	patid = NULLIF(@patid,''), 
    consid = NULLIF(@consid,''),  
    pracid = NULLIF(@pracid,''), 
    obsid = NULLIF(@obsid,''), 
	obsdate = NULLIF(STR_TO_DATE(@obsdate, '%d/%m/%Y'), '0000-00-00'), 
    enterdate = NULLIF(STR_TO_DATE(@enterdate, '%d/%m/%Y'), '0000-00-00'),
    staffid = NULLIF(@staffid,''),  
    parentobsid = NULLIF(@parentobsid,''),  
    medcodeid = NULLIF(@medcodeid,''), 
    value = NULLIF(@value,''),  
    numunitid = NULLIF(@numunitid,''),  
    obstypeid = NULLIF(@obstypeid,''),  
    numrangehigh = NULLIF(@numrangehigh,''),  
    numrangelow = NULLIF(@numrangelow,''),  
    probobsid = NULLIF(@probobsid,'');

SELECT * FROM p068_slupus_define LIMIT 10;

SELECT COUNT(*) FROM p068_slupus_define;

