-- Automated Data Cleaning

SELECT * 
FROM bakery.ushouseholdincome;

SELECT * 
FROM bakery.ushouseholdincome_cleaned;

-- Data Cleaning Steps

-- Remove Duplicates
DELETE FROM ushouseholdincome
WHERE 
	row_id IN (
	SELECT row_id
FROM (
	SELECT row_id, id,
		ROW_NUMBER() OVER (
			PARTITION BY id
			ORDER BY id) AS row_num
	FROM 
		us_household_income_clean
) duplicates
WHERE 
	row_num > 1
);

-- Fixing some data quality issues by fixing typos and general standardization
UPDATE ushouseholdincome
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE ushouseholdincome
SET County = UPPER(County);

UPDATE ushouseholdincome
SET City = UPPER(City);

UPDATE ushouseholdincome
SET Place = UPPER(Place);

UPDATE ushouseholdincome
SET State_Name = UPPER(State_Name);

UPDATE ushouseholdincome
SET `Type` = 'CDP'
WHERE `Type` = 'CPD';

UPDATE ushouseholdincome
SET `Type` = 'Borough'
WHERE `Type` = 'Boroughs';

-- Stored Procedure
DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
-- CREATING OUR TABLE
	CREATE TABLE IF NOT EXISTS `ushouseholdincome_Cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` varchar(10) DEFAULT NULL,
	  `ALand` bigint DEFAULT NULL,
	  `AWater` bigint DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `Time_Stamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
    
-- COPY DATA TO NEW TABLE
	INSERT INTO ushouseholdincome_cleaned
    SELECT *, CURRENT_TIMESTAMP
	FROM bakery.ushouseholdincome;

	-- Data Cleaning Steps

	-- Remove Duplicates
	DELETE FROM ushouseholdincome_cleaned
	WHERE 
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM 
			ushouseholdincome_cleaned
	) duplicates
	WHERE 
		row_num > 1
	);

	-- Fixing some data quality issues by fixing typos and general standardization
	UPDATE ushouseholdincome_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE ushouseholdincome_cleaned
	SET County = UPPER(County);

	UPDATE ushouseholdincome_cleaned
	SET City = UPPER(City);

	UPDATE ushouseholdincome_cleaned
	SET Place = UPPER(Place);

	UPDATE ushouseholdincome_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE ushouseholdincome_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE ushouseholdincome_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';

END $$
DELIMITER ;

CALL Copy_and_Clean_Data();

-- DEBUGGING OR CHECKING SP WORKS
	SELECT row_id, id, row_num
    FROM (
		SELECT row_id, id, 
			ROW_NUMBER() OVER (
				PARTITION BY id
                ORDER BY id) AS row_num
			FROM 
				ushouseholdincome_cleaned
		) duplicates
        WHERE 
			row_num > 1;


SELECT COUNT(row_id)
FROM ushouseholdincome_cleaned;

SELECT State_Name, COUNT(State_Name)
FROM ushouseholdincome_cleaned
GROUP BY State_Name; 

-- CREATE EVENT

CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 2 minute
    DO CALL Copy_and_Clean_Data();


-- CREATE TRIGGER
DELIMITER $$
CREATE TRIGGER transfer_clean_data
	AFTER INSERT ON bakery.ushouseholdincome
    FOR EACH ROW
BEGIN
	CALL Copy_and_Clean_Data();
END $$
DELIMITER ;








