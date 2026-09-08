-- DATA CLEANING 

-- 1. REMOVE COLUMNS NOT NEEDED FOR ANALYSIS 

ALTER TABLE nyc_restaurant_data
	DROP COLUMN building,   
	DROP COLUMN street,    
	DROP COLUMN zipcode,   
	DROP COLUMN phone,   
	DROP COLUMN community_board,   
	DROP COLUMN council_district,   
	DROP COLUMN census_tract, 
    DROP COLUMN latitude,   
	DROP COLUMN longitude,
	DROP COLUMN bin,   
	DROP COLUMN bbl,    
	DROP COLUMN nta,
    DROP COLUMN location_point1;  
    
 -- 2. DELETE PLACEHOLDER RECORDS 
 
 DELETE FROM nyc_restaurant_data
 WHERE inspection_date = '01/01/1900'; 
    
-- 3. CLEAN MISSING / BLANK VALUES 

UPDATE nyc_restaurant_data
SET 
grade_date = NULLIF(grade_date,''),
inspection_date = NULLIF(inspection_date, ''), 
score= nullif(score,''), 
grade=nullif(grade,''); 
 
UPDATE nyc_restaurant_data
SET 
violation_code= NULL,
violation_description = NULL 
WHERE TRIM(violation_code)='' 
AND TRIM(violation_description)=''; 


-- 4. CHANGE DATE FORMAT 

UPDATE nyc_restaurant_data 
SET 
inspection_date = str_to_date(inspection_date,'%m/%d/%Y'), 
grade_date= str_to_date(grade_date,'%m/%d/%Y'),   
record_date = str_to_date(record_date,'%m/%d/%Y');    

-- 5.  CORRECT DATA TYPES 

ALTER TABLE nyc_restaurant_data
MODIFY COLUMN inspection_date DATE , 
MODIFY COLUMN SCORE INT , 
MODIFY COLUMN grade_date DATE , 
MODIFY COLUMN record_date DATE   ;

-- 6. STANDARDISE CATEGORICAL FIELDS (VIOLATION CODES AND DESCRIPTIONS) 

SELECT DISTINCT violation_code, violation_description
FROM nyc_restaurant_data
WHERE violation_code IS  NOT NULL 
GROUP BY violation_code,violation_description
ORDER BY violation_code, violation_description; 

 
 UPDATE nyc_restaurant_data 
 SET violation_code =
	CASE violation_code
			WHEN '20D' THEN '20-04'   
			WHEN '16A' THEN '16-01'   
			WHEN '16E' THEN '16-06'   
			WHEN '15F1'THEN '15-39'   
			WHEN '20F' THEN '20-06'   
			WHEN '18D' THEN '18-13'   
			WHEN '15E2'THEN '15-21'   
			WHEN '15S' THEN '15-21'   
			WHEN '20A' THEN '20-01'   
			WHEN '20E' THEN '20-05'   
			WHEN '22A' THEN '28-01'   
			WHEN '15E3'THEN '15-22'
			WHEN '16D' THEN '16-04'
			WHEN '18F' THEN '18-08'
			WHEN '15F7'THEN '15-27'
			WHEN '16K' THEN '16-09'
			WHEN '16J' THEN '16-08'
			WHEN '16L' THEN '16-10'
			WHEN '16B' THEN '16-02'
			WHEN '15F6'THEN '15-37'
			WHEN '18C' THEN '18-14'
			WHEN '18B' THEN '18-12'
			WHEN '16C' THEN '16-03'
			WHEN '15F2'THEN '15-42'
	ELSE violation_code 
	END ;  					/* Standardised inconsistent violation codes by matching the
								older codes to the corresponding standard code*/


SELECT violation_code, 
COUNT(DISTINCT  violation_description) AS total_descriptions 
FROM nyc_restaurant_data
GROUP BY violation_code
HAVING COUNT(DISTINCT violation_description)>1
order by total_descriptions  desc ;
						/* -- Checking which violation codes have more than one description
						to identify inconsistencies that may need to be standardised*/ 	
                        
SELECT
    violation_code,
    violation_description AS proposed_standard_description,
    inspection_date AS latest_inspection_date
FROM
 (SELECT violation_code,violation_description,inspection_date,
ROW_NUMBER() OVER (PARTITION BY violation_code ORDER BY inspection_date DESC) AS rn
FROM nyc_restaurant_data
WHERE violation_code NOT IN ('05E','05H','10G','10H','19-01')
) AS ranked
 WHERE rn = 1
ORDER BY violation_code;


UPDATE nyc_restaurant_data AS r
JOIN (SELECT violation_code, violation_description
FROM (SELECT violation_code, violation_description, inspection_date,
ROW_NUMBER() OVER (PARTITION BY violation_code ORDER BY inspection_date DESC) AS rn
FROM nyc_restaurant_data
WHERE violation_code NOT IN ('05E','05H','10G','10H','19-01')
AND violation_description IS NOT NULL) AS ranked
WHERE rn = 1) AS latest
ON r.violation_code = latest.violation_code
SET r.violation_description = latest.violation_description;     

                                     /* Standardised violation descriptions using the latest available
                                     description for each code, excluding codes with conflicting descriptions.*/
                   

-- 7. SPLITTING INSPECTION TYPE INTO INSPECTION PROGRAM AND INSPECTION STAGE 

ALTER TABLE nyc_restaurant_data
ADD inspection_program TEXT,
ADD inspection_stage TEXT ;

UPDATE nyc_restaurant_data
SET 
    inspection_program = SUBSTRING_INDEX(inspection_type, '/', 1),
    inspection_stage = SUBSTRING_INDEX(inspection_type, '/', -1);

-- ------------------------------------------- -- 

SELECT * FROM nyc_restaurant_data limit 10; 

