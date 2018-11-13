package org.sahsu.rif.stats.service;

import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.annotation.XmlRootElement;

import org.sahsu.rif.generic.util.RIFLogger;

import com.sun.xml.internal.txw2.annotation.XmlElement;

@XmlRootElement
public class StatisticsFunctions {

	private static final String SMOOTHING_KEY = "smoothing";
	private static final String RISK_ANALYSIS_KEY = "risk";
	static final String STUDY_ID = "studyId";
	static final String STUDY_ID_URI = "/{" + STUDY_ID + "}";
	static final String SMOOTHING_URI = "/smoothing";
	static final String RISK_ANALYSIS_URI = "/riskanalysis";

	private final String studyId;
	private final Map<String, String> functions = new HashMap<>();

	private static Map<String, StatisticsFunctions> instances = new HashMap<>();

	public static StatisticsFunctions getInstance(String studyId) {

		if (!instances.containsKey(studyId)) {

			instances.put(studyId, new StatisticsFunctions(studyId));
		}
		return instances.get(studyId);
	}

	private StatisticsFunctions(final String studyId) {

		this.studyId = studyId;

		functions.put(SMOOTHING_KEY, SMOOTHING_URI + "/" + studyId);
		functions.put(RISK_ANALYSIS_KEY, RISK_ANALYSIS_URI + "/" + studyId);
	}

	@XmlElement
	public String smoothingFunction() {

		return functions.get(SMOOTHING_KEY);
	}

	@XmlElement
	public String riskAnalysisFunction() {

		return functions.get(RISK_ANALYSIS_KEY);
	}
}
