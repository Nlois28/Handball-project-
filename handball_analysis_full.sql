/* ===============================================================================
HANDBALL BUNDESLIGA 2023 - COMPLETE DATA ANALYTICS WORKFLOW
Author: [Το Όνομά Σου]
Tools: SQL (BigQuery), Looker Studio
===============================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. DATA PREPARATION & CLEANING
-- ----------------------------------------------------------------------------
/*I created a table that is called  handball_stats_bundesliga,  so that i can clean my data.
Removed duplicate data*/
SELECT *
FROM (
select distinct NAME
from `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
qualify ROW_NUMBER() OVER (PARTITION BY NAME ORDER BY G DESC)=1
)

--Renamed columns
ALTER TABLE `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
RENAME COLUMN `%` TO PERCENTAGE,
RENAME COLUMN `AS` TO ASSISTS,
RENAME COLUMN P TO GAMES_PLAYED,
RENAME COLUMN G TO TOTAL_GOALS,
RENAME COLUMN M TO GAMES_STARTED,
RENAME COLUMN FG TO FIELD_GOALS,
RENAME COLUMN G_1 TO GOALS_PER_GAME,
RENAME COLUMN TF TO TURNOVERS,
RENAME COLUMN ST TO STEALS,
RENAME COLUMN BL TO BLOCKS;

--Converted types
In column `percentages` i run a function so it can have only 2 digits.
update
`handball.handball_stats_bundesliga`
set PERCENTAGE = round(PERCENTAGE, 2)
where PERCENTAGE is not null


--Then 
update
`handball.handball_stats_bundesliga`
set PERCENTAGE = cast(round(PERCENTAGE * 100, 0) as int64)
where PERCENTAGE is not null

--I changed the name of goals_per_game to penalty_shots because it was the right name to put.
alter table `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
rename column GOALS_PER_GAME to
Penalty_shots;

--I substituted all the null data (if existed) with zero


update
`handball.handball_stats_bundesliga`
SET
  ASSISTS = IFNULL(ASSISTS, 0),
  TURNOVERS = IFNULL(TURNOVERS, 0),
  STEALS = IFNULL(STEALS, 0),
  BLOCKS = IFNULL(BLOCKS, 0),
  YC = IFNULL(YC, 0),
  `2MIN` = IFNULL(`2MIN`, 0),
  RC = IFNULL(RC, 0),
  PENALTY_SHOTS = IFNULL(PENALTY_SHOTS, 0)
WHERE true;

--I searched for outliers with no data to display.


SELECT * FROM `handball.handball_stats_bundesliga`
WHERE TOTAL_GOALS > 500 OR TOTAL_GOALS < 0;

--Validated data


-Logic check with no data to display
SELECT NAME, TOTAL_GOALS, MISSED_SHOTS, FIELD_GOALS
FROM `handball.handball_stats_bundesliga`
WHERE TOTAL_GOALS < FIELD_GOALS  -- this would be a mistake
   OR TOTAL_GOALS < 0;

- Null prices with no data to display
SELECT COUNT(*) as missing_values
FROM `handball.handball_stats_bundesliga`
WHERE PERCENTAGE IS NULL
   OR HPI IS NULL
   OR NAME IS NULL;
-Checked for range validation
SELECT
    MIN(PERCENTAGE) as min_perc,
    MAX(PERCENTAGE) as max_perc,
    MIN(TOTAL_GOALS) as min_goals,
    MAX(TOTAL_GOALS) as max_goals
FROM `handball.handball_stats_bundesliga`;




Uniqueness check with no data to display
SELECT NAME, COUNT(*)
FROM `handball.handball_stats_bundesliga`
GROUP BY NAME
HAVING COUNT(*) > 1;

--Who were the top scorers?

SELECT
    NAME,
    TOTAL_GOALS,
    CLUB,
    POSITION,
    GAMES_PLAYED
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
ORDER BY TOTAL_GOALS DESC

--who had the most assists?(best playmaker)
SELECT
    NAME,
    ASSISTS,
    CLUB,
    POSITION,
    GAMES_PLAYED
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
ORDER BY ASSISTS DESC

--who had the most blocks and steals?(best defender)


SELECT NAME, CLUB, (BLOCKS + STEALS) AS DEFENSIVE_ACTIONS
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
ORDER BY DEFENSIVE_ACTIONS DESC

--who had the most 2 minutes and red cards?

SELECT NAME, CLUB, `2MIN`, RC
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
ORDER BY RC DESC, `2MIN` DESC


--who had the best shooting percentage?

SELECT
    NAME,
    club,
    PERCENTAGE,
    MISSED_SHOTS,
    TOTAL_GOALS
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
WHERE TOTAL_GOALS > 60
ORDER BY PERCENTAGE DESC;

--who had the best hpi?

SELECT
    NAME,
    club,
    HPI
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
ORDER BY HPI DESC;

--which team had the most shooters in the top 50?

WITH Top50Players AS (
    SELECT
        NAME,
        CLUB
    FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
    ORDER BY HPI DESC
    LIMIT 50
)
SELECT
    club,
    COUNT(*) AS player_count
FROM Top50Players
GROUP BY club
ORDER BY player_count DESC;


--What is the correlation between effectiveness and hpi?

SELECT
    NAME,
    CLUB,
    PERCENTAGE,
    HPI
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
WHERE TOTAL_GOALS > 30
ORDER BY HPI DESC
LIMIT 20;
SELECT
    CORR(PERCENTAGE, HPI) AS correlation_efficiency_hpi
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
WHERE TOTAL_GOALS > 40;

--which players have >55%, more than 30 assists and less than 40 technical errors?

SELECT
    NAME,
    CLUB,
    PERCENTAGE,
    ASSISTS,
    TURNOVERS,
    HPI
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
WHERE PERCENTAGE > 55
  AND ASSISTS > 30
  AND TURNOVERS < 40
ORDER BY HPI DESC;


--which players have the biggest sum of steals and blocks compared the 2 minutes suspensions?

SELECT
    NAME,
    CLUB,
    STEALS,
    BLOCKS,
    `2MIN` AS suspensions,
    (STEALS + BLOCKS) AS total_defensive_actions,
    SAFE_DIVIDE((STEALS + BLOCKS), `2MIN`) AS clean_defense_ratio
FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
WHERE `2MIN` > 5
  AND (STEALS + BLOCKS) > 10
ORDER BY clean_defense_ratio DESC;


--Are the teams with the most players in the top 50 hpi in the top of the championship?

WITH Top50Players AS (
    SELECT
        NAME,
        CLUB,
        HPI
    FROM `lithe-aileron-433816-k5.handball.handball_stats_bundesliga`
    ORDER BY HPI DESC
    LIMIT 50
)
SELECT
    club,
    COUNT(*) AS players_in_top_50,
    ROUND(AVG(HPI), 1) AS average_hpi_of_top_players
FROM Top50Players
GROUP BY club
ORDER BY players_in_top_50 DESC;
