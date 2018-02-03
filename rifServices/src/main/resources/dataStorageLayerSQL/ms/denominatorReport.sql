/**
 *
 * <hr>
 * The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
 * that rapidly addresses epidemiological and public health questions using 
 * routinely collected health and population data and generates standardised 
 * rates and relative risks for any given health outcome, for specified age 
 * and year ranges, for any given geographical area.
 *
 * Copyright 2017 Imperial College London, developed by the Small Area
 * Health Statistics Unit. The work of the Small Area Health Statistics Unit 
 * is funded by the Public Health England as part of the MRC-PHE Centre for 
 * Environment and Health. Funding for this project has also been received 
 * from the United States Centers for Disease Control and Prevention.  
 *
 * <pre> 
 * This file is part of the Rapid Inquiry Facility (RIF) project.
 * RIF is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * RIF is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
 * to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA 02110-1301 USA
 * </pre>
 *
 * <hr>
 * Peter Hambly
 * @author phambly
 *
 * SQL statement name: 	denominatorReport.sql
 * Type:				Microsoft SQL Server SQL
 * Parameters (preceded by %):
 *						1: Extract table name; e.g. s367_extract
 *
 * Description:			Denominator SQL report. Handles gendes: males, females or both
 * Note:				NO SUPPORT FOR ESCAPING!
 *						Requires rif40.generate_series() to be created to have the same functionality
 *						as Postgres version
 *
 * DO NOT EDIT THIS FILE UNLESS YOU WANT TO CHANGE THE HTML REPORT. 
 * COPY THE ORIGINAL TO %CATALINA_HOME%\conf\dataStorageLayerSQL\<dir> directory OR IT WILL BE 
 * OVERWRITTEN BY UPGRADES.
 *
 * <dir> is "ms", "pg" or "common" in the resources directory:
 * %CATALINA_HOME%\webapps\rifServices\WEB-INF\classes\dataStorageLayerSQL
 */
WITH a AS (
	SELECT study_or_comparison,
	       year, 
	       sex,
		   SUM(total_pop) AS total_pop
	  FROM %1
	 GROUP BY study_or_comparison, year, sex
), c AS (
	SELECT year, 
	       sex,
		   SUM(total_pop) AS total_pop
	  FROM a
	 WHERE study_or_comparison = 'C'
	 GROUP BY year, sex
), s AS (
	SELECT year, 
	       sex,
		   SUM(total_pop) AS total_pop
	  FROM a
	 WHERE study_or_comparison = 'S'
	 GROUP BY year, sex
), t AS (
	SELECT c.year, 
		   SUM(c.total_pop) AS comparison_both,
		   SUM(s.total_pop) AS study_both
	  FROM c, s
	 WHERE c.year = s.year
	 GROUP BY c.year
 )
 SELECT t.year,
        SUM(c1.total_pop) AS comparison_males, SUM(c2.total_pop) AS comparison_females, t.comparison_both,
        SUM(s1.total_pop) AS study_males, SUM(s2.total_pop) AS study_females, t.study_both
  FROM t
		LEFT OUTER JOIN c c1 ON (t.year = c1.year AND c1.sex = 1 /* Males */)
		LEFT OUTER JOIN c c2 ON (t.year = c2.year AND c2.sex = 2 /* Females */)
		LEFT OUTER JOIN s s1 ON (t.year = s1.year AND s1.sex = 1 /* Males */)
		LEFT OUTER JOIN s s2 ON (t.year = s2.year AND s2.sex = 2 /* Females */)
 GROUP BY t.year, t.comparison_both, t.study_both
 ORDER BY t.year;
