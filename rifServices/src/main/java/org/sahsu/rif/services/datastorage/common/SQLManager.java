package org.sahsu.rif.services.datastorage.common;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.sahsu.rif.generic.concepts.User;
import org.sahsu.rif.generic.datastorage.QueryFormatter;
import org.sahsu.rif.generic.system.RIFServiceException;
import org.sahsu.rif.services.concepts.AbstractRIFConcept.ValidationPolicy;

import com.sun.rowset.CachedRowSetImpl;

public interface SQLManager {

	String SCHEMA_NAME = "rif40";
	String SCHEMA_PREFIX = SCHEMA_NAME + ".";
	String SCHEMA_DATA_NAME = "rif_data";
	String SCHEMA_DATA_PREFIX = SCHEMA_DATA_NAME + ".";

	ValidationPolicy getValidationPolicy();
	
	void setValidationPolicy(ValidationPolicy validationPolicy);
	
	void configureQueryFormatterForDB(
			QueryFormatter queryFormatter);
	
	PreparedStatement createPreparedStatement(
			Connection connection,
			QueryFormatter queryFormatter)
		throws SQLException;
	
	CachedRowSetImpl createCachedRowSet(
			Connection connection,
			QueryFormatter queryFormatter,
			String queryName)
				throws Exception;
	
	CachedRowSetImpl createCachedRowSet(
			Connection connection,
			QueryFormatter queryFormatter,
			String queryName,
			int[] params)
				throws Exception;
	
	String getColumnFromResultSet(
			CachedRowSetImpl cachedRowSet,
			String columnName)
			throws Exception;
	
	String getColumnFromResultSet(
			CachedRowSetImpl cachedRowSet,
			String columnName,
			boolean allowNulls,
			boolean allowNoRows)
			throws Exception;
	
	String getColumnComment(Connection connection,
			String schemaName, String tableName, String columnName)
			throws Exception;
	
	void enableDatabaseDebugMessages(
			Connection connection)
		throws RIFServiceException;
	
	void setEnableLogging(boolean enableLogging);
	
	String getUserPassword(final User user);
	
	boolean userExists(final String userID);
	
	void logSQLQuery(
			String queryName,
			QueryFormatter queryFormatter,
			String... parameters);
	
	void logSQLException(SQLException sqlException);
	
	boolean isUserBlocked(final User user);
	
	void logSuspiciousUserEvent(final User user);
	
	boolean userExceededMaximumSuspiciousEvents(final User user);
	
	void addUserIDToBlock(final User user);
	
	void login(final String userID, final String password) throws RIFServiceException;
	
	boolean isLoggedIn(final String userID);
	
	Connection assignPooledReadConnection(final User user) throws RIFServiceException;
	
	void reclaimPooledReadConnection(final User user, final Connection connection)
			throws RIFServiceException;
	
	void reclaimPooledWriteConnection(final User user, final Connection connection)
			throws RIFServiceException;
	
	Connection assignPooledWriteConnection(final User user) throws RIFServiceException;
	
	void logout(final User user) throws RIFServiceException;
	
	void deregisterAllUsers() throws RIFServiceException;
	
	default CallableStatement createPreparedCall(final Connection connection, final String query)
			throws SQLException {
		
		throw new UnsupportedOperationException("Method not implemented.");
	}
}