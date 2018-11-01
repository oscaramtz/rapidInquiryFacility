package org.sahsu.rif.generic.datastorage;

import org.sahsu.rif.generic.util.RIFLogger;
import org.sahsu.rif.generic.datastorage.SQLQueryUtility;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.lang.Exception;

public class RIFSQLException extends Exception {
	
	protected static final RIFLogger rifLogger = RIFLogger.getLogger();
	private static String lineSeparator = System.getProperty("line.separator");
	private String sqlQueryText;
	
	public RIFSQLException(
		final Class className, 
		final Exception exception) {
		
		super((exception != null && exception.getMessage() != null) ? exception.getMessage() : "RIFSQLException: no error message",
			exception != null ? exception.getCause() : null);
		
		rifLogger.error(className, "RIFSQLException: No PreparedStatement" +	
			"; exception: " + exception.getMessage(), exception);
	}
	
	public RIFSQLException(
		final Class className, 
		final Exception exception, 
		final PreparedStatement statement) {
		
		super((exception != null && exception.getMessage() != null) ? exception.getMessage() : "RIFSQLException: no error message",
			exception != null ? exception.getCause() : null);
		
		rifLogger.error(className, "RIFSQLException: " + 
			((statement != null) ? 
				"Warnings/Messages >>>" + lineSeparator + SQLQueryUtility.printWarnings(statement) + lineSeparator + "<<<" + lineSeparator :
                "No PreparedStatement" + lineSeparator) +	
			"exception: " + exception.getMessage(), exception);
	}
	
	public RIFSQLException(
		final Class className, 
		final Exception exception, 
		final PreparedStatement statement,
		final String sqlQueryText) {
		
		super((exception != null && exception.getMessage() != null) ? exception.getMessage() : "RIFSQLException: no error message",
			exception != null ? exception.getCause() : null);
		this.sqlQueryText = sqlQueryText;
		
		rifLogger.error(className, "RIFSQLException: " + 
			((statement != null) ? 
				"Warnings/Messages >>>" + lineSeparator + SQLQueryUtility.printWarnings(statement) + lineSeparator + "<<<" + lineSeparator :
                "No PreparedStatement") +	
			sqlQueryText + lineSeparator +
			"exception: " + exception.getMessage(), exception);
	}
	
	public String getSqlQueryText() {
		return this.sqlQueryText;
	}
}