package rifServices.dataStorageLayer;

import rifGenericLibrary.dataStorageLayer.SQLQueryUtility;
import rifGenericLibrary.dataStorageLayer.SQLSelectQueryFormatter;
import rifGenericLibrary.system.RIFServiceException;
import rifServices.system.RIFServiceMessages;

import java.util.ArrayList;
import java.sql.*;

/**
 *
 * <hr>
 * The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
 * that rapidly addresses epidemiological and public health questions using 
 * routinely collected health and population data and generates standardised 
 * rates and relative risks for any given health outcome, for specified age 
 * and year ranges, for any given geographical area.
 *
 * Copyright 2014 Imperial College London, developed by the Small Area
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
 * Kevin Garwood
 * @author kgarwood
 */

/*
 * Code Road Map:
 * --------------
 * Code is organised into the following sections.  Wherever possible, 
 * methods are classified based on an order of precedence described in 
 * parentheses (..).  For example, if you're trying to find a method 
 * 'getName(...)' that is both an interface method and an accessor 
 * method, the order tells you it should appear under interface.
 * 
 * Order of 
 * Precedence     Section
 * ==========     ======
 * (1)            Section Constants
 * (2)            Section Properties
 * (3)            Section Construction
 * (7)            Section Accessors and Mutators
 * (6)            Section Errors and Validation
 * (5)            Section Interfaces
 * (4)            Section Override
 *
 */

public class RunStudyThread {

	// ==========================================
	// Section Constants
	// ==========================================

	// ==========================================
	// Section Properties
	// ==========================================

	// ==========================================
	// Section Construction
	// ==========================================

	public RunStudyThread() {

		
	}

	// ==========================================
	// Section Accessors and Mutators
	// ==========================================

	
	
	
	private Integer[] scanForNewStudySubmissions(final Connection connection) 
		throws RIFServiceException {
				
		SQLSelectQueryFormatter queryFormatter = new SQLSelectQueryFormatter();
		queryFormatter.addSelectField("study_id");
		queryFormatter.addFromTable("rif40.rif_studies");
		queryFormatter.addWhereParameterWithLiteralValue("study_state", "C");
		
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		ArrayList<Integer> studiesToRun = new ArrayList<Integer>();
		try {
			statement 
				= connection.prepareStatement(queryFormatter.generateQuery());
			resultSet = statement.executeQuery();
			while (resultSet.next()) {
				studiesToRun.add(resultSet.getInt(1));
			}
		}
		catch(SQLException exception) {
/*
			String errorMessage
				= RIFServiceMessages.getMessage("");
			RIFServiceException rifServiceException 
				= new RIFServiceException(
					RIFServiceError, 
					errorMessage);
			throw rifServiceException;
*/			
		}
		finally {
			SQLQueryUtility.close(statement);
			SQLQueryUtility.close(statement);
		}
		
		return studiesToRun.toArray(new Integer[0]);
		
	}
	
	
	// ==========================================
	// Section Errors and Validation
	// ==========================================

	// ==========================================
	// Section Interfaces
	// ==========================================

	// ==========================================
	// Section Override
	// ==========================================
}