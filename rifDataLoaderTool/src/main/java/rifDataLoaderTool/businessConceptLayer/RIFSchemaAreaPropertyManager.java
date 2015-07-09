package rifDataLoaderTool.businessConceptLayer;

import java.text.Collator;
import java.util.ArrayList;
import java.util.HashMap;

import rifDataLoaderTool.system.RIFDataLoaderToolMessages;
import rifDataLoaderTool.businessConceptLayer.rifDataTypes.*;

/**
 * Holds knowledge about what properties are expected for different parts of the
 * RIF schema {@link rifDataLoaderTool.businessConceptLayer.RIFSchemaArea}.
 *
 * <hr>
 * Copyright 2015 Imperial College London, developed by the Small Area
 * Health Statistics Unit. 
 *
 * <pre> 
 * This file is part of the Rapid Inquiry Facility (RIF) project.
 * RIF is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * RIF is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with RIF.  If not, see <http://www.gnu.org/licenses/>.
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

public class RIFSchemaAreaPropertyManager {

	// ==========================================
	// Section Constants
	// ==========================================

	// ==========================================
	// Section Properties
	// ==========================================
	
	private HashMap<String, AbstractRIFDataType> dataTypeFromCovariateFieldName;
	private HashMap<String, AbstractRIFDataType> dataTypeFromHealthCodeFieldName;
	private HashMap<String, AbstractRIFDataType> dataTypeFromNumeratorFieldName;
	private HashMap<String, AbstractRIFDataType> dataTypeFromDenominatorFieldName;
		
	// ==========================================
	// Section Construction
	// ==========================================

	public RIFSchemaAreaPropertyManager() {
		
		
		/*
		 * Fields in covariate data
		 */
		dataTypeFromCovariateFieldName = new HashMap<String, AbstractRIFDataType>();
		dataTypeFromCovariateFieldName.put(
			"geography", 
			TextRIFDataType.newInstance());
		dataTypeFromCovariateFieldName.put(
			"geolevel_name", 
			TextRIFDataType.newInstance());
		dataTypeFromCovariateFieldName.put(
			"covariate_name", 
			TextRIFDataType.newInstance());
		dataTypeFromCovariateFieldName.put(
			"min", 
			DoubleRIFDataType.newInstance());		
		dataTypeFromCovariateFieldName.put(
			"max", 
			DoubleRIFDataType.newInstance());		
		dataTypeFromCovariateFieldName.put(
			"type", 
			DoubleRIFDataType.newInstance());			

		dataTypeFromHealthCodeFieldName
			= new HashMap<String, AbstractRIFDataType>();
		dataTypeFromHealthCodeFieldName.put(
			"code", 
			TextRIFDataType.newInstance());
		dataTypeFromHealthCodeFieldName.put(
			"label", 
			TextRIFDataType.newInstance());
		dataTypeFromHealthCodeFieldName.put(
			"description", 
			TextRIFDataType.newInstance());		
		dataTypeFromHealthCodeFieldName.put(
			"nameSpace", 
			TextRIFDataType.newInstance());
				
		dataTypeFromNumeratorFieldName = new HashMap<String, AbstractRIFDataType>();
		dataTypeFromNumeratorFieldName.put(
			"year", 
			YearRIFDataType.newInstance());
		dataTypeFromNumeratorFieldName.put(
			"age_sex_group", 
			YearRIFDataType.newInstance());

		dataTypeFromDenominatorFieldName 
			= new HashMap<String, AbstractRIFDataType>();
		dataTypeFromDenominatorFieldName.put(
			"year", 
			YearRIFDataType.newInstance());
		dataTypeFromDenominatorFieldName.put(
			"age", 
			AgeRIFDataType.newInstance());
		
	}

	// ==========================================
	// Section Accessors and Mutators
	// ==========================================

	public ArrayList<RIFCheckOption> getCheckOptions(
		final RIFSchemaArea rifSchemaArea) {
		
		ArrayList<RIFCheckOption> rifCheckOptions
			= new ArrayList<RIFCheckOption>();
		
		rifCheckOptions.add(RIFCheckOption.PERCENT_EMPTY);
		if ((rifSchemaArea == RIFSchemaArea.HEALTH_NUMERATOR_DATA) ||
			(rifSchemaArea == RIFSchemaArea.POPULATION_DENOMINATOR_DATA)) {
			
			//with these parts of the schema, we can guarantee there will
			//be a year field
			rifCheckOptions.add(RIFCheckOption.PERCENT_EMPTY_PER_YEAR);
		}
		
		return rifCheckOptions;		
	}
	
	public boolean isRIFCheckOptionAllowed(
		final RIFSchemaArea rifSchemaArea,
		final RIFCheckOption checkOption) {
		
		if ((checkOption == RIFCheckOption.PERCENT_EMPTY_PER_YEAR) &&
			(rifSchemaArea != RIFSchemaArea.HEALTH_NUMERATOR_DATA) &&
			(rifSchemaArea != RIFSchemaArea.POPULATION_DENOMINATOR_DATA)) {
				
			//yearly checks are only allowed in the parts of the schema where
			//we expect a year to be
			return false;
		}			
		
		return true;	
	}
	
	public String[] getMissingRequiredConvertFieldNames(
		final RIFSchemaArea rifSchemaArea,
		final String[] convertFieldNames) {
		
		ArrayList<String> missingRequiredFieldNames = new ArrayList<String>();

		Collator collator = RIFDataLoaderToolMessages.getCollator();
		
		String[] requiredConvertFieldNames
			= getRequiredConvertFieldNames(rifSchemaArea);		
		for (String requiredConvertFieldName : requiredConvertFieldNames) {
			boolean fieldFound = false;
			
			for (String convertFieldName : convertFieldNames) {
				if (collator.equals(requiredConvertFieldName, convertFieldName)) {
					fieldFound = true;
					break;
				}
			}
			if (fieldFound == false) {
				missingRequiredFieldNames.add(requiredConvertFieldName);
			}
		}

		String[] results = missingRequiredFieldNames.toArray(new String[0]);
		return results;
	}
	
	public String[] getRequiredConvertFieldNames(
		final RIFSchemaArea rifSchemaArea) {
		
		String[] requiredConvertFieldNames = new String[0];
		if (rifSchemaArea == RIFSchemaArea.HEALTH_CODE_DATA) {
			requiredConvertFieldNames = new String[4];
			requiredConvertFieldNames[0] = "code";
			requiredConvertFieldNames[1] = "label";
			requiredConvertFieldNames[2] = "description";
			requiredConvertFieldNames[3] = "name_space";
		}
		else if (rifSchemaArea == RIFSchemaArea.COVARIATE_DATA) {
			requiredConvertFieldNames = new String[6];
			requiredConvertFieldNames[0] = "geography";
			requiredConvertFieldNames[1] = "geolevel_name";
			requiredConvertFieldNames[2] = "covariate_name";
			requiredConvertFieldNames[3] = "min";
			requiredConvertFieldNames[4] = "max";
			requiredConvertFieldNames[5] = "type";
		}
		else if (rifSchemaArea == RIFSchemaArea.HEALTH_NUMERATOR_DATA) {
			requiredConvertFieldNames = new String[6];
			requiredConvertFieldNames[0] = "year";
			requiredConvertFieldNames[1] = "age_sex_group";			
		}
		else if (rifSchemaArea == RIFSchemaArea.POPULATION_DENOMINATOR_DATA) {
			requiredConvertFieldNames = new String[6];
			requiredConvertFieldNames[0] = "year";
			requiredConvertFieldNames[1] = "age_sex_group";			
		}		
		
		return requiredConvertFieldNames;
		
	}
	
	public AbstractRIFDataType getExpectedRIFDataType(
		final RIFSchemaArea rifSchemaArea,
		final String fieldName) {
		
		if ((rifSchemaArea == null) ||
			(fieldName == null)) {
			return null;
		}
		
		if (rifSchemaArea == RIFSchemaArea.HEALTH_CODE_DATA) {
			return dataTypeFromHealthCodeFieldName.get(fieldName);			
		}
		else if (rifSchemaArea == RIFSchemaArea.COVARIATE_DATA) {
			return dataTypeFromCovariateFieldName.get(fieldName);
		}
		else if (rifSchemaArea == RIFSchemaArea.HEALTH_NUMERATOR_DATA) {
			return dataTypeFromNumeratorFieldName.get(fieldName);
		}
		else if (rifSchemaArea == RIFSchemaArea.POPULATION_DENOMINATOR_DATA) {
			return dataTypeFromDenominatorFieldName.get(fieldName);
		}
		else {
			return null;
		}
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

