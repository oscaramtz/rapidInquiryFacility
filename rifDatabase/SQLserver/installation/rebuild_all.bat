REM ************************************************************************
REM
REM Description:
REM
REM Rapid Enquiry Facility (RIF) - RIF40 create sahsuland database objects and install data
REM
REM Copyright:
REM
REM The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
REM that rapidly addresses epidemiological and public health questions using 
REM routinely collected health and population data and generates standardised 
REM rates and relative risks for any given health outcome, for specified age 
REM and year ranges, for any given geographical area.
REM
REM Copyright 2014 Imperial College London, developed by the Small Area
REM Health Statistics Unit. The work of the Small Area Health Statistics Unit 
REM is funded by the Public Health England as part of the MRC-PHE Centre for 
REM Environment and Health. Funding for this project has also been received 
REM from the Centers for Disease Control and Prevention.  
REM
REM This file is part of the Rapid Inquiry Facility (RIF) project.
REM RIF is free software: you can redistribute it and/or modify
REM it under the terms of the GNU Lesser General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM
REM RIF is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
REM GNU Lesser General Public License for more details.
REM
REM You should have received a copy of the GNU Lesser General Public License
REM along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
REM to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
REM Boston, MA 02110-1301 USA
REM
REM Author:
REM
REM Margaret Douglass, Peter Hambly, SAHSU
REM
REM Usage: rif40_install_tables.bat
REM
REM recreate_all_sequences.bat MUST BE RUN FIRST
REM
REM MUST BE RUN AS ADMINSTRATOR
REM

ECHO OFF
NET SESSION >nul 2>&1
if %errorlevel% equ 0 (
    ECHO Administrator PRIVILEGES Detected! 
) else (
    ECHO NOT AN ADMIN!
	exit /b 1
)


ECHO ####################################################################################
ECHO #
ECHO # WARNING! this script will the sahusland_dev database. Type control-C to abort.
ECHO #
ECHO ####################################################################################
PAUSE

sqlcmd -E -b -m-1 -e -r1 -i rif40_database_creation.sql
if %errorlevel% neq 0 (
	ECHO rif40_database_creation.sql exiting with %errorlevel%
	exit /b 1
) else (
	ECHO rif40_database_creation.sql built OK %errorlevel%
)
sqlcmd -E -b -m-1 -e -i rif40_test_user.sql -v newuser=peter
if %errorlevel% neq 0  (
	ECHO rif40_test_user.sql exiting with %errorlevel%
	exit /b 1
) else (
	ECHO rif40_test_user.sql built OK %errorlevel%
)
CALL rif40_sahsuland_dev_install.bat 
if %errorlevel% neq 0  (
	ECHO rif40_sahsuland_dev_install.bat exiting with %errorlevel%
	exit /b 1
) else (
	ECHO if40_sahsuland_dev_install.bat built OK %errorlevel%
)
REM
REM Does not get to here...
REM
CALL rif40_sahsuland_install.bat 
if %errorlevel% neq 0  (
	ECHO rif40_sahsuland_install.bat exiting with %errorlevel%
	exit /b 1
) else (
	ECHO rif40_sahsuland_install.bat built OK %errorlevel%
	ECHO Both sahsuland and sahsuland_dev built OK
)

REM
REM Eof