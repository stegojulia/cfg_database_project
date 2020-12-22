-- CREATE DATABASE
CREATE DATABASE museum_db;
USE museum_db;

-- CREATE TABLES
CREATE TABLE `objects` (
  `object_id` INT NOT NULL AUTO_INCREMENT,
  `museum_number` VARCHAR(50) NOT NULL,
  `title` VARCHAR(150),
  `year` INT,
  `artist` INT,
  `condition_code` INT,
  PRIMARY KEY (`object_id`)
);

CREATE TABLE `users` (
  `staff_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(50) NOT NULL,
  `last_name` VARCHAR(50) NOT NULL,
  `job_title` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`staff_id`)
);

CREATE TABLE `location_history` (
  `move_id` INT NOT NULL AUTO_INCREMENT,
  `move_date` DATE NOT NULL,
  `object_id` INT NOT NULL,
  `updated_location` VARCHAR(10) NOT NULL,
  `staff_id` INT NOT NULL,
  PRIMARY KEY (`move_id`)
);

CREATE TABLE `attributes` (
  `entry_id` INT AUTO_INCREMENT,
  `object_id` INT NOT NULL,
  `height` INT,
  `width` INT,
  `medium` VARCHAR(100),
  `support` VARCHAR(50),
  PRIMARY KEY (`entry_id`)
);

CREATE TABLE `framing` (
  `entry_id` INT NOT NULL AUTO_INCREMENT,
  `entry_date` DATE NOT NULL,
  `object_id` INT NOT NULL,
  `framed` BOOL,
  `frame_height` INT,
  `frame_width` INT,
  `frame_depth` INT,
  `glazed` BOOL,
  `glazing_type` VARCHAR(50),
  `backboard` BOOL,
  `backboard_type` VARCHAR(50),
  PRIMARY KEY (`entry_id`)
);

CREATE TABLE `conservation_reports` (
  `entry_id` INT  NOT NULL AUTO_INCREMENT,
  `entry_date` DATE NOT NULL,
  `object_id` INT NOT NULL,
  `report_type` VARCHAR(50) NOT NULL,
  `report_text` VARCHAR(500) NOT NULL,
  `staff_id` INT NOT NULL,
  PRIMARY KEY (`entry_id`)
);

CREATE TABLE `artists` (
  `artist_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(100),
  `last_name` VARCHAR(100),
  `year_born` INT,
  `year_died` INT,
  `country_born` VARCHAR(50),
  `country_died` VARCHAR(50),
  PRIMARY KEY (`artist_id`)
);

-- UPLOAD DATA FROM CSV FILES
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/objects.csv' 
INTO TABLE objects 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/staff.csv' 
INTO TABLE users 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

DROP TABLE location_history;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/location_history.csv' 
INTO TABLE location_history 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/attributes.csv' 
INTO TABLE attributes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/framing.csv' 
INTO TABLE framing
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/conservation.csv' 
INTO TABLE conservation_reports
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/artists.csv' 
INTO TABLE artists
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- CREATE A VIEW OF ALL UNGLAZED OIL PAINTINGS CURRENTLY ON DISPLAY WITH THEIR LOCATION TO PROVIDE CONSERVATORS WITH A LIST OF PAINTINGS TO DUST
CREATE VIEW for_dusting
AS
SELECT o.title, l.updated_location
FROM objects o
JOIN location_history l
ON o.object_id = l.object_id
JOIN attributes at
ON o.object_id = at.object_id
JOIN framing f 
ON o.object_id = f.object_id
WHERE glazed = 0 AND medium ='oil';

SELECT * FROM for_dusting;

-- CREATE A FUNCTION WHICH CHECKS IF A PAINTING IS AVAILABLE FOR VIEWING
DELIMITER //
CREATE FUNCTION is_on_display(location VARCHAR(10), condition_code INT) 
RETURNS VARCHAR(100)
DETERMINISTIC 
BEGIN
DECLARE object_status VARCHAR(100);
IF location LIKE 'G%' THEN
SET object_status = 'ON DISPLAY';
ELSEIF condition_code >=3 THEN
SET object_status = 'VIEW BY APPOINTMENT ONLY';
END IF;
RETURN (object_status);
END//
DELIMITER ;

-- call the function to see which paintings by Turner can be viewed
SELECT o.museum_number, o.title, is_on_display(l.updated_location, o.condition_code) as is_on_display
FROM objects o
JOIN location_history l
ON o.object_id = l.object_id
JOIN artists a
ON o.artist = a.artist_id
WHERE a.last_name = 'Turner';


-- USE A SUBQUERY TO IDENTIFY OBJECTS IN NEED OF A CONSERVATION REPORT
SELECT o.museum_number
FROM objects o
WHERE object_id NOT IN
(SELECT DISTINCT o.object_id
FROM objects o
JOIN conservation_reports cr
ON o.object_id = cr.object_id);


-- CREATE A PROCEDURE THAT UPDATES THE LOCATION OF AN OBJECT
DELIMITER //
CREATE PROCEDURE ObjectMove(IN object_id INT, IN location VARCHAR(10), IN staff INT)
BEGIN
INSERT INTO location_history(move_date, object_id, updated_location, staff_id)
VALUES (CURRENT_DATE(), object_id, location, staff);
END// 
DELIMITER ;

-- call the procedure to log a change of location
CALL ObjectMove(3, 'G5', 61012);


-- IN FRAMING, A PAINTING HAS TO BE FRAMED TO BE GLAZED. CREATE A TRIGGER THAT WILL ENSURE THAT VALUE OF GLAZED IS 0 IF THE VALUE OF 'FRAMED' FOR COMPLETE DATA
DELIMITER //
CREATE TRIGGER framed_is_zero
	BEFORE INSERT ON framing
	FOR EACH ROW
    BEGIN
	IF (new.framed = 0) THEN
	SET new.glazed = 0;
	END IF;
    END//
-- example of the trigger in use
INSERT INTO framing (entry_date, object_id, framed)
VALUES (CURRENT_DATE(), 4, 0);


