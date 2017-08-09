
-- ************************************************************************
--
-- GIT Header
--
-- $Format:Git ID: (%h) %ci$
-- Version hash: $Format:%H$
--
-- Description:
--
-- Rapid Enquiry Facility (RIF) - Load SEER data; reformat into RIF4.0 format. Does not load into RIF (see rif40_load_seer.sql)
--
--
-- Copyright:
--
-- The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
-- that rapidly addresses epidemiological and public health questions using 
-- routinely collected health and population data and generates standardised 
-- rates and relative risks for any given health outcome, for specified age 
-- and year ranges, for any given geographical area.
--
-- Copyright 2014 Imperial College London, developed by the Small Area
-- Health Statistics Unit. The work of the Small Area Health Statistics Unit 
-- is funded by the Public Health England as part of the MRC-PHE Centre for 
-- Environment and Health. Funding for this project has also been received 
-- from the Centers for Disease Control and Prevention.  
--
-- This file is part of the Rapid Inquiry Facility (RIF) project.
-- RIF is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- RIF is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
-- to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
-- Boston, MA 02110-1301 USA
--
-- Author:
--
-- Peter Hambly, SAHSU
--
-- Usage: psql -U rif40 -w -e -f load_seer.sql 
-- Connect flags if required: -d <Postgres database name> -h <host> -p <port>
--
-- Requires RIF USA county level geography to be loaded: rif_pg_USA_2014.sql
-- Also requires USA county level base tables to be loaded: pg_USA_2014.sql
--
\pset pager off
\set ECHO all
\set ON_ERROR_STOP ON
\timing

BEGIN TRANSACTION;

DROP TABLE IF EXISTS seer9_yr1973_2013_fixed_length;
DROP TABLE IF EXISTS seer9_yr1973_2013;

--
-- Load singleages.txt as a fixed length record
--
CREATE TABLE seer9_yr1973_2013_fixed_length (
	record_value VARCHAR(358)
);
/*
C:\Users\Peter\Documents\Local data loading>wc -l SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9*.TXT
    769261 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/BREAST.TXT
    528452 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/COLRECT.TXT
    364018 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/DIGOTHR.TXT
    434960 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/FEMGEN.TXT
    381579 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/LYMYLEUK.TXT
    636118 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/MALEGEN.TXT
    784697 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/OTHER.TXT
    643924 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/RESPIR.TXT
    320405 SEER_1973_2013_TEXTDATA/incidence/yr1973_2013.seer9/URINARY.TXT
   4863414 total
 */

\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\BREAST.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\COLRECT.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\DIGOTHR.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\FEMGEN.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\LYMYLEUK.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\MALEGEN.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\OTHER.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\RESPIR.TXT' WITH CSV;
\copy seer9_yr1973_2013_fixed_length FROM 'SEER_1973_2013_TEXTDATA\incidence\yr1973_2013.seer9\URINARY.TXT' WITH CSV;

--
-- Check rowcount
--
SELECT COUNT(*) AS total FROM seer9_yr1973_2013_fixed_length;
DO LANGUAGE plpgsql $$
DECLARE
	c1 CURSOR FOR
		SELECT COUNT(*) AS total
 		  FROM seer9_yr1973_2013_fixed_length;
	c1_rec RECORD;
BEGIN
	OPEN c1;
	FETCH c1 INTO c1_rec;
	CLOSE c1;
--
	IF c1_rec.total = 4863414 THEN
		RAISE INFO 'Table: seer9_yr1973_2013_fixed_length has % rows', c1_rec.total;
	ELSE
		RAISE EXCEPTION 'Table: seer9_yr1973_2013_fixed_length has % rows; expecting 4863414', c1_rec.total;
	END IF;
END;
$$;

--
-- Convert datatypes
--
CREATE TABLE seer9_yr1973_2013
AS
SELECT SUBSTRING(record_value FROM 39 FOR 4)::INTEGER AS year_dx,	/* Year of diagnosis */
       SUBSTRING(record_value FROM 24 FOR 1)::INTEGER AS sex,		/* Sex */
       SUBSTRING(record_value FROM 25 FOR 3)::INTEGER AS age_dx, 	/* Age at diagnosis */
       SUBSTRING(record_value FROM 246 FOR 2)::Text AS state_fips_code,	 /* State FIPS code */
       SUBSTRING(record_value FROM 248 FOR 3)::Text AS county_fips_code, /* County FIPS code */ 
       SUBSTRING(record_value FROM 208 FOR 4)::Text AS icdot10v, 	/* Recode ICD-O-2 to 10 */
       SUBSTRING(record_value FROM 1 FOR 8)::INTEGER AS pubcsnum,	/* Patient ID */
       SUBSTRING(record_value FROM 35 FOR 2)::INTEGER AS seq_num,  	/* Sequence number */
       SUBSTRING(record_value FROM 53 FOR 4)::Text AS histo3v,		/* Histologic Type ICD-O-3 */
       SUBSTRING(record_value FROM 57 FOR 1)::Text AS beho3v,		/* Behavior code ICD-O-3 */
       SUBSTRING(record_value FROM 233 FOR 1)::INTEGER AS rac_reca,	/* Race recode A (WHITE, BLACK, OTHER) */
       SUBSTRING(record_value FROM 234 FOR 1)::INTEGER AS rac_recy,	/* Race recode Y (W, B, AI, API) */	  
       SUBSTRING(record_value FROM 235 FOR 1)::INTEGER AS origrecb,	/* Origin Recode NHIA (HISPANIC, NON-HISP) */	 
       SUBSTRING(record_value FROM 255 FOR 5)::Text AS codpub,	  	/* Cause of death to SEER site recode (see: https://seer.cancer.gov/codrecode/1969+_d09172004/index.html) */
       SUBSTRING(record_value FROM 9 FOR 10)::INTEGER AS reg		/* SEER registry */   
  FROM seer9_yr1973_2013_fixed_length;

/* Cancer reigsatry codes:

Code			Description (first year of data)
0000001501		San Francisco-Oakland SMSA (1973)
0000001502		Connecticut (1973)
0000001520		Metropolitan Detroit (1973)
0000001521		Hawaii (1973)
0000001522		Iowa (1973)
0000001523		New Mexico (1973)
0000001525		Seattle (Puget Sound) (1974)
0000001526		Utah (1973)
0000001527		Metropolitan Atlanta (1975)
0000001529		Alaska*
0000001531		San Jose-Monterey*
0000001535		Los Angeles*
0000001537		Rural Georgia*
0000001541		Greater California (excluding SF, Los Angeles & SJ)**
0000001542		Kentucky**
0000001543		Louisiana**
0000001544		New Jersey**
0000001547		Greater Georgia (excluding AT and RG)**
(Year in parentheses refers to first diagnosis year data reported to SEER)

*Note: The incidence/yr1992_2013.sj_la_rg_ak directory files contain cases for Alaska, San Jose-Monterey, Los Angeles and 
       Rural Georgia registries beginning in 1992. Cases have been collected by SEER for these registries prior to 1992 but have 
       been excluded from the SEER Research Data file.
**Note: The incidence/yr2000_2013.ca_ky_lo_nj_ga directory files contain cases for Greater California, Kentucky, Louisiana, 
        New Jersey and Greater Georgia registries beginning in 2000. For the year 2005, only January through June diagnoses are
		included for Louisiana. The July through December incidence cases can be found in the yr2005.lo_2nd_half directory.
*/  

--
-- Extract cancer
-- * Convert age, sex to RIF age_sex_group 1
-- * Convert FIPS codes to the geographic Names Information System (GNIS) codes used by the RIF
-- * Enforce primary key (Patient ID, Sequence number)
-- * Check AGE_SEX_GROUP, handle uncoded age
-- * Convert unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g.
--   900 series to represent county/independent city combinations in Virginia.
-- * Use icdot10v (ICD 10 site code - recoded from ICD-O-2 to 10) as the ICD field
--
DROP TABLE IF EXISTS seer_cancer;  
CREATE TABLE seer_cancer
AS  
SELECT a.year_dx AS year, 
	   'US'::Text AS cb_2014_us_nation_5m,
       d.statens AS cb_2014_us_state_500k, 
       COALESCE(c.countyns, 'UNKNOWN: '||a.county_fips_code) AS cb_2014_us_county_500k,
	   (a.sex*100)+
			CASE WHEN a.age_dx = 999 THEN 99
			ELSE                     b.offset END AS age_sex_group, 
	   a.icdot10v,		/* ICD 10 site code - recoded from ICD-O-2 to 10 */
	   a.pubcsnum,		/* Patient ID */
	   a.seq_num,		/* Sequence number */
       a.histo3v,		/* Histologic Type ICD-O-3 */
       a.beho3v,		/* Behavior code ICD-O-3 */
       a.rac_reca,		/* Race recode A (WHITE, BLACK, OTHER) */
       a.rac_recy,		/* Race recode Y (W, B, AI, API) */	   
	   a.origrecb,		/* Origin Recode NHIA (HISPANIC, NON-HISP) */
	   a.codpub,	  	/* Cause of death to SEER site recode (see: https://seer.cancer.gov/codrecode/1969+_d09172004/index.html) */
       a.reg-1500 AS reg		/* SEER registry (minus 1500 so same as population file) */   	   
  FROM seer9_yr1973_2013 a
		LEFT OUTER JOIN rif40_age_groups b ON (b.age_group_id = 1 AND a.age_dx BETWEEN b.low_age AND b.high_age /* limit 255! */)
		LEFT OUTER JOIN cb_2014_us_county_500k c ON (a.state_fips_code = c.statefp AND a.county_fips_code = c.countyfp)
		LEFT OUTER JOIN cb_2014_us_state_500k d ON (a.state_fips_code = d.statefp)
 ORDER BY a.pubcsnum, a.seq_num;
 
COMMENT ON TABLE seer_cancer IS 'SEER Cancer data 1973-2013. 9 States in total';
COMMENT ON COLUMN seer_cancer.year IS 'Year';
COMMENT ON COLUMN seer_cancer.cb_2014_us_nation_5m IS 'United States to county level including territories';
COMMENT ON COLUMN seer_cancer.cb_2014_us_state_500k IS 'State geographic Names Information System (GNIS) code';
COMMENT ON COLUMN seer_cancer.cb_2014_us_county_500k IS 'County geographic Names Information System (GNIS) code. Unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g. the 900 series to represent county/independent city combinations in Virginia.';
COMMENT ON COLUMN seer_cancer.age_sex_group IS 'RIF age_sex_group 1 (21 bands)';
COMMENT ON COLUMN seer_cancer.icdot10v IS 'ICD 10 site code - recoded from ICD-O-2 to 10';
COMMENT ON COLUMN seer_cancer.pubcsnum IS 'Patient ID';
COMMENT ON COLUMN seer_cancer.seq_num IS 'Sequence number';
COMMENT ON COLUMN seer_cancer.histo3v IS 'Histologic Type ICD-O-3';
COMMENT ON COLUMN seer_cancer.beho3v IS 'Behavior code ICD-O-3';
COMMENT ON COLUMN seer_cancer.rac_reca IS 'Race recode A (WHITE, BLACK, OTHER)';
COMMENT ON COLUMN seer_cancer.rac_recy IS 'Race recode Y (W, B, AI, API)';
COMMENT ON COLUMN seer_cancer.origrecb IS 'Origin Recode NHIA (HISPANIC, NON-HISP)';
COMMENT ON COLUMN seer_cancer.codpub IS 'Cause of death to SEER site recode (see: https://seer.cancer.gov/codrecode/1969+_d09172004/index.html)';
COMMENT ON COLUMN seer_cancer.reg IS 'SEER registry (minus 1500 so same as population file)';

--
-- Check rowcount
--
SELECT COUNT(*) AS total FROM seer_cancer;
DO LANGUAGE plpgsql $$
DECLARE
	c1 CURSOR FOR
		SELECT COUNT(*) AS total
 		  FROM seer_cancer;
	c1_rec RECORD;
BEGIN
	OPEN c1;
	FETCH c1 INTO c1_rec;
	CLOSE c1;
--
	IF c1_rec.total = 4863414 THEN
		RAISE INFO 'Table: seer_cancer has % rows', c1_rec.total;
	ELSE
		RAISE EXCEPTION 'Table: seer_cancer has % rows; expecting 4863414', c1_rec.total;
	END IF;
END;
$$;

ALTER TABLE seer_cancer ALTER COLUMN year SET NOT NULL;
ALTER TABLE seer_cancer ALTER COLUMN cb_2014_us_state_500k SET NOT NULL;
ALTER TABLE seer_cancer ALTER COLUMN cb_2014_us_county_500k SET NOT NULL;

ALTER TABLE seer_cancer ADD CONSTRAINT seer_cancer_asg_ck 
	CHECK (age_sex_group BETWEEN 100 AND 121 OR age_sex_group BETWEEN 200 AND 221 OR age_sex_group IN (199, 299) /* No age coded */);
	
ALTER TABLE seer_cancer ALTER COLUMN age_sex_group SET NOT NULL;

\copy seer_cancer TO 'seer_cancer.csv' WITH CSV HEADER;
\dS+ seer_cancer
 
ALTER TABLE seer_cancer ADD CONSTRAINT seer_cancer_pk 
	PRIMARY KEY (pubcsnum, seq_num);	
CREATE INDEX seer_cancer_year ON seer_cancer (year);
CREATE INDEX seer_cancer_cb_2014_us_nation_5m ON seer_cancer(cb_2014_us_nation_5m);
CREATE INDEX seer_cancer_cb_2014_us_state_500k ON seer_cancer(cb_2014_us_state_500k);
CREATE INDEX seer_cancer_cb_2014_us_county_500k ON seer_cancer(cb_2014_us_county_500k);
CREATE INDEX seer_cancer_age_sex_group ON seer_cancer(age_sex_group);
CREATE INDEX seer_cancer_icdot10v ON seer_cancer(icdot10v);	
CREATE INDEX seer_cancer_reg ON seer_cancer(reg);	
	
--END;	
--\q
  
DROP TABLE IF EXISTS seer_wbo_single_ages_fixed_length;
DROP TABLE IF EXISTS seer_wbo_single_ages;

--
-- Load singleages.txt as a fixed length record
--
CREATE TABLE seer_wbo_single_ages_fixed_length (
	record_value VARCHAR(28)
);

-- wc -l SEER_1973_2013_TEXTDATA\populations\white_black_other\yr1973_2013.seer9\singleages.txt
\copy seer_wbo_single_ages_fixed_length FROM 'SEER_1973_2013_TEXTDATA\populations\white_black_other\yr1973_2013.seer9\singleages.txt' WITH CSV;

--
-- Check rowcount
--
SELECT COUNT(*) AS total FROM seer_wbo_single_ages_fixed_length;
DO LANGUAGE plpgsql $$
DECLARE
	c1 CURSOR FOR
		SELECT COUNT(*) AS total
 		  FROM seer_wbo_single_ages_fixed_length;
	c1_rec RECORD;
BEGIN
	OPEN c1;
	FETCH c1 INTO c1_rec;
	CLOSE c1;
--
	IF c1_rec.total = 2764264 THEN
		RAISE INFO 'Table: seer_wbo_single_ages_fixed_length has % rows', c1_rec.total;
	ELSE
		RAISE EXCEPTION 'Table: seer_wbo_single_ages_fixed_length has % rows; expecting 2764264', c1_rec.total;
	END IF;
END;
$$;

--
-- Convert datatypes
--
CREATE TABLE seer_wbo_single_ages
AS
SELECT SUBSTRING(record_value FROM 1 FOR 4)::INTEGER AS year,
       SUBSTRING(record_value FROM 5 FOR 2) AS state_postal_abbreviation,
       SUBSTRING(record_value FROM 7 FOR 2)::Text AS state_fips_code,
       SUBSTRING(record_value FROM 9 FOR 3)::Text AS county_fips_code,
       SUBSTRING(record_value FROM 12 FOR 2)::INTEGER AS registry,
       SUBSTRING(record_value FROM 14 FOR 1)::INTEGER AS race,
       SUBSTRING(record_value FROM 15 FOR 1)::INTEGER AS origin,
       SUBSTRING(record_value FROM 16 FOR 1)::INTEGER AS sex,
       SUBSTRING(record_value FROM 17 FOR 2)::INTEGER AS age,
       SUBSTRING(record_value FROM 19 FOR 10)::NUMERIC AS population
  FROM seer_wbo_single_ages_fixed_length;
/* 
 * Registry codes:
 *
	01 = San Francisco-Oakland SMSA
	02 = Connecticut
	20 = Detroit (Metropolitan)
	21 = Hawaii
	22 = Iowa
	23 = New Mexico
	25 = Seattle (Puget Sound)
	26 = Utah
	27 = Atlanta (Metropolitan)
	29 = Alaska Natives
	31 = San Jose-Monterey
	35 = Los Angeles
	37 = Rural Georgia
	41 = California excluding SF/SJM/LA
	42 = Kentucky
	43 = Louisiana
	44 = New Jersey
	47 = Greater Georgia
 */
 
--
-- Extract population
-- * Convert age, sex to RIF age_sex_group 1
-- * Convert FIPS codes to the geographic Names Information System (GNIS) codes used by the RIF
-- * Enforce primary key
-- * Check AGE_SEX_GROUP
-- * Convert unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g.
--   900 series to represent county/independent city combinations in Virginia.
--
DROP TABLE IF EXISTS seer_population;  
CREATE TABLE seer_population
AS  
SELECT a.year, 
	   'US'::Text AS cb_2014_us_nation_5m,
       d.statens AS cb_2014_us_state_500k, 
       COALESCE(c.countyns, 'UNKNOWN: '||a.county_fips_code) AS cb_2014_us_county_500k,
	   (a.sex*100)+b.offset AS age_sex_group, 
       SUM(a.population) AS population
  FROM seer_wbo_single_ages a
		LEFT OUTER JOIN rif40_age_groups b ON (b.age_group_id = 1 AND a.age BETWEEN b.low_age AND b.high_age)
		LEFT OUTER JOIN cb_2014_us_county_500k c ON (a.state_fips_code = c.statefp AND a.county_fips_code = c.countyfp)
		LEFT OUTER JOIN cb_2014_us_state_500k d ON (a.state_fips_code = d.statefp)
 GROUP BY a.year, d.statens, COALESCE(c.countyns, 'UNKNOWN: '||a.county_fips_code), a.sex, b.offset
 ORDER BY 1,2,3,4,5;
 
COMMENT ON TABLE seer_population IS 'SEER Population 1972-2013. Georgia starts in 1975, Washington in 1974. 9 States in total';
COMMENT ON COLUMN seer_population.year IS 'Year';
COMMENT ON COLUMN seer_population.cb_2014_us_nation_5m IS 'United States to county level including territories';
COMMENT ON COLUMN seer_population.cb_2014_us_state_500k IS 'State geographic Names Information System (GNIS) code';
COMMENT ON COLUMN seer_population.cb_2014_us_county_500k IS 'County geographic Names Information System (GNIS) code. Unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g. the 900 series to represent county/independent city combinations in Virginia.';
COMMENT ON COLUMN seer_population.age_sex_group IS 'RIF age_sex_group 1 (21 bands)';
COMMENT ON COLUMN seer_population.population IS 'Population';

--
-- Check rowcount
--
SELECT COUNT(*) AS total FROM seer_population;
DO LANGUAGE plpgsql $$
DECLARE
	c1 CURSOR FOR
		SELECT COUNT(*) AS total
 		  FROM seer_population;
	c1_rec RECORD;
BEGIN
	OPEN c1;
	FETCH c1 INTO c1_rec;
	CLOSE c1;
--
	IF c1_rec.total = 354326 THEN
		RAISE INFO 'Table: seer_population has % rows', c1_rec.total;
	ELSE
		RAISE EXCEPTION 'Table: seer_population has % rows; expecting 354326', c1_rec.total;
	END IF;
END;
$$;
 
ALTER TABLE seer_population ADD CONSTRAINT seer_population_pk 
	PRIMARY KEY (year, cb_2014_us_nation_5m, cb_2014_us_state_500k, cb_2014_us_county_500k, age_sex_group);	
ALTER TABLE seer_population ADD CONSTRAINT seer_population_asg_ck 
	CHECK (age_sex_group BETWEEN 100 AND 121 OR age_sex_group BETWEEN 200 AND 221);

CLUSTER seer_population USING seer_population_pk;
CREATE INDEX seer_population_year ON seer_population (year);
CREATE INDEX seer_population_cb_2014_us_nation_5m ON seer_population(cb_2014_us_nation_5m);
CREATE INDEX seer_population_cb_2014_us_state_500k ON seer_population(cb_2014_us_state_500k);
CREATE INDEX seer_population_cb_2014_us_county_500k ON seer_population(cb_2014_us_county_500k);
CREATE INDEX seer_population_age_sex_group ON seer_population(age_sex_group);

\copy seer_population TO 'seer_population.csv' WITH CSV HEADER;
\dS+ seer_population
 
-- 
-- Extract ethnicity covariates
-- * Convert age, sex to RIF age_sex_group 1
-- * Convert FIPS codes to the geographic Names Information System (GNIS) codes used by the RIF
-- * Enforce primary key
-- * Check AGE_SEX_GROUP
-- * Convert unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g.
--   900 series to represent county/independent city combinations in Virginia.
--
DROP TABLE IF EXISTS seer_wbo_ethnicity; 
CREATE TABLE seer_wbo_ethnicity
AS  
WITH a AS (
	SELECT a.year, 
	       'US'::Text AS cb_2014_us_nation_5m,
	       d.statens AS cb_2014_us_state_500k, 
		   COALESCE(c.countyns, 'UNKNOWN: '||a.county_fips_code) AS cb_2014_us_county_500k,
		   CASE WHEN a.year < 1992 AND a.race = 3 /* Recode other to 9 */ THEN 9 ELSE a.race END AS race, 
		   a.origin,
		   SUM(a.population) AS population
	  FROM seer_wbo_single_ages a
			LEFT OUTER JOIN rif40_age_groups b ON (b.age_group_id = 1 AND a.age BETWEEN b.low_age AND b.high_age)
			LEFT OUTER JOIN cb_2014_us_county_500k c ON (a.state_fips_code = c.statefp AND a.county_fips_code = c.countyfp)
			LEFT OUTER JOIN cb_2014_us_state_500k d ON (a.state_fips_code = d.statefp)
	 GROUP BY a.year, d.statens, 
			  COALESCE(c.countyns, 'UNKNOWN: '||a.county_fips_code), 
			  CASE WHEN a.year < 1992 AND a.race = 3 /* Recode other to 9 */ THEN 9 ELSE a.race END, a.origin
)
SELECT year, cb_2014_us_nation_5m, cb_2014_us_state_500k, cb_2014_us_county_500k, 
      (10*race)+COALESCE(origin, 0) AS ethnicity, a.population
  FROM a
 ORDER BY 1,2,3,4,5;

COMMENT ON TABLE seer_wbo_ethnicity IS 'SEER Ethnicity 1972-2013; white/blacks/other + hispanic/non-hispanic. 9 States in total';
COMMENT ON COLUMN seer_wbo_ethnicity.year IS 'Year';
COMMENT ON COLUMN seer_wbo_ethnicity.cb_2014_us_nation_5m IS 'United States to county level including territories';
COMMENT ON COLUMN seer_wbo_ethnicity.cb_2014_us_state_500k IS 'State geographic Names Information System (GNIS) code';
COMMENT ON COLUMN seer_wbo_ethnicity.cb_2014_us_county_500k IS 'County geographic Names Information System (GNIS) code. Unjoined county FIPS codes to "UNKNOWN: " + county FIPS code; e.g. the 900 series to represent county/independent city combinations in Virginia.';
COMMENT ON COLUMN seer_wbo_ethnicity.ethnicity IS 'Ethnicity coded 19: White; 29: Black, 39: American Indian/Alaska Native (1992 onwards); 99: Other (1973-1991); all with no hispanic data ';
COMMENT ON COLUMN seer_wbo_ethnicity.population IS 'Population'; 

-- 
-- Add PK, make index organised table
--
ALTER TABLE seer_wbo_ethnicity ADD CONSTRAINT seer_wbo_ethnicity_pk 
	PRIMARY KEY (year, cb_2014_us_state_500k, cb_2014_us_county_500k, ethnicity);
CLUSTER seer_wbo_ethnicity USING seer_wbo_ethnicity_pk;

CREATE INDEX seer_wbo_ethnicity_year ON seer_wbo_ethnicity (year);
CREATE INDEX seer_wbo_ethnicity_cb_2014_us_nation_5m ON seer_wbo_ethnicity(cb_2014_us_nation_5m);
CREATE INDEX seer_wbo_ethnicity_cb_2014_us_state_500k ON seer_wbo_ethnicity(cb_2014_us_state_500k);
CREATE INDEX seer_wbo_ethnicity_cb_2014_us_county_500k ON seer_wbo_ethnicity(cb_2014_us_county_500k);
CREATE INDEX seer_wbo_ethnicity_ethnicity ON seer_wbo_ethnicity(ethnicity);

\copy seer_wbo_ethnicity TO 'seer_wbo_ethnicity.csv' WITH CSV HEADER;
\dS+ seer_wbo_ethnicity
 
END;

--
-- Analyse tables
--
ANALYZE VERBOSE seer_cancer;
ANALYZE VERBOSE seer_population;
ANALYZE VERBOSE seer_wbo_ethnicity;

--
-- Eof