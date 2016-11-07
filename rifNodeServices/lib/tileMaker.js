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
// Rapid Enquiry Facility (RIF) - Tile maker code
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
	
const serverLog = require('../lib/serverLog'),
	  nodeGeoSpatialServicesCommon = require('../lib/nodeGeoSpatialServicesCommon'),
	  httpErrorResponse = require('../lib/httpErrorResponse'),
	  scopeChecker = require('../lib/scopeChecker');

const async = require('async'),
	  os = require('os'),
	  fs = require('fs'),
	  path = require('path'),
	  turf = require('turf'),
	  geojson2svg = require('geojson2svg'),
	  converter = geojson2svg({
			viewportSize: { width: 256, height: 256 },
			attributes: { 'style': 'stroke:#000000; fill-opacity: 0.0; stroke-width:0.5px;' },
			output: 'svg'
		}),
	  reproject = require("reproject"),
	  proj4 = require("proj4"),
	  wellknown = require('wellknown'),
	  topojson = require('topojson');

/*
 * Function: 	writeSVGTile
 * Parameters:	path, geolevel, zoomlevel, X, Y, callback, insertion geoJSON
 * Returns:		tile X
 * Description: Create SVG tile from geoJSON
 */
var writeSVGTile = function writeSVGTile(path, geolevel, zoomlevel, X, Y, callback, intersection) {
	scopeChecker(__file, __line, {
		path: path,
		callback: callback, 
		intersection: intersection,
		bbox: intersection.bbox
	});
	
//	
// Create directory: path/geolevel/zoomlevel/X as required
//		  
	var dirArray=[path, geolevel, zoomlevel, Y];
	var dir=nodeGeoSpatialServicesCommon.createTemporaryDirectory(dirArray);
	var svgFileName=dir + "/" + Y + ".svg";
	
//
// Create stream for tile
//	
	var svgStream = fs.createWriteStream(svgFileName, { flags : 'w' });	
	svgStream.on('finish', 
		function svgStreamClose() {
			console.error("Wrote tile: " + svgFileName);
			callback();
		});		
	svgStream.on('error', 
		function svgStreamError(e) {
			callback(e);						
		});

//
// Get bounding box from intersection, reproject to 3857
//
	var bboxPolygon = turf.bboxPolygon(intersection.bbox);		
	var bbox3857Polygon = reproject.reproject(
		bboxPolygon,'EPSG:4326','EPSG:3857',proj4.defs);
	var mapExtent={ 
		left: bbox3857Polygon.geometry.coordinates[0][0][0], 	// Xmin
		bottom: bbox3857Polygon.geometry.coordinates[0][1][1], 	// Ymin
		right: bbox3857Polygon.geometry.coordinates[0][2][0], 	// Xmax
		top: bbox3857Polygon.geometry.coordinates[0][3][1] 		// Ymax
	};		
	var svgOptions = {
		mapExtent: mapExtent,
		attributes: { id: svgFileName }
	};
	
//
// Reproject intersection to 3857 and convert to SVG
//	
	var intersection3857 = reproject.reproject(
		intersection,'EPSG:4326','EPSG:3857',proj4.defs);
	var svgString = converter.convert(intersection3857, svgOptions);
	svgString='<?xml version="1.0" standalone="no"?>\n' +
		' <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n' +
		'  <svg width="256" height="256" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' + 
		'   ' + svgString + '\n' +
		'  </svg>';
	console.error(svgFileName + ": " + svgString.substring(0, 132));
//
// Write SVG file
//		
	svgStream.write(svgString);
	svgStream.end();
} // End of writeSVGTile()

/*
 * Function: 	longitude2tile
 * Parameters:	Longitude, zoom level
 * Returns:		tile X
 * Description:	Convert longitude (WGS84 - 4326) to OSM tile x
 
	From: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
	
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
	
	X and Y
	
	* X goes from 0 (left edge is 180 °W) to 2**zoom − 1 (right edge is 180 °E)
	* Y goes from 0 (top edge is 85.0511 °N) to 2**zoom − 1 (bottom edge is 85.0511 °S) in a Mercator projection
	
	For the curious, the number 85.0511 is the result of arctan(sinh(π)). By using this bound, the entire map becomes a (very large) square.
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
 
	pgTileMaker(endCallback)										
} // End of tileMaker()


var pgTileMaker = function pgTileMaker(client, callback) {
	
	scopeChecker(__file, __line, {
		callback: callback
	});

	var sql;
	var pgErrorHandler = function pgErrorHandler(err) {
		var nerr=new Error(err.message + "\nSQL> " + sql + ";");
		nerr.stack=err.stack;
		callback(nerr);	
	}

	var lstart = new Date().getTime();
	
	var topojson_options = {
		verbose: false
	};
	topojson_options["property-transform"] = function(d) {					
		return d.properties;
	};
	topojson_options.id = function(d) {
		if (!d.properties["id"]) {
			throw new Error("FIELD PROCESSING ERROR! Invalid id field: d.properties.id does not exist in geoJSON");
		}
		else {
			return d.properties["id"];
		}							
	};						
			
	function Tile(tileId, geolevel_id, geolevel_name, zoomlevel, x, y, geojson, topojson_options, tileArray) { // Object constructor
		this.tileId=tileId;
		this.geojson={type: "FeatureCollection", bbox: undefined, features: [geojson]};
		this.geolevel_id=geolevel_id;	
		this.geolevel_name=geolevel_name;	
		this.zoomlevel=zoomlevel;
		this.x=x;
		this.y=y;
		this.topojson_options=topojson_options;		

		if (tileArray) {
			tileArray.push(this);	
			this.id=tileArray.length;
			this.geojson.features[0].properties.id=tileArray.length;
		}
		else {
			throw new Error("No tileArray defined");
		}		
	}
	Tile.prototype = { // Add methods
		addFeature: function(geojson) {
			this.geojson.features.push(geojson);
			this.geojson.features[(this.geojson.features.length-1)].properties.id=this.id;
		},
		addTopoJson: function() {
			var bbox=turf.bbox(this.geojson);
			this.geojson.bbox=bbox;
			var numFeatures=(this.geojson.features.length || 0);	
			if (this.id == 1) {
				this.topojson_options.verbose=true;
				console.error("GEOJSON: " + JSON.stringify(this.geojson, null, 2).substring(0, 1000));
			}
			else {
				this.topojson_options.verbose=false;
			}
			this.topojson=topojson.topology({   // Convert geoJSON to topoJSON
				collection: this.geojson
				}, this.topojson_options);
			
			console.error('Made tile ' + this.id + ': "' + this.tileId + 
				'", ' +  numFeatures + ' features' + 
				'; bounding box: ' + JSON.stringify(bbox));	
			if (this.id == 1) {
				console.error("TOPOJSON: " + JSON.stringify(this.topojson, null, 2).substring(0, 1000));
			}	
				
			this.geojson=undefined;
		}
	};
	
//
// Add $user to path
//	
	sql="SELECT reset_val FROM pg_settings WHERE name='search_path'";
	var query=client.query(sql, function(err, result) {
		if (err) {
			pgErrorHandler(err);
		}
		sql='SET SEARCH_PATH TO "$user",' + result.rows[0].reset_val;
		
		var tileArray = [];	
		function getTileArray() {
			return tileArray;
		}
		
		var query=client.query(sql, function(err, result) {
			if (err) {
				pgErrorHandler(err);
			}
// 
// Primary key: geolevel_id, zoomlevel, areaid, x, y
//			
			sql="SELECT z.geolevel_id::VARCHAR||'_'||'cb_2014_us_state_500k'||'_'||z.zoomlevel::VARCHAR||'_'||z.x::VARCHAR||'_'||z.y::VARCHAR AS tile_id,\n" +
				"       z.geolevel_id, z.zoomlevel, z.optimised_wkt, z.areaid, a.areaname\n" +				
				"  FROM tile_intersects_cb_2014_us_500k z, lookup_cb_2014_us_state_500k a\n" +
				" WHERE z.geolevel_id = 2\n" + 
				"   AND z.zoomlevel   = 5\n" + 
				"   AND z.areaid      = a.cb_2014_us_state_500k\n" + 
				" ORDER BY 1 /* LIMIT 200 */";
			var query = client.query(sql);
			query.on('error', pgErrorHandler);

			query.on('row', function(row) {
/*

Generates GEOJSON: {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "areaID": "01785533",
        "areaName": "Alaska"
      },
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [
          [
            [
              [
                -179.148191144524,
                51.2701475586686
              ],
              [
                -179.145678650359,
                51.2714362678723
              ],
              [
                -179.146755433572,
                51.2753023954834
              ],
              [
                -179.144960794883,
                51.2785671254661
              ],
              [
                -179.14029473429,
                51.2834642204402
              ],
              [
                -179.135628673697,
                51.2862993806884
              ],
              [
                -179.130603685366,
                51.2874162619983
              ],
							
REFERENCE (from shapefile) {
	"type": "FeatureCollection",
	"bbox": [-179.148909,
	-14.548699000000001,
	179.77847,
	71.36516200000001],
	"features": [{
		"type": "Feature",
		"properties": {
			"STATEFP": "02",
			"STATENS": "01785533",
			"AFFGEOID": "0400000US02",
			"GEOID": "02",
			"STUSPS": "AK",
			"NAME": "Alaska",
			"LSAD": "00",
			"ALAND": 1477849359548,
			"AWATER": 245487700921,
			"GID": 1,
			"AREAID": "01785533",
			"AREANAME": "Alaska",
			"AREA_KM2": 1516559.358611932,
			"GEOGRAPHIC_CENTROID_WKT": "POINT (-150.4186689317295 58.382944477050366)"
		},
		"geometry": {
			"type": "MultiPolygon",
			"coordinates": [[[[-157.903963,
			56.346443],
			[-157.89897200000001,
			56.347497000000004],
 */			
				
				var tileArray=getTileArray();
				var geojson={
					type: "Feature",
					properties: {
						id: 	  undefined,
						areaID:   row.areaid,
						areaName: row.areaname
					}, 
					geometry: wellknown.parse(row.optimised_wkt)
				};
//				console.error("wktjson: " + JSON.stringify(wktjson, null, 2).substring(0, 1000));	
					
				if (tileArray.length == 0) {
					var geojsonTile=new Tile(row.tile_id, row.geolevel_id, row.geolevel_name, row.zoomlevel, row.x, row.y, geojson, topojson_options, tileArray);
//					console.error('Tile ' + geojsonTile.id + ': ' + geojsonTile.tileId + "; properties: " + 
//						JSON.stringify(geojsonTile.geojson.features[0].properties, null, 2));
				}
				else {
					var geojsonTile=tileArray[(tileArray.length-1)];
					if (geojsonTile.tileId == row.tile_id) {
						geojsonTile.addFeature(geojson);
//						console.error('Add areaID: ' + row.areaid + "; properties: " + 
//							JSON.stringify(geojsonTile.geojson.features[(geojsonTile.geojson.features.length-1)].properties, null, 2));
					}
					else {	
						geojsonTile.addTopoJson();	
						
						geojsonTile=new Tile(row.tile_id, row.geolevel_id, row.geolevel_name, row.zoomlevel, row.x, row.y, geojson, topojson_options, tileArray);
					
//						console.error('Tile ' + geojsonTile.id + ': "' + geojsonTile.tileId + "; features[0] properties: " + 
//							JSON.stringify(geojsonTile.geojson.features[0].properties, null, 2));		
					}	
				}				
			});
			
			query.on('end', function(result) {
				var end = new Date().getTime();
				var elapsedTime=(end - lstart)/1000; // in S
				console.error(result.rowCount + ' tile intersects processed; ' + tileArray.length + " tiles in " + elapsedTime + " S");
				callback();
			});		
		});
	});		
}

module.exports.pgTileMaker = pgTileMaker;

//
// Eof