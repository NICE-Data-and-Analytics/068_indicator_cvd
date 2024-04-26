USE cprd2023;

CREATE TABLE p068_smoking (
WITH temp AS (
    SELECT d.*,
        c.term,
        n.description,
        o.description AS obstypeid_desc,
        c.include, 
        c.category, 
        c.cluster_id,
        ROW_NUMBER() OVER (PARTITION BY patid, cluster_id ORDER BY obsdate DESC) AS rn
    FROM p068_smoking_define AS d
    -- Label units
    LEFT JOIN lookup_numunitid AS n ON d.numunitid = n.code
    -- Label obstype
    LEFT JOIN lookup_obstypeid AS o ON d.obstypeid = o.code
    -- Label medcodes
    LEFT JOIN (
        SELECT *
        FROM p068_codes
        WHERE category IN ('Smoking status', 'Current smoker')
        ) AS c ON d.medcodeid = c.medcodeid
    -- Drop records where obstype is 1 - Allergy or 4 - Family history
    WHERE d.obstypeid NOT IN (1, 4)
    )
    SELECT patid,
        pracid,
        obsid,
        obsdate,
        medcodeid,
        term AS medcodeid_desc,
        description AS numunitid, 
        obstypeid_desc AS obstypeid,
        include, 
        category, 
        cluster_id
    FROM temp
    WHERE rn = 1
);