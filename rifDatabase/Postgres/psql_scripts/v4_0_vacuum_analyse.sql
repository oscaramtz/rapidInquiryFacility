-- ************************************************************************
--
-- GIT Header
--
-- $Format:Git ID: (%h) %ci$
-- $Id$
-- Version hash: $Format:%H$
--
-- Description:
--
-- Rapid Enquiry Facility (RIF) - VACUUM ANALYSE VERBOSE all rif40 owned objects
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
-- the Free Software Foundation, either verquote_ident(l_schema)||'.'||quote_ident(l_tablesion 3 of the License, or
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
\set ECHO none
\set ON_ERROR_STOP ON
\timing off
\pset pager off
\pset format aligned
\pset tuples_only

--
-- Check user is rif40
--
DO LANGUAGE plpgsql $$
BEGIN
	IF user = 'rif40' THEN
		RAISE INFO 'User check: %', user;	
	ELSE
		RAISE EXCEPTION 'C20900: User check failed: % is not rif40', user;	
	END IF;
END;
$$;

\o ../psql_scripts/v4_0_vacuum_analyse_tmp.sql
\qecho -- Vacuum analyse script auto generated by ../psql_scripts/v4_0_vacuum_analyse.sql
\qecho -- ************************************************************************
\qecho --
\qecho -- GIT Header
\qecho --
\qecho -- $Format:Git ID: (%h) %ci$
\qecho -- $Id$
\qecho -- Version hash: $Format:%H$
\qecho --
\qecho -- Description:
\qecho --
\qecho -- Rapid Enquiry Facility (RIF) - VACUUM ANALYSE VERBOSE all rif40 owned objects
\qecho --
\qecho -- Copyright:
\qecho --
\qecho -- The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
\qecho -- that rapidly addresses epidemiological and public health questions using 
\qecho -- routinely collected health and population data and generates standardised 
\qecho -- rates and relative risks for any given health outcome, for specified age 
\qecho -- and year ranges, for any given geographical area.
\qecho --
\qecho -- Copyright 2014 Imperial College London, developed by the Small Area
\qecho -- Health Statistics Unit. The work of the Small Area Health Statistics Unit 
\qecho -- is funded by the Public Health England as part of the MRC-PHE Centre for 
\qecho -- Environment and Health. Funding for this project has also been received 
\qecho -- from the Centers for Disease Control and Prevention.  
\qecho --
\qecho -- This file is part of the Rapid Inquiry Facility (RIF) project.
\qecho -- RIF is free software: you can redistribute it and/or modify
\qecho -- it under the terms of the GNU Lesser General Public License as published by
\qecho -- the Free Software Foundation, either verquote_ident(l_schema)||'.'||quote_ident(l_tablesion 3 of the License, or
\qecho -- (at your option) any later version.
\qecho --
\qecho -- RIF is distributed in the hope that it will be useful,
\qecho -- but WITHOUT ANY WARRANTY; without even the implied warranty of
\qecho -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
\qecho -- GNU Lesser General Public License for more details.
\qecho --
\qecho -- You should have received a copy of the GNU Lesser General Public License
\qecho -- along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
\qecho -- to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
\qecho -- Boston, MA 02110-1301 USA
\qecho --
\qecho -- Author:
\qecho --
\qecho -- Peter Hambly, SAHSU
\qecho --
\qecho '\\set ECHO all'
SELECT 'VACUUM ANALYZE VERBOSE '||schemaname||'.'||tablename||';' AS sql_stmt
  FROM pg_tables
 WHERE tableowner = USER
   AND schemaname NOT LIKE 'pg_temp%'
ORDER BY 1;
\qecho --
\qecho -- Eof
\o

--
-- Vacuum ANALYZE all RIF40 tables
--
\i ../psql_scripts/v4_0_vacuum_analyse_tmp.sql
\echo Vacuum ANALYZE all RIF40 tables comnplete.

--
-- Eof
