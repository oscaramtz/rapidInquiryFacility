package rifServices.dataStorageLayer.pg;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import rifGenericLibrary.businessConceptLayer.User;
import rifGenericLibrary.dataStorageLayer.pg.PGSQLQueryUtility;
import rifGenericLibrary.dataStorageLayer.pg.PGSQLSelectQueryFormatter;
import rifGenericLibrary.system.RIFServiceException;
import rifServices.businessConceptLayer.AgeBand;
import rifServices.businessConceptLayer.AgeGroup;
import rifServices.businessConceptLayer.ComparisonArea;
import rifServices.businessConceptLayer.DiseaseMappingStudy;
import rifServices.businessConceptLayer.DiseaseMappingStudyArea;
import rifServices.businessConceptLayer.GeoLevelToMap;
import rifServices.businessConceptLayer.Geography;
import rifServices.businessConceptLayer.Investigation;
import rifServices.businessConceptLayer.MapArea;
import rifServices.businessConceptLayer.NumeratorDenominatorPair;
import rifServices.businessConceptLayer.RIFStudySubmission;
import rifServices.businessConceptLayer.Sex;
import rifServices.businessConceptLayer.YearRange;
import rifServices.dataStorageLayer.common.StudyStateManager;
import rifServices.dataStorageLayer.common.SubmissionManager;
import rifServices.system.RIFServiceError;
import rifServices.system.RIFServiceMessages;
import rifServices.system.RIFServiceStartupOptions;
import rifServices.dataStorageLayer.common.SampleTestObjectGenerator;

final class PGSQLRIFSubmissionManager extends PGSQLAbstractSQLManager
		implements SubmissionManager {
	
	private StudyStateManager studyStateManager;

	PGSQLRIFSubmissionManager(final RIFServiceStartupOptions options,
			final StudyStateManager studyStateManager) {

		super(options);
		this.studyStateManager = studyStateManager;
		
		setEnableLogging(false);
	}

	@Override
	public RIFStudySubmission getRIFStudySubmission(
			final Connection connection,
			final User user,
			final String studyID)
		throws RIFServiceException {
		
		SampleTestObjectGenerator testDataGenerator = new SampleTestObjectGenerator();
		RIFStudySubmission rifStudySubmission
			= testDataGenerator.createSampleRIFJobSubmission();
		DiseaseMappingStudy diseaseMappingStudy
			= getDiseaseMappingStudy(
				connection, 
				user, 
				studyID);		
		rifStudySubmission.setStudy(diseaseMappingStudy);
		
		return rifStudySubmission;
	}


	/*
	 * Methods below are for retrieving a study
	 */
	@Override
	public DiseaseMappingStudy getDiseaseMappingStudy(
			final Connection connection,
			final User user,
			final String studyID)
		throws RIFServiceException {
				
		//check for non-existent study given id
		//checkNonExistentStudy(studyID);
		
		studyStateManager.checkNonExistentStudyID(
			connection,
			user,
			studyID);

		DiseaseMappingStudy result
			= DiseaseMappingStudy.newInstance();
		try {
			result.setIdentifier(studyID);
		
			retrieveGeneralInformationForStudy(
				connection,
				result);
		
			retrieveStudyAreaForStudy(
				connection,
				result);
		
			retrieveComparisonAreaForStudy(
				connection,
				result);

			retrieveInvestigationsForStudy(
				connection,
				result);
			return result;
		}
		catch(SQLException sqlException) {
			logSQLException(sqlException);
			PGSQLQueryUtility.rollback(connection);			
			String errorMessage
				= RIFServiceMessages.getMessage(
					"sqlRIFSubmissionManager.error.unableToGetDiseaseMappingStudy",
					studyID);
			RIFServiceException rifServiceException
				= new RIFServiceException(
					RIFServiceError.DATABASE_QUERY_FAILED,
					errorMessage);
			throw rifServiceException;
		}		
	}
	
	private void retrieveGeneralInformationForStudy(
		final Connection connection,
		final DiseaseMappingStudy diseaseMappingStudy) 
		throws SQLException,
		RIFServiceException {
				
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		try {
			PGSQLSelectQueryFormatter queryFormatter
				= new PGSQLSelectQueryFormatter();
			queryFormatter.addFromTable("rif40_studies");
			queryFormatter.addSelectField("study_name");
			queryFormatter.addSelectField("geography");
			//queryFormatter.addSelectField("project");
			queryFormatter.addSelectField("comparison_geolevel_name");
			queryFormatter.addSelectField("study_geolevel_name");
			queryFormatter.addSelectField("denom_tab");
			queryFormatter.addWhereParameter("study_id");
			
			logSQLQuery(
				"retrieveGeneralInformationForStudy", 
				queryFormatter,
				diseaseMappingStudy.getIdentifier());		
			
			statement
				= createPreparedStatement(
					connection,
					queryFormatter);
			statement.setInt(1, Integer.valueOf(diseaseMappingStudy.getIdentifier()));
			
			resultSet = statement.executeQuery();
			resultSet.next();
			
			diseaseMappingStudy.setName(resultSet.getString(1));
			Geography geography
				= Geography.newInstance(resultSet.getString(2), "");
			diseaseMappingStudy.setGeography(geography);		
			
			//KLG: Note that we cannot reconstitute geolevel select, geolevel view,
			//geo level area -- just 'to map'
			GeoLevelToMap comparisonAreaGeoLevelToMap
				= GeoLevelToMap.newInstance(resultSet.getString(3));
			ComparisonArea comparisonArea
				= diseaseMappingStudy.getComparisonArea();
			comparisonArea.setGeoLevelToMap(comparisonAreaGeoLevelToMap);
			
			GeoLevelToMap diseaseMappingStudyAreaGeoLevelToMap
				= GeoLevelToMap.newInstance(resultSet.getString(3));
			DiseaseMappingStudyArea diseaseMappingStudyArea
				= diseaseMappingStudy.getDiseaseMappingStudyArea();
			diseaseMappingStudyArea.setGeoLevelToMap(diseaseMappingStudyAreaGeoLevelToMap);
			
			//retrieving denom is awkward because we need both denom and numer to
			//reconstitute ndPair
		}
		finally {
			//Cleanup database resources			
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);
		}		
	}
		
	private void retrieveStudyAreaForStudy(
		final Connection connection,
		final DiseaseMappingStudy diseaseMappingStudy)
		throws SQLException,
		RIFServiceException {
					
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		try {
			PGSQLSelectQueryFormatter queryFormatter
				= new PGSQLSelectQueryFormatter();
			queryFormatter.addFromTable("rif40_study_areas");
			queryFormatter.addSelectField("area_id");
			queryFormatter.addSelectField("band_id");
			queryFormatter.addWhereParameter("study_id");
			
			logSQLQuery(
				"retrieveStudyAreaForStudy", 
				queryFormatter,
				diseaseMappingStudy.getIdentifier());	
			
			statement 
				= createPreparedStatement(
					connection,
					queryFormatter);			
			statement.setInt(1, Integer.valueOf(diseaseMappingStudy.getIdentifier()));
						
			DiseaseMappingStudyArea diseaseMappingStudyArea
				= DiseaseMappingStudyArea.newInstance();
			//KLG: TODO - how can we improve this so we can add in extra
			//information?
			resultSet = statement.executeQuery();
			while (resultSet.next()) {
				String geographicalIdentifier
					= resultSet.getString(1);
				MapArea mapArea = MapArea.newInstance(
					geographicalIdentifier, 
					geographicalIdentifier, 
					geographicalIdentifier);
				diseaseMappingStudyArea.addMapArea(mapArea);
			}
				diseaseMappingStudy.setDiseaseMappingStudyArea(diseaseMappingStudyArea);
		}
		finally {
			//Cleanup database resources			
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);
		}
	}	
	
	private void retrieveComparisonAreaForStudy(
		final Connection connection,
		final DiseaseMappingStudy diseaseMappingStudy)
		throws SQLException,
		RIFServiceException {
				
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		try {
			PGSQLSelectQueryFormatter queryFormatter
			= new PGSQLSelectQueryFormatter();
			queryFormatter.addFromTable("rif40_comparison_areas");
			queryFormatter.addSelectField("area_id");
			queryFormatter.addWhereParameter("study_id");
			
			logSQLQuery(
				"retrieveComparisonAreaForStudy", 
				queryFormatter,
				diseaseMappingStudy.getIdentifier());	

			
			statement 
				= createPreparedStatement(
					connection,
					queryFormatter);			
			statement.setInt(1, Integer.valueOf(diseaseMappingStudy.getIdentifier()));
						
			ComparisonArea comparisonArea
				= ComparisonArea.newInstance();
			//KLG: TODO - how can we improve this so we can add in extra
			//information?
			resultSet = statement.executeQuery();
			while (resultSet.next()) {
				String geographicalIdentifier
					= resultSet.getString(1);
				MapArea mapArea = MapArea.newInstance(
					geographicalIdentifier, 
					geographicalIdentifier, 
					geographicalIdentifier);
				comparisonArea.addMapArea(mapArea);
			}

			diseaseMappingStudy.setComparisonArea(comparisonArea);
		}
		finally {
			//Cleanup database resources			
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);
		}
	}
	
	private void retrieveInvestigationsForStudy(
		final Connection connection,
		final DiseaseMappingStudy diseaseMappingStudy)
		throws SQLException,
		RIFServiceException {
		
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		try {
			PGSQLSelectQueryFormatter queryFormatter
				= new PGSQLSelectQueryFormatter();
			queryFormatter.addSelectField("inv_id");
			queryFormatter.addSelectField("inv_name");
			queryFormatter.addSelectField("inv_description");
			queryFormatter.addSelectField("year_start");
			queryFormatter.addSelectField("year_stop");
			queryFormatter.addSelectField("max_age_group");
			queryFormatter.addSelectField("min_age_group");
			queryFormatter.addSelectField("genders");
			queryFormatter.addSelectField("numer_tab");
		
			queryFormatter.addFromTable("rif40_investigations");
			queryFormatter.addWhereParameter("study_id");
			
			logSQLQuery(
					"retrieveInvestigationsForStudy", 
					queryFormatter,
					diseaseMappingStudy.getIdentifier());
			
			statement 
				= createPreparedStatement(
					connection,
					queryFormatter);			
			statement.setInt(1, Integer.valueOf(diseaseMappingStudy.getIdentifier()));
			resultSet
				= statement.executeQuery();
			while (resultSet.next()) {
				
				Investigation investigation = Investigation.newInstance();
				//set identifier
				int ithParameter = 1;
				investigation.setIdentifier(
					resultSet.getString(ithParameter++));

				//set title
				investigation.setTitle(
					resultSet.getString(ithParameter++));
				//set description
				investigation.setDescription(
					resultSet.getString(ithParameter++));
		
				//set year range
				int startYearValue
					= resultSet.getInt(ithParameter++);
				int stopYearValue
					= resultSet.getInt(ithParameter++);
				YearRange yearRange
					= YearRange.newInstance(
						String.valueOf(startYearValue), 
						String.valueOf(stopYearValue));
				investigation.setYearRange(yearRange);
				
				
				//set the age bands.  
				//KLG: To do: we are not able to reconstitute age bands properly
				int maximumAgeGroupID
					= resultSet.getInt(ithParameter++);
				AgeGroup upperLimitAgeGroup
					= getAgeGroupFromIdentifier(
						connection,
						maximumAgeGroupID);
				int minimumAgeGroupID
					= resultSet.getInt(ithParameter++);
				AgeGroup lowerLimitAgeGroup
					= getAgeGroupFromIdentifier(
						connection,
						minimumAgeGroupID);				
				AgeBand ageBand
					= AgeBand.newInstance(lowerLimitAgeGroup, upperLimitAgeGroup);
				investigation.addAgeBand(ageBand);
								
				//set the sex value
				int sexIntValue
					= resultSet.getInt(ithParameter++);
				if (sexIntValue == 1) {
					investigation.setSex(Sex.MALES);
				}
				else if (sexIntValue == 2) {
					investigation.setSex(Sex.FEMALES);
				}
				else {
					investigation.setSex(Sex.BOTH);
				}
		
				//set the numerator denominator values
				String numeratorTableName
					= resultSet.getString(ithParameter++);
				NumeratorDenominatorPair ndPair
					= getNDPairForNumeratorTableName(
						connection,
						numeratorTableName);
				investigation.setNdPair(ndPair);
			
				diseaseMappingStudy.addInvestigation(investigation);				
			}
			
		}
		finally {
			//Cleanup database resources			
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);
		}
	}
		
	/**
	 * We assume the age group identifier will be valid
	 * @param connection
	 * @param ageGroupIdentifier
	 * @return
	 * @throws SQLException
	 */
	private AgeGroup getAgeGroupFromIdentifier(
		final Connection connection,
		final int ageGroupIdentifier) 
		throws SQLException,
		RIFServiceException {
				
		PreparedStatement statement = null;
		ResultSet resultSet = null;
		AgeGroup result = null;
		try {
			
			PGSQLSelectQueryFormatter queryFormatter
				= new PGSQLSelectQueryFormatter();
			queryFormatter.addFromTable("rif40_age_groups");
			queryFormatter.addSelectField("low_age");
			queryFormatter.addSelectField("high_age");
			queryFormatter.addSelectField("fieldname");	
			queryFormatter.addWhereParameter("age_group_id");
			queryFormatter.addWhereParameter("\"offset\"");
			
			logSQLQuery(
					"getAgeGroupFromIdentifier", 
					queryFormatter,
					"1",
					String.valueOf(ageGroupIdentifier));
			
			statement 
				= createPreparedStatement(
					connection,
					queryFormatter);			
			statement.setInt(1, 1);
			statement.setInt(2, Integer.valueOf(ageGroupIdentifier));
			resultSet
				= statement.executeQuery();
			resultSet.next();
			result
				= AgeGroup.newInstance(
					String.valueOf(ageGroupIdentifier), 					
					resultSet.getString(1), 
					resultSet.getString(2), 
					resultSet.getString(3));		
		}
		finally {
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);			
		}
		
		return result;
	}
	
	private NumeratorDenominatorPair getNDPairForNumeratorTableName(
		final Connection connection,
		final String numeratorTableName) 
		throws SQLException,
		RIFServiceException {

		ResultSet resultSet = null;
		NumeratorDenominatorPair result = null;
		PreparedStatement statement = null;
		try {
			PGSQLSelectQueryFormatter queryFormatter = new PGSQLSelectQueryFormatter();
			configureQueryFormatterForDB(queryFormatter);
			queryFormatter.setUseDistinct(true);
			queryFormatter.addSelectField("numerator_description");
			queryFormatter.addSelectField("denominator_table");
			queryFormatter.addSelectField("denominator_description");		
			queryFormatter.addFromTable("rif40_num_denom");
			queryFormatter.addWhereParameter("numerator_table");		

			logSQLQuery(
					"getNDPairForNumeratorTableName", 
					queryFormatter,
					String.valueOf(numeratorTableName));			
			
			statement 
				= createPreparedStatement(
					connection,
					queryFormatter);			
			statement.setString(1, numeratorTableName);
			resultSet = statement.executeQuery();
			resultSet.next();
			result = NumeratorDenominatorPair.newInstance();
			result.setNumeratorTableName(numeratorTableName);
			result.setNumeratorTableDescription(resultSet.getString(1));
			result.setDenominatorTableName(resultSet.getString(2));
			result.setDenominatorTableDescription(resultSet.getString(3));
		}
		finally {
			PGSQLQueryUtility.close(statement);
			PGSQLQueryUtility.close(resultSet);
		}
		
		return result;
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
