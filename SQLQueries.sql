USE	Projects

SELECT	*
FROM	HR

--Rename column
EXEC sp_rename 'hr.id', 'empl_id','COLUMN';

--Change empl_id column data type
ALTER TABLE	hr
ALTER COLUMN empl_id VARCHAR(20) NULL;



--Describe table
sp_help 'HR';

SELECT birthdate FROM HR;

--Check if all data are of type DATE
SELECT birthdate
FROM HR
WHERE ISDATE(birthdate) = 0;

-- Change birthdate,hire_date,termdate column data type to 'DATE'
ALTER TABLE HR
ALTER COLUMN birthdate DATE;
ALTER TABLE HR
ALTER COLUMN hire_date DATE;

					
--Modify termdate column to data without hour, then change the data type to DATE
BEGIN TRANSACTION;
BEGIN TRY
	UPDATE HR
	SET termdate = LEFT(termdate, 10)
	
	COMMIT;
    PRINT 'Actualización completada y transacción confirmada.';
END TRY
BEGIN CATCH
	ROLLBACK;
    PRINT 'Transacción revertida debido a un error.';
END CATCH;


--change termdate data type to DATE
ALTER TABLE HR
ALTER COLUMN termdate DATE;

--Create age column
ALTER TABLE HR
ADD age INT;

-- Update age column , there is no null in birthdate rows
UPDATE HR
SET age = DATEDIFF(YEAR,birthdate, GETDATE())



-- QUESTIONS

-- 1. What is the gender breakdown of employees in the company?

SELECT	gender,
		COUNT(gender) as total
FROM	HR
WHERE	termdate IS NULL
GROUP BY gender
ORDER BY total DESC

-- 2. What is the race/ethnicity breakdown of employees in the company?

SELECT	race,
		COUNT(race) as total
FROM	HR
WHERE	termdate IS NULL
GROUP BY race
ORDER BY total DESC

-- 3. What is the age distribution of employees in the company?

WITH CTE AS
			(	
			SELECT CASE 
					WHEN age >=20 AND age <=29 THEN '20-29'
					WHEN age >=30 AND age <=39 THEN '30-39'
					WHEN age >=40 AND age <=49 THEN '40-49'
					ELSE '50+'
					END as	age_group,
							gender
					FROM	HR
					WHERE	termdate IS NULL	
			)

SELECT	age_group,
		gender,
		COUNT(*) as total
FROM	CTE
GROUP BY age_group,gender
ORDER BY age_group,total DESC

-- 4. How many employees work at headquarters versus remote locations?

SELECT	location,
		COUNT(*) as total
FROM	HR
WHERE	termdate IS NULL
GROUP BY location;


-- 5. What is the average length of employment for employees who have been terminated?

SELECT	
		MIN(DATEDIFF(YEAR,hire_date,termdate)) AS min_length,
		MAX(DATEDIFF(YEAR,hire_date,termdate)) AS max_length,
		AVG(DATEDIFF(YEAR,hire_date,termdate)) AS avg_length_employment
FROM	HR
WHERE	termdate IS NOT NULL;

--check dates of employees have been employed for less than a year
SELECT	COUNT(*)
FROM(
	SELECT	first_name,
		last_name,
		hire_date,
		termdate,
		MIN(DATEDIFF(YEAR,hire_date,termdate)) AS min_length,
		MAX(DATEDIFF(YEAR,hire_date,termdate)) AS max_length
		FROM	HR
		WHERE	termdate IS NOT NULL
		GROUP BY hire_date,termdate,first_name,last_name
		HAVING	MIN(DATEDIFF(YEAR,hire_date,termdate)) <1
) as subquery
-- 6. How does the gender distribution vary across departments and job titles?

SELECT	department,
		gender,
		jobtitle,
		COUNT(*) as total
FROM	HR
WHERE	termdate IS NULL
GROUP BY department,jobtitle,gender
ORDER BY department

-- 7. What is the distribution of job titles across the company?

SELECT	jobtitle,
		COUNT(*) as total	
FROM	HR
WHERE	termdate IS NULL
GROUP BY jobtitle
ORDER BY total DESC

-- 8. Which department has the highest turnover rate?

WITH turn_over AS
			(
			SELECT	department,
					COUNT(*) as total_count,
					SUM(CASE WHEN termdate IS NOT NULL AND termdate <= GETDATE() THEN 1 ELSE 0 END) as terminated_count
					--DATEDIFF(YEAR,hire_date,termdate) as turn
			FROM	HR
			--WHERE	termdate IS NOT NULL
			GROUP BY department
			)

SELECT	department,
		total_count,
		terminated_count, 
		ROUND(CAST(terminated_count AS DECIMAL(10,2))/total_count,2) as termination_rate
FROM	turn_over
ORDER BY termination_rate DESC


-- 9. What is the distribution of employees across locations by city and state?

SELECT	location,
		location_state,
		location_city,
		COUNT(*) AS total
FROM	HR
WHERE	termdate IS NULL
GROUP BY location,location_city,location_state
ORDER BY total DESC



-- 10. How has the company's employee count changed over time based on hire and term dates?
WITH CTE AS
		(
		SELECT	YEAR(hire_date) AS year,
				COUNT(*) AS hires,
				SUM(CASE WHEN termdate IS NOT NULL AND termdate <= GETDATE() THEN 1 ELSE 0 END) terminations					
		FROM	HR
		GROUP BY YEAR(hire_date)
		)
SELECT	year,
		hires,
		terminations,
		hires - terminations AS net_change,
		ROUND(CAST((hires - terminations) AS DECIMAL (10,2))/hires *100,2) AS net_change_percent
FROM	CTE
ORDER BY year ASC

-- 11. What is the tenure distribution for each department?

SELECT	department,
		ROUND(AVG(DATEDIFF(year,hire_date,termdate)),2) as avg_tenure
FROM	HR
WHERE	termdate <= GETDATE() AND termdate IS NOT NULL
GROUP BY department
ORDER BY avg_tenure DESC
