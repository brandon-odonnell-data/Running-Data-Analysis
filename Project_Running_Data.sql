/** 
Analysis of data collected from fitness devices linked with the Strava API in 2019.
Dataset is sample of 116 amateur runners that consented to share nearly 42 000 runs. 
Dataset was obtained from Kaggle (https://www.kaggle.com/datasets/olegoaer/running-races-strava).
Where relevant, runs are filtered to exclude those below 100 m in length and with times of 0 s.
Dataset was meant to be cleared of outliers prior to this analysis, but initial checks highlighted
speeds vastly above the world record of 10.44 m/s set by Usain Bolt in 2009; rows yielding such
speeds are filtered out where relevant.
**/


-- Query all data.
SELECT *
FROM Project_Running_Data..running_data_strava;


-- Rename column headings.
EXEC sp_rename 'Project_Running_Data..running_data_strava.distance (m)', 'distance_m', 'COLUMN'
EXEC sp_rename 'Project_Running_Data..running_data_strava.elapsed time (s)', 'elapsed_time_s', 'COLUMN'
EXEC sp_rename 'Project_Running_Data..running_data_strava.elevation gain (m)', 'elevation_gain_m', 'COLUMN'
EXEC sp_rename 'Project_Running_Data..running_data_strava.average heart rate (bpm)', 'avg_heart_rate_bpm', 'COLUMN';


-- Query table information.
SELECT * 
FROM information_schema.columns;


-- Convert data types for possible aggegrations.
ALTER TABLE Project_Running_Data..running_data_strava
    ALTER COLUMN distance_m FLOAT NULL
ALTER TABLE Project_Running_Data..running_data_strava
    ALTER COLUMN elapsed_time_s INT NULL
ALTER TABLE Project_Running_Data..running_data_strava
    ALTER COLUMN elevation_gain_m FLOAT NULL
ALTER TABLE Project_Running_Data..running_data_strava
    ALTER COLUMN avg_heart_rate_bpm FLOAT NULL;


-- Query data to identify null or blanks space values across columns.
SELECT 
	SUM(CASE WHEN athlete IS NULL THEN 1 ELSE 0 END) AS athlete_null,
	SUM(CASE WHEN athlete = ' ' THEN 1 ELSE 0 END) AS athlete_blank,
	SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_null,
	SUM(CASE WHEN gender = ' ' THEN 1 ELSE 0 END) AS gender_blank,
	SUM(CASE WHEN timestamp IS NULL THEN 1 ELSE 0 END) AS timestamp_null,
	SUM(CASE WHEN timestamp = ' ' THEN 1 ELSE 0 END) AS timestamp_blank,
	SUM(CASE WHEN distance_m IS NULL THEN 1 ELSE 0 END) AS dist_null,
	SUM(CASE WHEN distance_m = ' ' THEN 1 ELSE 0 END) AS dist_m_blank,
	SUM(CASE WHEN elapsed_time_s IS NULL THEN 1 ELSE 0 END) AS el_time_null,
	SUM(CASE WHEN elapsed_time_s = ' ' THEN 1 ELSE 0 END) AS el_time_blank,
	SUM(CASE WHEN elevation_gain_m IS NULL THEN 1 ELSE 0 END) AS el_gain_null,
	SUM(CASE WHEN elevation_gain_m = ' ' THEN 1 ELSE 0 END) AS el_gain_blank,
	SUM(CASE WHEN avg_heart_rate_bpm IS NULL THEN 1 ELSE 0 END) AS avg_hr_null,
	SUM(CASE WHEN avg_heart_rate_bpm = ' ' THEN 1 ELSE 0 END) AS avg_hr_blank
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;
/** 
FINDINGS
No null values, all empty cells are blank spaces.
Blank values not consistent across fields. 
Records will be kept to avoid massive loss of data overall.
**/


-- What are the numbers and percentages of men, women and unspecified?
SELECT
	COUNT(CASE WHEN rds.gender = ' ' THEN 1 END) AS num_blank,
	ROUND(COUNT(CASE WHEN rds.gender = ' ' THEN 1 END)/(COUNT(*)+.0)*100,2) AS perc_blank,
	COUNT(CASE WHEN rds.gender = 'F' THEN 1 END) AS num_f,
	ROUND(COUNT(CASE WHEN rds.gender = 'F' THEN 1 END)/(COUNT(*)+.0)*100,2) AS perc_f,
	COUNT(CASE WHEN rds.gender = 'M' THEN 1 END) AS num_m,
	ROUND(COUNT(CASE WHEN rds.gender = 'M' THEN 1 END)/(COUNT(*)+.0)*100,2) AS perc_m
FROM Project_Running_Data..running_data_strava AS rds
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;
/** 
FINDINGS
Unspecified: 355, 0.85%
Female: 9398, 22.48%
Male: 32047, 76.67%
**/


/**
What is the average distance run? Does it fit with the symbolic 10km?
What are the average minimum and maximum distances run?
**/
SELECT 
	ROUND(AVG(distance_m),0) AS avg_all_distances_m,
	ROUND(MAX(distance_m),0) AS max_all_distances_m,
	ROUND(MIN(distance_m),0) AS min_all_distances_m
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;
/** 
FINDINGS
Average: 11099 m (11 km, this does reflect the symbolic 10 km)
Max: 218950 m
Min: 100 m (limited to 100 m to ignore sub-100 m runs/races), 0.1 m otherwise
**/


-- What are the average distances run for men and women?
SELECT 
	gender,
	ROUND(AVG(distance_m),0) AS avg_all_distances_m,
	ROUND(MAX(distance_m),0) AS max_all_distances_m,
	ROUND(MIN(distance_m),0) AS min_all_distances_m
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44
GROUP BY gender
ORDER BY gender;
/** 
FINDINGS
Average: 9996 (unspecified), 10271 (female), 11353 (men)
Max: 43571 (unspecified), 120912 (female), 218950 (men)
Min: 756 (unspecified), 105 (female), 100 (men)
Average running distance is approximately the same for all genders.
Male top distance is nearly double that of female top distance.
**/


-- How do rankings by distance look? Men and women combined in particular.
SELECT TOP(10)
	gender,
	distance_m,
	RANK() OVER (ORDER BY distance_m DESC) AS dist_rank_m
FROM Project_Running_Data..running_data_strava
WHERE 
	gender = 'M' AND 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;

SELECT TOP(10)
	gender,
	distance_m,
	RANK() OVER (ORDER BY distance_m DESC) AS dist_rank_f
FROM Project_Running_Data..running_data_strava
WHERE gender = 'F' AND
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;

SELECT TOP(20)
	gender,
	distance_m,
	RANK() OVER (ORDER BY distance_m DESC) AS dist_rank_mf
FROM Project_Running_Data..running_data_strava
WHERE 
	gender IN('F','M') AND 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;
/** 
FINDINGS
Top 10 distances attributed to men.
3 women in top 20.
**/


-- What are the average distances for the top 10 runners (by distance) by gender?
WITH dist_top10 AS
(
    SELECT 
		gender,
		distance_m, 
        ROW_NUMBER() OVER (Partition By gender ORDER BY distance_m DESC) AS row_num
    FROM Project_Running_Data..running_data_strava
	WHERE 
		distance_m >= 100 AND
		elapsed_time_s > 0 AND
		distance_m / elapsed_time_s <= 10.44
)
SELECT 
	gender, 
	AVG(distance_m) AS avg_dist_top10,
	SUM(distance_m) AS sum_dist_top10
FROM dist_top10
WHERE row_num <= 10
GROUP BY gender;
/** 
FINDINGS
For average:
	Unspecified: 33506.02 m
	Female: 94646.24 m
	Male: 154649 m
	Average male distance for top 10 is 1.63 times that of females.
	63% difference between male and female average distance for top 10 of each.

For total:
	Unspecified: 335060.2 m
	Female: 946462.4 m
	Male: 1546490 m
	Total male distance for top 10 is 1.63 times that of females.
	63% difference between male and female average distance for top 10 of each.
**/


/**
Looking at longest run times:

What is the average time for all runs?
**/
SELECT 
	AVG(elapsed_time_s) AS avg_time_all_s
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;

-- What is the average time for all runs by gender?
SELECT 
	gender,
	AVG(elapsed_time_s) AS avg_time_s
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44
GROUP BY gender;

-- What is the average time for top 10 runs?
SELECT 
	AVG(elapsed_time_s) AS avg_time_top10_all
FROM (
	SELECT 
		elapsed_time_s, 
        ROW_NUMBER() OVER (ORDER BY elapsed_time_s DESC) AS row_num
    FROM Project_Running_Data..running_data_strava
	WHERE 
		distance_m >= 100 AND
		elapsed_time_s > 0 AND
		distance_m / elapsed_time_s <= 10.44
	) AS num_times_rows
WHERE row_num <= 10;

-- What is the average time for top 20 runs?
SELECT 
	AVG(elapsed_time_s) AS avg_time_top20_all
FROM (
	SELECT 
		elapsed_time_s, 
        ROW_NUMBER() OVER (ORDER BY elapsed_time_s DESC) AS row_num
    FROM Project_Running_Data..running_data_strava
	WHERE 
		distance_m >= 100 AND
		elapsed_time_s > 0 AND
		distance_m / elapsed_time_s <= 10.44
	) AS num_times_rows
WHERE row_num <= 20;

-- What is the average time for top 10 runs by gender?
SELECT 
	gender, 
	AVG(elapsed_time_s) AS avg_time_top10
FROM (
	SELECT 
		gender, 
		elapsed_time_s, 
        ROW_NUMBER() OVER (Partition By gender ORDER BY elapsed_time_s DESC) AS row_num
    FROM Project_Running_Data..running_data_strava
	WHERE 
		distance_m >= 100 AND
		elapsed_time_s > 0 AND
		distance_m / elapsed_time_s <= 10.44
	) AS num_times_rows
WHERE row_num <= 10
GROUP BY gender;
/** 
FINDINGS
Average all: 4271 s
For all average by:
	Unspecified: 3825 s
	Female: 4178 s
	Male: 4303 s
	Average male time is 1.03 times that of females.
	3.0% difference between male and female average time.

For top 10 average by:
	All: 506277 s
	Unspecified: 18429 s
	Female: 78535 s
	Male: 487628 s
	Average male time is 6.2 times that of females.
	520.9% difference between male and female average time.

For top 20 average all: 288329 s
**/


/**
Looking at speeds:

What is the average speed for all runs?
**/
SELECT 
	AVG(distance_m) / AVG(elapsed_time_s) AS avg_speed_all_ms
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44;

-- What is the average speed for all runs by gender?
SELECT 
	gender,
	AVG(distance_m) / AVG(elapsed_time_s) AS avg_speed_all_ms
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44
GROUP BY gender;

--CTE for use with following queries.
WITH speed_row_nums AS (
	SELECT
		gender,
		speed_ms,
		ROW_NUMBER() OVER (ORDER BY speed_ms DESC) AS row_num
	FROM (
		SELECT
			gender,
			distance_m / elapsed_time_s AS speed_ms
		FROM Project_Running_Data..running_data_strava
		WHERE 
			distance_m >= 100 AND
			elapsed_time_s > 0 AND
			distance_m / elapsed_time_s <= 10.44
		) AS speed_calcs
)

-- Using CTE speed_row_nums: What is the average speed for top 10 runs?
SELECT
	AVG(speed_ms) AS avg_speed_top10_ms
FROM speed_row_nums
WHERE row_num <= 10;

-- Using CTE speed_row_nums: What is the average speed for top 20 runs?
--SELECT
--	AVG(speed_ms) AS avg_speed_top20_ms
--FROM speed_row_nums
--WHERE row_num <= 20;

-- Using CTE speed_row_nums: What is the average speed for top 10 runs by gender?
--SELECT
--	gender,
--	AVG(speed_ms) AS avg_speed_top10_ms
--FROM speed_row_nums
--WHERE row_num <= 10
--GROUP BY gender;
/** 
FINDINGS
For average speed all: 2.6 m/s

For average speed all by gender:
	Unspecified: 2.6 m/s
	Female: 2.5 m/s
	Male: 2.6 m/s

For average speed all top 10: 9.0 m/s

For average speed all top 20: 8.6 m/s

For average speed top 10 by gender:
	Female: 8.9 m/s
	Male: 9.2 m/s
**/


-- What is the average of the average heart bpm (total and by gender)?
SELECT 
	gender,
	AVG(avg_heart_rate_bpm) AS avg_avg_heart_rate_bpm
FROM Project_Running_Data..running_data_strava
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44
GROUP BY gender;
/**
FINDINGS
Average of average heart bpm: 83.6 bpm
Unspecified: 85.5 bpm
Female: 77.8 bpm
Male: 85.3 bpm
Women appear to have a lower average heart rate when running.
**/


/**
Looking at time-related results (using varchar values rather than formal time analyses):

What is the average number of runs per week?
**/
WITH get_year AS (
	SELECT
		*,
		SUBSTRING(timestamp, 7, 4) AS year_sep
	FROM Project_Running_Data..running_data_strava
)

SELECT
	year_sep,
	COUNT(year_sep) AS runs_per_year,
	COUNT(CONVERT(FLOAT, year_sep)) / 52.0 AS avg_runs_per_week
FROM get_year
WHERE 
	distance_m >= 100 AND
	elapsed_time_s > 0 AND
	distance_m / elapsed_time_s <= 10.44
GROUP BY year_sep
ORDER BY avg_runs_per_week DESC;
/**
FINDINGS
Most runs recorded in 2019, with decreasing runs going back in years (2020 anomaly).
Same overall pattern for average runs per week.
**/

-- How many runs occur each season?
WITH get_month AS (
	SELECT
		SUBSTRING(timestamp, 4, 2) AS month_sep
	FROM Project_Running_Data..running_data_strava
)

SELECT
	SUM(CASE WHEN month_sep IN('03', '04', '05') THEN 1 ELSE 0 END) AS spring_count,
	SUM(CASE WHEN month_sep IN('06', '07', '08') THEN 1 ELSE 0 END) AS summer_count,
	SUM(CASE WHEN month_sep IN('09', '10', '11') THEN 1 ELSE 0 END) AS autumn_count,
	SUM(CASE WHEN month_sep IN('12', '01', '02') THEN 1 ELSE 0 END) AS winter_count
FROM get_month;
/**
FINDINGS
Similar number of runs across all four seasons.
Highest to lowest: autumn, spring, winter, summer
Surprising to see summer with fewest runs.
**/


/**
Query all data for additional table of 23 rows of sample data for male runner.
Sample data collected from Zeopoxa mobile app.
**/
SELECT *
FROM Project_Running_Data..sample_data_zeopoxa;


-- Full join with Strava data table for quick comparison of average running speed to that of average Strava speeds.
SELECT
	rds.gender,
	AVG(rds.distance_m) / AVG(rds.elapsed_time_s) AS avg_speed_all_ms,
	AVG(CONVERT(FLOAT, sdz.avg_speed_kph) * (1000.0 / 3600.0)) AS sample_avg_speed_ms
FROM Project_Running_Data..running_data_strava AS rds
FULL JOIN Project_Running_Data..sample_data_zeopoxa AS sdz
ON rds.athlete = sdz.athlete
GROUP BY rds.gender;
/**
FINDINGS
Sample athlete average speed between that of Strava men and women.
**/