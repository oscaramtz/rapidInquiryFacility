// ************************************************************************
//
// GIT Header
//
// $Format:Git ID: (%h) %ci$
// $Id: 7ccec3471201c4da4d181af6faef06a362b29526 $
// Version hash: $Format:%H$
//
// Description:
//
// Rapid Enquiry Facility (RIF) - GeoJSON to CSV conversion code
//
// Copyright:
//
// The Rapid Inquiry Facility (RIF) is an automated tool devised by SAHSU 
// that rapidly addresses epidemiological and public health questions using 
// routinely collected health and population data and generates standardised 
// rates and relative risks for any given health outcome, for specified age 
// and year ranges, for any given geographical area.
//
// Copyright 2014 Imperial College London, developed by the Small Area
// Health Statistics Unit. The work of the Small Area Health Statistics Unit 
// is funded by the Public Health England as part of the MRC-PHE Centre for 
// Environment and Health. Funding for this project has also been received 
// from the Centers for Disease Control and Prevention.  
//
// This file is part of the Rapid Inquiry Facility (RIF) project.
// RIF is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// RIF is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with RIF. If not, see <http://www.gnu.org/licenses/>; or write 
// to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
// Boston, MA 02110-1301 USA
//
// Author:
//
// Peter Hambly, SAHSU
	
const async = require('async'),
	  serverLog = require('../lib/serverLog'),
	  nodeGeoSpatialServicesCommon = require('../lib/nodeGeoSpatialServicesCommon'),
	  httpErrorResponse = require('../lib/httpErrorResponse');

const os = require('os'),
	  fs = require('fs'),
	  path = require('path');
	
/*
 * Function: 	tileMaker()
 * Parameters:	Internal response object, HTTP request object, HTTP response object, callback to call at end of processing
 * Description:	
 *				Then call geojsonToCSV() - Convert geoJSON to CSV; save as CSV files; create load scripts for Postgres and MS SQL server
 */		
 
var tileMaker = function tileMaker(response, req, res, endCallback) {

	scopeChecker(__file, __line, {
		response: response,
		message: response.message,
		serverLog: serverLog,
		req: req,
		res: res,
		httpErrorResponse: httpErrorResponse,
		nodeGeoSpatialServicesCommon: nodeGeoSpatialServicesCommon,
		callback: endCallback
	});
		
	const geojsonToCSV = require('../lib/geojsonToCSV');
		
/*
 * Function: 	longitude2tile
 * Parameters:	Longitude, zoom level
 * Returns:		tile X
 * Description:	Convert longitude (WGS84 - 4326) to OSM tile x
 
	Derivation of the tile X/Y 

	* Reproject the coordinates to the Mercator projection (from EPSG:4326 to EPSG:3857):

	x = lon
	y = arsinh(tan(lat)) = log[tan(lat) + sec(lat)]
	(lat and lon are in radians)

	* Transform range of x and y to 0 ? 1 and shift origin to top left corner:

	x = [1 + (x / p)] / 2
	y = [1 - (y / p)] / 2

	* Calculate the number of tiles across the map, n, using 2**zoom
	* Multiply x and y by n. Round results down to give tilex and tiley.

 */		
	var longitude2tile = function longitude2tile(longitude, zoomLevel) {
		var tileX=Math.floor( (longitude + 180) / 360 * Math.pow(2, zoomLevel) );
		return tileX;
	}
	
/*
 * Function: 	latitude2tile
 * Parameters:	Latitude, zoom level
 * Returns:		tile Y
 * Description:	Convert latitude (WGS84 - 4326) to OSM tile y
 */ 
 	var latitude2tile = function latitude2tile(latitude, zoomLevel) {
		var tileY=Math.floor(
			(1.0 - Math.log( /* Natural Log */
					Math.tan(latitude * (Math.PI/180)) + 1.0 / Math.cos(latitude * (Math.PI/180))) / 
				Math.PI) / 2.0 * Math.pow(2, zoomLevel)
			);
		return tileY;
	}

/*
 * Function: 	tile2longitude
 * Parameters:	tile X, zoom level
 * Returns:		Longitude
 * Description:	Convert OSM tile X to longitude (WGS84 - 4326)
 */
	function tile2longitude(x,zoomLevel) {
		return (x/Math.pow(2,zoomLevel)*360-180);
	}
	
/*
 * Function: 	tile2latitude
 * Parameters:	tile Y, zoom level
 * Returns:		Latitude
 * Description:	Convert OSM tile Y to latitude (WGS84 - 4326)
 */	
	function tile2latitude(y,zoomLevel) {
		var n=Math.PI-2*Math.PI*y/Math.pow(2,zoomLevel);
		return (180/Math.PI*Math.atan(0.5*(Math.exp(n)-Math.exp(-n))));
	}
 
	for (var i=0; i<response.file_list.length; i++) { 
//
// Get tile max/min lat/long from bounding box
//
		var msg="tileMaker() file [" + i + "/" + response.file_list.length + "]: " + 
			(response.file_list[i].file_name || "No file name") + 
			"; geolevel_id: " + (response.file_list[i].geolevel_id|| "No geolevel_id") + 
			"; zoom levels: " + (response.file_list[i].topojson.length|| "No zoomlevels") +
			"; min zoomlevel: " + response.file_list[i].topojson[(response.file_list[i].topojson.length-1)].zoomlevel +
			"; max zoomlevel: " + response.file_list[i].topojson[0].zoomlevel +
			"\nBounding box (4326) [" + 
			"xmin: " + response.file_list[i].bbox[0] + ", " +
			"ymin: " + response.file_list[i].bbox[1] + ", " +
			"xmax: " + response.file_list[i].bbox[2] + ", " +
			"ymax: " + response.file_list[i].bbox[3] + "]; " +
			"\nTile numbers (" + response.file_list[i].topojson[0].zoomlevel +") [" + 
			"xmin: " + longitude2tile(response.file_list[i].bbox[0], response.file_list[i].topojson[0].zoomlevel) + ", " +
			"ymin: " + latitude2tile(response.file_list[i].bbox[1], response.file_list[i].topojson[0].zoomlevel) + ", " +
			"xmax: " + longitude2tile(response.file_list[i].bbox[2], response.file_list[i].topojson[0].zoomlevel) + ", " +
			"ymax: " + latitude2tile(response.file_list[i].bbox[3], response.file_list[i].topojson[0].zoomlevel) + "];";
//			
// Comparision with SQL Server calculation:
//
// TRACE: tileMaker() file [0/3]: cb_2014_us_county_500k.shp; geolevel_id: 3; zoom levels: 6; min zoomlevel: 6; max zoomlevel: 11
// Bounding box (4326) [xmin: -179.148909, ymin: -14.548699000000001, xmax: 179.77847, ymax: 71.36516200000001]; 
// Tile numbers (11) [xmin: 4, ymin: 1107, xmax: 2046, ymax: 434];
//
// geography       zoomlevel       Xmin        Xmax       Ymin       Ymax       Y_mintile  Y_maxtile   X_mintile   X_maxtile
// --------------- --------------- ----------- ---------- ---------- ---------- ---------- ----------- ----------- ----------
// cb_2014_us_500k              11  -179.14734  179.77847  -14.55255   71.35256       1107         435           4       2046
//			
// This shows that YmaxTile is one less; this is caused by projection error in the SQL; this needs to be reduced:
//
// i.e. 71.35256 compared to 71.365162
//
// sahsuland_dev=> SELECT tileMaker_latitude2tile(71.365162, 11);
//  tilemaker_latitude2tile
// -------------------------
//                     434
// (1 row)
//
		console.error("TRACE: " + msg);
		response.message+=msg;
	}
	addStatus(__file, __line, response, "Created tiles", 200 /* HTTP OK */, serverLog, req, // Add status
		function addStatusTilesCallback(err) { 	
			if (err) {						
				serverLog.serverLog2(__file, __line, "addStatusTilesCallback", "ERROR! in adding tiles", req, e);
			}
	
			try {
				// Call geojsonToCSV() - Convert geoJSON to CSV; save as CSV files; create load scripts for Postgres and MS SQL server
				geojsonToCSV.geojsonToCSV(response, req, res, endCallback); // Convert geoJSON to CSV
			}
			catch (e) {	
				serverLog.serverError2(__file, __line, "shapeFileQueueDrain", 
					"Exception thrown by tileMaker.tileMaker() ", req, e, response);	
			}	
	
		});
											
} // End of tileMaker()

module.exports.tileMaker = tileMaker;

// Eof