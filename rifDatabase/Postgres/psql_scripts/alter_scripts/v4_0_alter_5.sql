-- ************************************************************************
-- *
-- * THIS IS A SCHEMA ALTER SCRIPT - IT CAN BE RE-RUN BUT THEY MUST BE RUN 
-- * IN NUMERIC ORDER
-- *
-- ************************************************************************
--
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
-- Rapid Enquiry Facility (RIF) - RIF alter script 5 - Zoomlevel support
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
-- the Free Software Foundation, either version 3 of the License, or
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
-- e.g.
--
-- psql -U rif40 -d sahsuland_dev -w -e -P pager=off -v testuser=peter -v verbosity= -v debug_level=1 -v use_plr= -v pghost=localhost -v echo=all -f alter_scripts/v4_0_alter_5.sql
--
\set ECHO all
\set ON_ERROR_STOP ON
\timing

\echo Running SAHSULAND schema alter script #5 zoomlevel support.

/*

Alter script #5

Rebuilds all geolevel tables with full partitioning (alter #3 support):

Done:

1. Convert to 4326 (WGS84 GPS projection) after simplification. Optimised geometry is 
   always in 4326.
2. Zoomlevel support. Optimised geometry is level 6, OPTIMISED_GEOMETRY_2 is level 8,
   OPTIMISED_GEOMETRY_3 is level 11; likewise OPTIMISED_GEOJSON (which will become a JOSN type). 
   TOPO_OPTIMISED_GEOJSON is removed.
3. Add t_rif40_sahsu_maptiles for zoomlevels 6, 8, 11, rif40_sahsu_maptiles for other zoomlevels.
4. Calculate the latitude of the middle of the total map bound; use this as the latitude
   in if40_geo_pkg.rif40_zoom_levels() for the correct m/pixel.
5. Partition t_rif40_sahsu_maptiles; convert partition to p_ naming convention, move to
    rif40_partitions schema, added indexes and constraints as required.
6. Convert rif40_get_geojson_tiles to use t_rif40_sahsu_maptiles tables.
7. Re-index partition indexes.
8. Add support for regionINLA.txt on a per study basis as rif40_GetAdjacencyMatrix().

<total area_id>
<area_id> <total (N)> <adjacent area 1> .. <adjacent area N>

9. populate_rif40_tiles() to correctly report rows inserted (using RETURNING); make
   more efficient; create EXPLAIN PLAN version.
10. Fix sahsuland projection (i.e. it is 27700; do the export using GDAL correctly).
11. Use Node.js topojson_convert.js GeoJSON to topoJSON conversion.  
12. Remove ST_SIMPLIFY_TOLERANCE from T_RIF40_GEOLEVELS; replace with m/pixel for zoomlevel.
13. Move all geospatial data to rif_data schema.
14. Map tiles build to warn if bounds of map at zoomlevel 6 exceeds 4x3 tiles.
15. Map tiles build  to fail if a zoomlevel 11 maptile(bound area: 19.6x19.4km) > 10% of the area bounded by the map; 
    i.e. the map is not projected correctly (as sahsuland was at one point). 
	There area 1024x as many tiles at 11 compared to 6; 10% implies there could be 1 tile at zoomlevel 8.
	This means that the Smallest geography supported is 3,804 km2 - about the size of Suffolk (1,489 square miles)
	so the Smallest US State (Rhode Island @4,002 square km) can be supported.
	
Not done:

16. Intersection to use shapefile SRID projection; after simplification to be tested against intersections 
    using zoomlevel 11.


*/
   
BEGIN;

--
-- Check user is rif40
--
DO LANGUAGE plpgsql $$
BEGIN
	IF user = 'rif40' THEN
		RAISE INFO 'v4_0_alter_5.sql: User check: %', user;	
	ELSE
		RAISE EXCEPTION 'v4_0_alter_5.sql: C20900: User check failed: % is not rif40', user;	
	END IF;
END;
$$;

--
-- Add zoomlevel support etc
--
\i ../PLpgsql/v4_0_rif40_geo_pkg.sql
--\i ../PLpgsql/rif40_geo_pkg/v4_0_rif40_geo_pkg_simplification.sql
\i ../PLpgsql/v4_0_rif40_xml_pkg.sql
\i ../PLpgsql/v4_0_rif40_sql_pkg_ddl_checks.sql
\i ../PLpgsql/rif40_sql_pkg/rif40_ddl.sql

\set VERBOSITY terse
DO LANGUAGE plpgsql $$
DECLARE
--
-- Functions to enable debug for
--
	rif40_sql_pkg_functions 	VARCHAR[] := ARRAY['rif40_ddl', 
		'rif40_zoom_levels', 'rif40_GetMapAreas', 'rif40_get_geojson_tiles'];
--
	l_function 					VARCHAR;
BEGIN
--
-- Turn on some debug
--
        PERFORM rif40_log_pkg.rif40_log_setup();
        PERFORM rif40_log_pkg.rif40_send_debug_to_info(TRUE);
--
-- Enabled debug on select rif40_sm_pkg functions
--
	FOREACH l_function IN ARRAY rif40_sql_pkg_functions LOOP
		RAISE INFO 'v4_0_alter_5.sql: Enable debug for function: %', l_function;
		PERFORM rif40_log_pkg.rif40_add_to_debug(l_function||':DEBUG1');
	END LOOP;
	
END;
$$;
  
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels()/* 0 */;
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(30);
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(60);	
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(80);
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(88);
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(89.99);
DO LANGUAGE plpgsql $$
BEGIN
	SELECT * FROM rif40_geo_pkg.rif40_zoom_levels(90);
EXCEPTION 
	WHEN others THEN NULL;
END;
$$;	

--
-- DROP t_rif40_geolevels.st_simplify_tolerance
--
ALTER TABLE t_rif40_geolevels DROP COLUMN IF EXISTS st_simplify_tolerance CASCADE;
-- Add areaid_count
DO $$ 
    BEGIN
        BEGIN
            ALTER TABLE t_rif40_geolevels ADD areaid_count INTEGER;
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column areaid_count already exists in t_rif40_geolevels.';
        END;
    END;
$$;

CREATE OR REPLACE VIEW rif40_geolevels AS 
 SELECT a.geography,
    a.geolevel_name,
    a.geolevel_id,
    a.description,
    a.lookup_table,
    a.lookup_desc_column,
    a.shapefile,
    a.centroidsfile,
    a.shapefile_table,
    a.shapefile_area_id_column,
    a.shapefile_desc_column,
    a.centroids_table,
    a.centroids_area_id_column,
    a.avg_npoints_geom,
    a.avg_npoints_opt,
    a.file_geojson_len,
    a.leg_geom,
    a.leg_opt,
    a.covariate_table,
    a.resolution,
    a.comparea,
    a.listing,
    a.restricted,
    a.centroidxcoordinate_column,
    a.centroidycoordinate_column,
	a.areaid_count
   FROM t_rif40_geolevels a
  WHERE sys_context('SAHSU_CONTEXT'::character varying, 'RIF_STUDENT'::character varying)::text = 'YES'::text AND a.restricted <> 1
UNION
 SELECT a.geography,
    a.geolevel_name,
    a.geolevel_id,
    a.description,
    a.lookup_table,
    a.lookup_desc_column,
    a.shapefile,
    a.centroidsfile,
    a.shapefile_table,
    a.shapefile_area_id_column,
    a.shapefile_desc_column,
    a.centroids_table,
    a.centroids_area_id_column,
    a.avg_npoints_geom,
    a.avg_npoints_opt,
    a.file_geojson_len,
    a.leg_geom,
    a.leg_opt,
    a.covariate_table,
    a.resolution,
    a.comparea,
    a.listing,
    a.restricted,
    a.centroidxcoordinate_column,
    a.centroidycoordinate_column,
	a.areaid_count
   FROM t_rif40_geolevels a
  WHERE sys_context('SAHSU_CONTEXT'::character varying, 'RIF_STUDENT'::character varying) IS NULL OR sys_context('SAHSU_CONTEXT'::character varying, 'RIF_STUDENT'::character varying)::text = 'NO'::text
  ORDER BY 1, 3 DESC;

ALTER TABLE rif40_geolevels
  OWNER TO rif40;
GRANT ALL ON TABLE rif40_geolevels TO rif40;
GRANT SELECT ON TABLE rif40_geolevels TO rif_user;
GRANT SELECT ON TABLE rif40_geolevels TO rif_manager;
COMMENT ON VIEW rif40_geolevels
  IS 'Geolevels: hierarchy of level with a geography. Use this table for SELECT; use T_RIF40_GEOLEVELS for INSERT/UPDATE/DELETE. View with RIF_STUDENT security context support. If the user has the RIF_STUDENT role the geolevels are restricted to e.g. LADUA/DISTRICT level resolution or lower. This is controlled by the RESTRICTED field.';
COMMENT ON COLUMN rif40_geolevels.geography IS 'Geography (e.g EW2001)';
COMMENT ON COLUMN rif40_geolevels.geolevel_name IS 'Name of geolevel. This will be a column name in the numerator/denominator tables';
COMMENT ON COLUMN rif40_geolevels.geolevel_id IS 'ID for ordering (1=lowest resolution). Up to 99 supported.';
COMMENT ON COLUMN rif40_geolevels.description IS 'Description';
COMMENT ON COLUMN rif40_geolevels.lookup_table IS 'Lookup table name. This is used to translate codes to the common names, e.g a LADUA of 00BK is &quot;Westminster&quot;';
COMMENT ON COLUMN rif40_geolevels.lookup_desc_column IS 'Lookup table description column name.';
COMMENT ON COLUMN rif40_geolevels.shapefile IS 'Location of the GIS shape file. NULL if PostGress/PostGIS used. Can also use SHAPEFILE_GEOMETRY instead,';
COMMENT ON COLUMN rif40_geolevels.centroidsfile IS 'Location of the GIS centroids file. Can also use CENTROIDXCOORDINATE_COLUMN, CENTROIDYCOORDINATE_COLUMN instead.';
COMMENT ON COLUMN rif40_geolevels.shapefile_table IS 'Table containing GIS shape file data (created using shp2pgsql).';
COMMENT ON COLUMN rif40_geolevels.shapefile_area_id_column IS 'Column containing the AREA_IDs in SHAPEFILE_TABLE';
COMMENT ON COLUMN rif40_geolevels.shapefile_desc_column IS 'Column containing the AREA_ID descriptions in SHAPEFILE_TABLE';
COMMENT ON COLUMN rif40_geolevels.centroids_table IS 'Table containing GIS shape file data with Arc GIS calculated population weighted centroids (created using shp2pgsql). PostGIS does not support population weighted centroids.';
COMMENT ON COLUMN rif40_geolevels.centroids_area_id_column IS 'Column containing the AREA_IDs in CENTROIDS_TABLE. X and Y co-ordinates ciolumns are asummed to be named after CENTROIDXCOORDINATE_COLUMN and CENTROIDYCOORDINATE_COLUMN.';
COMMENT ON COLUMN rif40_geolevels.avg_npoints_geom IS 'Average number of points in a geometry object (AREA_ID). Used to evaluation the impact of ST_SIMPLIFY_TOLERANCE.';
COMMENT ON COLUMN rif40_geolevels.avg_npoints_opt IS 'Average number of points in a ST_SimplifyPreserveTopology() optimsed geometry object (AREA_ID). Used to evaluation the impact of ST_SIMPLIFY_TOLERANCE.';
COMMENT ON COLUMN rif40_geolevels.file_geojson_len IS 'File length estimate (in bytes) for conversion of the entire geolevel geometry to GeoJSON. Used to evaluation the impact of ST_SIMPLIFY_TOLERANCE.';
COMMENT ON COLUMN rif40_geolevels.leg_geom IS 'The average length (in projection units - usually metres) of a vector leg. Used to evaluation the impact of ST_SIMPLIFY_TOLERANCE.';
COMMENT ON COLUMN rif40_geolevels.leg_opt IS 'The average length (in projection units - usually metres) of a ST_SimplifyPreserveTopology() optimsed geometryvector leg. Used to evaluation the impact of ST_SIMPLIFY_TOLERANCE.';
COMMENT ON COLUMN rif40_geolevels.covariate_table IS 'Name of table used for covariates at this geolevel';
COMMENT ON COLUMN rif40_geolevels.resolution IS 'Can use a map for selection at this resolution (0/1)';
COMMENT ON COLUMN rif40_geolevels.comparea IS 'Able to be used as a comparison area (0/1)';
COMMENT ON COLUMN rif40_geolevels.listing IS 'Able to be used in a disease map listing (0/1)';
COMMENT ON COLUMN rif40_geolevels.restricted IS 'Is geolevel access rectricted by Inforamtion Governance restrictions (0/1). If 1 (Yes) then a) students cannot access this geolevel and b) if the system parameter ExtractControl=1 then the user must be granted permission by a RIF_MANAGER to extract from the database the results, data extract and maps tables. This is enforced by the RIF application.';
COMMENT ON COLUMN rif40_geolevels.centroidxcoordinate_column IS 'Lookup table centroid X co-ordinate column name. Can also use CENTROIDSFILE instead.';
COMMENT ON COLUMN rif40_geolevels.centroidycoordinate_column IS 'Lookup table centroid Y co-ordinate column name.';
COMMENT ON COLUMN rif40_geolevels.areaid_count IS 'Area ID count'; /* New for tileMaker */

--SELECT * FROM rif40_columns WHERE column_name_hide = 'ST_SIMPLIFY_TOLERANCE';
DELETE FROM rif40_columns WHERE column_name_hide = 'ST_SIMPLIFY_TOLERANCE';

DELETE FROM rif40_columns
 WHERE column_name_hide IN ('AREAID_COUNT')
   AND table_or_view_name_hide IN ('RIF40_GEOLEVELS', 'T_RIF40_GEOLEVELS'); 
DELETE FROM rif40_columns 
 WHERE column_name_hide IN ('MAXZOOMLEVEL', 'MINZOOMLEVEL', 'GEOMETRYTABLE', 'HIERARCHYTABLE') 
   AND table_or_view_name_hide IN ('RIF40_GEOGRAPHIES'); 

INSERT INTO rif40_columns (table_or_view_name_hide, column_name_hide, nullable, oracle_data_type, comments)   		 
SELECT DISTINCT UPPER(b.relname) AS table_or_view_name_hide, UPPER(d.attname) AS column_name_hide, 
      CASE WHEN d.attnotnull THEN 'NOT NULL' ELSE 'NULL' END AS nullable, t.typname AS oracle_data_type,
       col_description(b.oid, d.attnum) AS comments
  FROM pg_class b, pg_attribute d, pg_type t
 WHERE b.relname::regclass = d.attrelid
   AND d.atttypid = t.oid
   AND b.relname IN ('rif40_geolevels')
   AND b.relkind = 'v'
   AND col_description(b.oid, d.attnum) IS NOT NULL
   AND d.attname NOT IN (
		SELECT LOWER(column_name_hide) AS column_name
 		  FROM rif40_columns
		 WHERE table_or_view_name_hide IN ('RIF40_GEOLEVELS')); 
	 
INSERT INTO rif40_columns (table_or_view_name_hide, column_name_hide, nullable, oracle_data_type, comments)   		 
SELECT DISTINCT UPPER(b.relname) AS table_or_view_name_hide, UPPER(d.attname) AS column_name_hide, 
      CASE WHEN d.attnotnull THEN 'NOT NULL' ELSE 'NULL' END AS nullable, t.typname AS oracle_data_type,
       col_description(b.oid, d.attnum) AS comments
  FROM pg_class b, pg_attribute d, pg_type t
 WHERE b.relname::regclass = d.attrelid
   AND d.atttypid = t.oid
   AND b.relname IN ('t_rif40_geolevels')
   AND b.relkind = 'r'
   AND col_description(b.oid, d.attnum) IS NOT NULL
   AND d.attname NOT IN (
		SELECT LOWER(column_name_hide) AS column_name
 		  FROM rif40_columns
		 WHERE table_or_view_name_hide IN ('T_RIF40_GEOLEVELS')); 
		 
INSERT INTO rif40_columns (table_or_view_name_hide, column_name_hide, nullable, oracle_data_type, comments)   		 
SELECT UPPER(b.relname) AS table_or_view_name_hide, UPPER(d.attname) AS column_name_hide, 
      CASE WHEN d.attnotnull THEN 'NOT NULL' ELSE 'NULL' END AS nullable, t.typname AS oracle_data_type,
       col_description(b.oid, d.attnum) AS comments
  FROM pg_class b, pg_attribute d, pg_type t
 WHERE b.relname::regclass = d.attrelid
   AND d.atttypid = t.oid
   AND b.relname IN ('rif40_geographies')
   AND b.relkind = 'r'
   AND col_description(b.oid, d.attnum) IS NOT NULL
   AND d.attname NOT IN (
		SELECT LOWER(column_name_hide) AS column_name
 		  FROM rif40_columns
		 WHERE table_or_view_name_hide IN ('RIF40_GEOGRAPHIES')); 
		 
WITH b AS (
	SELECT geography, srid, rif40_geo_pkg.rif40_zoom_levels(	
			ST_Y( 														/* Get latitude */
				ST_transform( 											/* Transform to 4326 */
					ST_GeomFromEWKT('SRID='||a.srid||';POINT(0 0)') 	/* Grid Origin */, 
						4326)
				)::NUMERIC) AS zl
	   FROM rif40_geographies a
)
SELECT geography, srid,
       (zl).zoom_level,
       (zl).latitude, 
	   (zl).tiles, 
	   (zl).degrees_per_tile, 
	   (zl).m_x_per_pixel, 
	   (zl).m_y_per_pixel, 
	   (zl).simplify_tolerance,
	   (zl).scale
  FROM b
 WHERE (zl).zoom_level IN (6, 8, 11) /* RIF zoomlevels */;
 
/*
SELECT * FROM rif40_geo_pkg.rif40_zoom_levels();
psql:alter_scripts/v4_0_alter_5.sql:134: INFO:  [DEBUG1] rif40_zoom_levels(): [60001] latitude: 0
 zoom_level | latitude |    tiles     | degrees_per_tile | m_x_per_pixel_est | m_x_per_pixel | m_y_per_pixel |   m_x    |   m_y    | simplify_tolerance |      scale
------------+----------+--------------+------------------+-------------------+---------------+---------------+----------+----------+--------------------+------------------
          0 |        0 |            1 |              360 |            156412 |        155497 |               | 39807187 |          |               1.40 | 1 in 591,225,112
          1 |        0 |            4 |              180 |             78206 |         77748 |               | 19903593 |          |               0.70 | 1 in 295,612,556
          2 |        0 |           16 |               90 |             39103 |         39136 |         39070 | 10018754 | 10001966 |               0.35 | 1 in 148,800,745
          3 |        0 |           64 |               45 |             19552 |         19568 |         19472 |  5009377 |  4984944 |               0.18 | 1 in 74,400,373
          4 |        0 |          256 |             22.5 |              9776 |          9784 |          9723 |  2504689 |  2489167 |               0.09 | 1 in 37,200,186
          5 |        0 |         1024 |            11.25 |              4888 |          4892 |          4860 |  1252344 |  1244120 |               0.04 | 1 in 18,600,093
          6 |        0 |         4096 |            5.625 |              2444 |          2446 |          2430 |   626172 |   622000 |              0.022 | 1 in 9,300,047
          7 |        0 |        16384 |            2.813 |              1222 |          1223 |          1215 |   313086 |   310993 |              0.011 | 1 in 4,650,023
          8 |        0 |        65536 |            1.406 |               611 |           611 |           607 |   156543 |   155495 |             0.0055 | 1 in 2,325,012
          9 |        0 |       262144 |            0.703 |               305 |           306 |           304 |    78272 |    77748 |             0.0027 | 1 in 1,162,506
         10 |        0 |      1048576 |            0.352 |               153 |           153 |           152 |    39136 |    38874 |             0.0014 | 1 in 581,253
         11 |        0 |      4194304 |            0.176 |                76 |            76 |            76 |    19568 |    19437 |            0.00069 | 1 in 290,626
         12 |        0 |     16777216 |            0.088 |                38 |            38 |            38 |     9784 |     9718 |            0.00034 | 1 in 145,313
         13 |        0 |     67108864 |            0.044 |                19 |            19 |            19 |     4892 |     4859 |            0.00017 | 1 in 72,657
         14 |        0 |    268435456 |            0.022 |               9.5 |           9.6 |           9.5 |     2446 |     2430 |          0.0000858 | 1 in 36,328
         15 |        0 |   1073741824 |            0.011 |               4.8 |           4.8 |           4.7 |     1223 |     1215 |          0.0000429 | 1 in 18,164
         16 |        0 |   4294967296 |            0.005 |               2.4 |           2.4 |           2.4 |      611 |      607 |          0.0000215 | 1 in 9,082
         17 |        0 |  17179869184 |            0.003 |              1.19 |          1.19 |          1.19 |      306 |      304 |          0.0000107 | 1 in 4,541
         18 |        0 |  68719476736 |           0.0014 |              0.60 |          0.60 |          0.59 |      153 |      152 |          0.0000054 | 1 in 2,271
         19 |        0 | 274877906944 |          0.00069 |              0.30 |          0.30 |          0.30 |       76 |       76 |          0.0000027 | 1 in 1,135
(20 rows)
 */
--
-- Projection was wrong, is now correct; i.e. SAHSULAND is 3,286 square km is size...
--
SELECT b.geolevel_id, b.geolevel_name, a.zoomlevel,
       COUNT(a.areaid) AS t_areas, 
       SUM(ST_NPoints(a.geom)) AS t_points, 
	   ROUND((SUM(ST_Area(ST_Transform(a.geom, 27700))))::NUMERIC, 1) AS t_area, /* Transform 4326 => 27700 so in metres */
	   ROUND((SUM(ST_perimeter(ST_Transform(a.geom, 27700))))::NUMERIC, 1) AS t_perimeter,
	   ROUND((SUM(ST_Area(ST_Transform(a.geom, 27700)))/10000001)::NUMERIC, 1) AS t_area_km2, 
	   ROUND((SUM(ST_perimeter(ST_Transform(a.geom, 27700)))/1000)::NUMERIC, 1) AS t_perimeter_km
  FROM geometry_sahsuland a, rif40_geolevels b
 WHERE a.geolevel_id = b.geolevel_id
   AND b.geography = 'SAHSULAND'
 GROUP BY b.geolevel_id, b.geolevel_name, a.zoomlevel
 ORDER BY b.geolevel_id, a.zoomlevel;
 
/*
 geolevel_id |  geolevel_name   | zoomlevel | t_areas | t_points |    t_area     | t_perimeter | t_area_km2 | t_perimeter_km
-------------+------------------+-----------+---------+----------+---------------+-------------+------------+----------------
           1 | SAHSU_GRD_LEVEL1 |         6 |       1 |     2931 | 32857231766.8 |   1645397.9 |     3285.7 |         1645.4
           1 | SAHSU_GRD_LEVEL1 |         7 |       1 |     3907 | 32857285476.1 |   1658366.5 |     3285.7 |         1658.4
           1 | SAHSU_GRD_LEVEL1 |         8 |       1 |     5209 | 32857256959.2 |   1666751.1 |     3285.7 |         1666.8
           1 | SAHSU_GRD_LEVEL1 |         9 |       1 |     6945 | 32857269513.8 |   1672475.1 |     3285.7 |         1672.5
           1 | SAHSU_GRD_LEVEL1 |        10 |       1 |     9259 | 32857221701.0 |   1676206.0 |     3285.7 |         1676.2
           1 | SAHSU_GRD_LEVEL1 |        11 |       1 |    12344 | 32857217943.8 |   1677334.0 |     3285.7 |         1677.3
           2 | SAHSU_GRD_LEVEL2 |         6 |      17 |     9548 | 32857288251.2 |   4703034.2 |     3285.7 |         4703.0
           2 | SAHSU_GRD_LEVEL2 |         7 |      17 |    12777 | 32857343159.3 |   4731288.1 |     3285.7 |         4731.3
           2 | SAHSU_GRD_LEVEL2 |         8 |      17 |    17097 | 32857286912.3 |   4750950.5 |     3285.7 |         4751.0
           2 | SAHSU_GRD_LEVEL2 |         9 |      17 |    22832 | 32857235257.6 |   4764624.7 |     3285.7 |         4764.6
           2 | SAHSU_GRD_LEVEL2 |        10 |      17 |    30640 | 32857214725.2 |   4772586.6 |     3285.7 |         4772.6
           2 | SAHSU_GRD_LEVEL2 |        11 |      17 |    41566 | 32857217966.5 |   4774439.2 |     3285.7 |         4774.4
           3 | SAHSU_GRD_LEVEL3 |         6 |     200 |    19222 | 32857283587.4 |   9516423.6 |     3285.7 |         9516.4
           3 | SAHSU_GRD_LEVEL3 |         7 |     200 |    25924 | 32857370298.1 |   9573614.2 |     3285.7 |         9573.6
           3 | SAHSU_GRD_LEVEL3 |         8 |     200 |    34866 | 32857251293.8 |   9611402.8 |     3285.7 |         9611.4
           3 | SAHSU_GRD_LEVEL3 |         9 |     200 |    46753 | 32857222245.8 |   9635716.6 |     3285.7 |         9635.7
           3 | SAHSU_GRD_LEVEL3 |        10 |     200 |    62731 | 32857218639.5 |   9649455.1 |     3285.7 |         9649.5
           3 | SAHSU_GRD_LEVEL3 |        11 |     200 |    85247 | 32857217913.8 |   9651264.4 |     3285.7 |         9651.3
           4 | SAHSU_GRD_LEVEL4 |         6 |    1230 |    28280 | 32857401524.9 |  15054114.9 |     3285.7 |        15054.1
           4 | SAHSU_GRD_LEVEL4 |         7 |    1230 |    39188 | 32857279136.4 |  15167444.5 |     3285.7 |        15167.4
           4 | SAHSU_GRD_LEVEL4 |         8 |    1230 |    53807 | 32857284741.1 |  15230184.0 |     3285.7 |        15230.2
           4 | SAHSU_GRD_LEVEL4 |         9 |    1230 |    73244 | 32857222648.6 |  15266530.5 |     3285.7 |        15266.5
           4 | SAHSU_GRD_LEVEL4 |        10 |    1230 |    99280 | 32857216238.4 |  15286010.4 |     3285.7 |        15286.0
           4 | SAHSU_GRD_LEVEL4 |        11 |    1230 |   135809 | 32857217943.8 |  15287777.0 |     3285.7 |        15287.8
(24 rows)
 */

WITH a AS (
	SELECT srid, 
	       substring(srtext, position('SPHEROID[' in srtext)) AS l_spheroid
	FROM spatial_ref_sys
   WHERE srid = 4326
      OR srid IN (SELECT DISTINCT srid FROM rif40_geographies)   
), d AS (
	SELECT srid, 
	       ST_Distance_Spheroid(
				ST_GeomFromEWKT('SRID='||a.srid||';POINT(0 0)'), /* POINT(lat long) */
				ST_GeomFromEWKT('SRID='||a.srid||';POINT(1 0)'),
				a.l_spheroid::spheroid) one_unit_in_m,
				a.l_spheroid
	  FROM a
), e AS (
	SELECT srid, 
	       ST_Distance_Spheroid(
				ST_GeomFromEWKT('SRID='||d.srid||';POINT(0 0)'), 
				ST_GeomFromEWKT('SRID='||d.srid||';POINT('||100/d.one_unit_in_m||' 0)'),
				d.l_spheroid::spheroid) one_hundred_m
	  FROM d
)			
SELECT b.geography, 
       a.srid, 
	   d.one_unit_in_m,
	   e.one_hundred_m,
       substring(a.l_spheroid, 1, position(',AUTHORITY[' in a.l_spheroid)-1)||']' AS spheroid
  FROM d, e, a LEFT OUTER JOIN rif40_geographies b ON (a.srid = b.srid)
 WHERE a.srid = d.srid
   AND d.srid = e.srid;
/*
 geography | srid  |  one_unit_in_m   | one_hundred_m |                   spheroid
-----------+-------+------------------+---------------+-----------------------------------------------
           |  4326 | 111319.490779206 |           100 | SPHEROID["WGS 84",6378137,298.257223563]
 SAHSU     | 27700 | 111309.479501005 |           100 | SPHEROID["Airy 1830",6377563.396,299.3249646]
 EW01      | 27700 | 111309.479501005 |           100 | SPHEROID["Airy 1830",6377563.396,299.3249646]
 UK91      | 27700 | 111309.479501005 |           100 | SPHEROID["Airy 1830",6377563.396,299.3249646]
(4 rows)
 */
  
SELECT substring(a1.spheroid, 1, position(',AUTHORITY[' in a1.spheroid)-1)||']' AS spheroid
  FROM (
	SELECT substring(srtext, position('SPHEROID[' in srtext)) AS spheroid
		FROM spatial_ref_sys	
		WHERE srid = 4326) a1;
/*
tileinfo 17 70406 42988
-I-> Input: Osm-Tile z/x/y[17/70406/42988] tms[88083]
tile_osm : 17/70406/42988
tile_tms : 17/70406/88083
center=13.37722778,52.51538515
bbox=13.375854492,52.514549436,13.378601074,52.516220864
SRID=4326;POINT(13.37722778 52.51538515)
SRID=4326;POLYGON((13.375854492 52.516220864,13.378601074 52.516220864,13.378601074 52.514549436,13.375854492 52.514549436,13.375854492 52.516220864))
wget 'http://mt3.google.com/vt/lyrs=s,h&z=17&x=70406&y=42988' -O 17_70406_42988_osm.png */

SELECT rif40_geo_pkg.longitude2tile(13.37722778, 17);
-- 70406
SELECT rif40_geo_pkg.tile2longitude(70406, 17);
-- 13.37722778
SELECT rif40_geo_pkg.latitude2tile(52.51538515, 17);
-- 42988
SELECT rif40_geo_pkg.tile2latitude(42988, 17);
-- 52.51538515
SELECT rif40_geo_pkg.y_osm_tile2_tms_tile(rif40_geo_pkg.latitude2tile(52.51538515, 17), 17);
-- 88083

WITH a AS (
	SELECT *
          FROM rif40_xml_pkg.rif40_getGeoLevelBoundsForArea('SAHSULAND', 'SAHSU_GRD_LEVEL2', '01.004')
), b AS (
	SELECT ST_Centroid(ST_MakeEnvelope(a.x_min, a.y_min, a.x_max, a.y_max)) AS centroid
	  FROM a
), c AS (
	SELECT ST_X(b.centroid) AS X_centroid, ST_Y(b.centroid) AS Y_centroid, 11 AS zoom_level	  
	  FROM b
), d AS (
	SELECT zoom_level, X_centroid, Y_centroid, 
		   rif40_geo_pkg.latitude2tile(Y_centroid, zoom_level) AS Y_tile,
		   rif40_geo_pkg.longitude2tile(X_centroid, zoom_level) AS X_tile
	  FROM c
), e AS (
	SELECT zoom_level, X_centroid, Y_centroid,
		   rif40_geo_pkg.tile2latitude(Y_tile, zoom_level) AS Y_min,
		   rif40_geo_pkg.tile2longitude(X_tile, zoom_level) AS X_min,	
		   rif40_geo_pkg.tile2latitude(Y_tile+1, zoom_level) AS Y_max,
		   rif40_geo_pkg.tile2longitude(X_tile+1, zoom_level) AS X_max,
		   X_tile, Y_tile
	  FROM d
) 
SELECT * FROM e;

/*
 zoom_level |    x_centroid    |    y_centroid    |       x_min       |    y_min    |       x_max       |  y_max   | x_tile | y_tile
------------+------------------+------------------+-------------------+-------------+-------------------+----------+--------+--------
         11 | -6.5067982673645 | 54.8289222717285 | -6.48998333253028 | 54.66796875 | -6.66460756202846 | 54.84375 |   1061 |   1335
		
 */
--
-- rif40_GetMapAreas interface
--
\pset title 'rif40_GetMapAreas interface'
WITH a AS (
	SELECT *
          FROM rif40_xml_pkg.rif40_getGeoLevelBoundsForArea('SAHSULAND', 'SAHSU_GRD_LEVEL2', '01.004')
) 
SELECT rif40_xml_pkg.rif40_GetMapAreas(
			'SAHSULAND' /* Geography */, 
			'SAHSU_GRD_LEVEL4' 	/* geolevel view */, 
			a.y_max, a.x_max, a.y_min, a.x_min /* Bounding box - from cte */) AS json 
  FROM a LIMIT 4;
  
\set debug_level 1
\set VERBOSITY terse

--
-- Create types for fast JSON tile making
--
DROP AGGREGATE IF EXISTS array_agg_mult(anyarray);
CREATE AGGREGATE array_agg_mult(anyarray) (
    SFUNC = array_cat,
    STYPE = anyarray,
    INITCOND = '{}'
);
COMMENT ON AGGREGATE array_agg_mult(anyarray) IS 'Allow array_agg() to aggregate anyarray';

DROP TYPE IF EXISTS rif40_goejson_type;
CREATE TYPE rif40_goejson_type AS (
	area_id 					Text, 
	name						Text,
	area 						NUMERIC, 
	total_males					INTEGER,
	total_females				INTEGER, 
	population_year				INTEGER,
	gid							INTEGER);
COMMENT ON TYPE rif40_goejson_type IS 'Special type to allow ROW() elements to be named; for ROW_TO_JSON()';

/*
 geolevel_name | geography | zoomlevel | x_tile_number | y_tile_number |             optimised_topojson              |         tile_
id
---------------+-----------+-----------+---------------+---------------+---------------------------------------------+--------------
------------
 LEVEL1        | SAHSU     |         9 |           264 |           330 | {"type": "FeatureCollection","features":[]} | SAHSU_1_LEVEL
1_9_264_330
 LEVEL1        | SAHSU     |         9 |           265 |           330 | {"type": "FeatureCollection","features":[]} | SAHSU_1_LEVEL
1_9_265_330
(2 rows)
 */	
--
-- Test performance (FAST .. 31.834 ms)
--
\timing on

/* OLD tile table: no null tiles
SELECT optimised_topojson::Text
  FROM t_rif40_sahsu_maptiles 
 WHERE geolevel_name = 'LEVEL2'
   AND LENGTH(optimised_topojson::Text) < 100 LiMIT 10;
 optimised_topojson
--------------------
(0 rows)
  
SELECT geolevel_name, geography, zoomlevel, 
       MIN(x_tile_number) AS min_x, MAX(x_tile_number) AS max_x, MIN(y_tile_number) AS min_y, MAX(y_tile_number) AS max_y,
	   COUNT(tiles) AS tiles
  FROM t_rif40_sahsu_maptiles 
 WHERE geolevel_name = 'LEVEL2'
 GROUP BY geolevel_name, geography, zoomlevel
 ORDER BY geolevel_name, geography, zoomlevel;

 geolevel_name | geography | zoomlevel | min_x | max_x | min_y | max_y | tiles
---------------+-----------+-----------+-------+-------+-------+-------+-------
 LEVEL2        | SAHSU     |         0 |     0 |     0 |     0 |     0 |     1
 LEVEL2        | SAHSU     |         1 |     0 |     0 |     0 |     0 |     1
 LEVEL2        | SAHSU     |         2 |     1 |     1 |     1 |     1 |     1
 LEVEL2        | SAHSU     |         3 |     3 |     3 |     2 |     2 |     1
 LEVEL2        | SAHSU     |         4 |     7 |     7 |     5 |     5 |     1
 LEVEL2        | SAHSU     |         5 |    15 |    15 |    10 |    10 |     1
 LEVEL2        | SAHSU     |         6 |    30 |    31 |    20 |    20 |     2
 LEVEL2        | SAHSU     |         7 |    61 |    62 |    40 |    41 |     4
 LEVEL2        | SAHSU     |         8 |   122 |   124 |    80 |    83 |    11
 LEVEL2        | SAHSU     |         9 |   245 |   249 |   160 |   167 |    33
 LEVEL2        | SAHSU     |        10 |   490 |   498 |   321 |   335 |   110
 LEVEL2        | SAHSU     |        11 |   980 |   996 |   642 |   670 |   378
(12 rows)
 */

-- NEW Tile table. Note tiles present in higher zoomlevel but same tilees are missing from lower geolevels
-- The view puts them back
SELECT geolevel_id, zoomlevel, 
       MIN(x) AS min_x, MAX(x) AS max_x, MIN(y) AS min_y, MAX(y) AS max_y,
	   COUNT(tile_id) AS tiles
  FROM t_tiles_sahsuland 
 WHERE geolevel_id = 2
 GROUP BY geolevel_id, zoomlevel
 ORDER BY geolevel_id, zoomlevel;
/*
 geolevel_id | zoomlevel | min_x | max_x | min_y | max_y | tiles
-------------+-----------+-------+-------+-------+-------+-------
           2 |         0 |     0 |     0 |     0 |     0 |     1
           2 |         1 |     0 |     0 |     0 |     0 |     1
           2 |         2 |     1 |     1 |     1 |     1 |     1
           2 |         3 |     3 |     3 |     2 |     2 |     1
           2 |         4 |     7 |     7 |     5 |     5 |     1
           2 |         5 |    15 |    15 |    10 |    10 |     1
           2 |         6 |    30 |    31 |    20 |    20 |     2
           2 |         7 |    61 |    62 |    40 |    41 |     4
           2 |         8 |   122 |   124 |    80 |    83 |    11
           2 |         9 |   245 |   249 |   160 |   167 |    29
           2 |        10 |   490 |   498 |   321 |   335 |    92
           2 |        11 |   980 |   996 |   642 |   670 |   235
(12 rows)
 */

-- Adding back the view shows the numbers are the same (SLOW!)
/*
WITH a AS (
	SELECT geolevel_id, zoomlevel, 
		   MIN(x) AS min_x, MAX(x) AS max_x, MIN(y) AS min_y, MAX(y) AS max_y,
		   COUNT(tile_id) AS tiles
	  FROM t_tiles_sahsuland 
	 WHERE geolevel_id = 2
	 GROUP BY geolevel_id, zoomlevel
)
SELECT b.geolevel_name, b.zoomlevel, 
       MIN(b.x) AS min_x, MAX(b.x) AS max_x, MIN(b.y) AS min_y, MAX(b.y) AS max_y,
	   COUNT(tile_id) AS tiles,
	   SUM(CASE WHEN b.optimised_topojson::Text = '{"type": "FeatureCollection","features":[]}' THEN 0 ELSE 1 END) AS not_null_tiles
  FROM a, tiles_sahsuland b 
 WHERE a.geolevel_id = b.geolevel_id
   AND a.zoomlevel   = b.zoomlevel
   AND b.x BETWEEN a.min_x AND a.max_x
   AND b.y BETWEEN a.min_y AND a.max_y
 GROUP BY b.geolevel_name, b.zoomlevel
 ORDER BY b.geolevel_name, b.zoomlevel;

  geolevel_name   | zoomlevel | min_x | max_x | min_y | max_y | tiles | not_null_tiles
------------------+-----------+-------+-------+-------+-------+-------+----------------
 SAHSU_GRD_LEVEL2 |         0 |     0 |     0 |     0 |     0 |     1 |              1
 SAHSU_GRD_LEVEL2 |         1 |     0 |     0 |     0 |     0 |     1 |              1
 SAHSU_GRD_LEVEL2 |         2 |     1 |     1 |     1 |     1 |     1 |              1
 SAHSU_GRD_LEVEL2 |         3 |     3 |     3 |     2 |     2 |     1 |              1
 SAHSU_GRD_LEVEL2 |         4 |     7 |     7 |     5 |     5 |     1 |              1
 SAHSU_GRD_LEVEL2 |         5 |    15 |    15 |    10 |    10 |     1 |              1
 SAHSU_GRD_LEVEL2 |         6 |    30 |    31 |    20 |    20 |     2 |              2
 SAHSU_GRD_LEVEL2 |         7 |    61 |    62 |    40 |    41 |     4 |              4
 SAHSU_GRD_LEVEL2 |         8 |   122 |   124 |    80 |    83 |    12 |             11
 SAHSU_GRD_LEVEL2 |         9 |   245 |   249 |   160 |   167 |    40 |             29
 SAHSU_GRD_LEVEL2 |        10 |   490 |   498 |   321 |   335 |   135 |             92
 SAHSU_GRD_LEVEL2 |        11 |   980 |   996 |   642 |   670 |   493 |            235
(12 rows)
 */

/*
-- Extra
WITH a AS (
	SELECT geolevel_id, zoomlevel, 
		   MIN(x) AS min_x, MAX(x) AS max_x, MIN(y) AS min_y, MAX(y) AS max_y,
		   COUNT(tile_id) AS tiles
	  FROM t_tiles_sahsuland 
	 GROUP BY geolevel_id, zoomlevel
), b AS (
	SELECT b.geolevel_id, b.zoomlevel, b.x, b.y
	  FROM a, tiles_sahsuland b 
	 WHERE a.geolevel_id = b.geolevel_id
	   AND a.zoomlevel   = b.zoomlevel
	   AND b.x BETWEEN a.min_x AND a.max_x
	   AND b.y BETWEEN a.min_y AND a.max_y
	EXCEPT 
	SELECT CASE 
				WHEN geolevel_name = 'LEVEL1' THEN 1 
				WHEN geolevel_name = 'LEVEL2' THEN 2 
				WHEN geolevel_name = 'LEVEL3' THEN 3 
				WHEN geolevel_name = 'LEVEL4' THEN 4 
				ELSE NULL
		   END AS geolevel_id, 
	       zoomlevel, x_tile_number, y_tile_number
	  FROM t_rif40_sahsu_maptiles   
)
SELECT b.*, 
       SUBSTRING(c.optimised_topojson::Text FROM 1 FOR 50) AS optimised_topojson 
  FROM b, tiles_sahsuland c 
	 WHERE c.geolevel_id = b.geolevel_id
	   AND c.zoomlevel   = b.zoomlevel
	   AND c.x           = b.x
	   AND c.y           = b.y
       AND c.optimised_topojson::Text != '{"type": "FeatureCollection","features":[]}'
 ORDER BY 1, 2, 3, 4;
 geolevel_id | zoomlevel | x | y | optimised_topojson
-------------+-----------+---+---+--------------------
(0 rows)
*/

/*
-- Missing (goelevel 1 only has 1 row in t_tiles_sahsuland)
WITH a AS (
	SELECT geolevel_id, zoomlevel, 
		   MIN(x) AS min_x, MAX(x) AS max_x, MIN(y) AS min_y, MAX(y) AS max_y,
		   COUNT(tile_id) AS tiles
	  FROM t_tiles_sahsuland 
	 WHERE geolevel_id > 1
	 GROUP BY geolevel_id, zoomlevel
	UNION
	SELECT 1 geolevel_id, zoomlevel, -* geolevel_id 1 has only 1 tile; so use geolevel_id 2 *-
		   MIN(x) AS min_x, MAX(x) AS max_x, MIN(y) AS min_y, MAX(y) AS max_y,
		   COUNT(tile_id) AS tiles
	  FROM t_tiles_sahsuland 
	 WHERE geolevel_id = 2
	 GROUP BY geolevel_id, zoomlevel	
)
SELECT CASE 
			WHEN geolevel_name = 'LEVEL1' THEN 1 
			WHEN geolevel_name = 'LEVEL2' THEN 2 
			WHEN geolevel_name = 'LEVEL3' THEN 3 
			WHEN geolevel_name = 'LEVEL4' THEN 4 
			ELSE NULL
	   END AS geolevel_id, 
	   zoomlevel, x_tile_number, y_tile_number
  FROM t_rif40_sahsu_maptiles 
EXCEPT 
SELECT b.geolevel_id, b.zoomlevel, b.x, b.y
  FROM a, tiles_sahsuland b 
 WHERE a.geolevel_id = b.geolevel_id
   AND a.zoomlevel   = b.zoomlevel
   AND b.x BETWEEN a.min_x AND a.max_x
   AND b.y BETWEEN a.min_y AND a.max_y
 ORDER BY 1, 2, 3, 4;
 geolevel_id | zoomlevel | x_tile_number | y_tile_number
-------------+-----------+---------------+---------------
(0 rows)
 */
 /*
SELECT z.geolevel_name, z.geolevel_id, z.zoomlevel, z.no_area_ids,
	   MIN(z.x) AS min_x, MAX(z.x) AS max_x, MIN(z.y) AS min_y, MAX(z.y) AS max_y,
	   COUNT(z.tile_id) AS tiles,
	   SUM(CASE WHEN z.optimised_topojson::Text = '{"type": "FeatureCollection","features":[]}' THEN 1 ELSE 0 END) AS null_tiles
  FROM tiles_sahsuland z
 WHERE geolevel_id = 1
 GROUP BY z.geolevel_name, z.geolevel_id, z.zoomlevel, z.no_area_ids
 ORDER BY z.geolevel_name, z.geolevel_id, z.zoomlevel, z.no_area_ids;

  geolevel_name   | geolevel_id | zoomlevel | no_area_ids | min_x | max_x | min_y | max_y |  tiles  | null_tiles
------------------+-------------+-----------+-------------+-------+-------+-------+-------+---------+------------
 SAHSU_GRD_LEVEL1 |           1 |         0 |           0 |     0 |     0 |     0 |     0 |       1 |          0
 SAHSU_GRD_LEVEL1 |           1 |         1 |           0 |     0 |     1 |     0 |     1 |       4 |          0
 SAHSU_GRD_LEVEL1 |           1 |         2 |           0 |     0 |     3 |     0 |     3 |      16 |          0
 SAHSU_GRD_LEVEL1 |           1 |         3 |           0 |     0 |     7 |     0 |     7 |      64 |          0
 SAHSU_GRD_LEVEL1 |           1 |         4 |           0 |     0 |    15 |     0 |    15 |     256 |          0
 SAHSU_GRD_LEVEL1 |           1 |         5 |           0 |     0 |    31 |     0 |    31 |    1024 |          0
 SAHSU_GRD_LEVEL1 |           1 |         6 |           0 |     0 |    63 |     0 |    63 |    4096 |          0
 SAHSU_GRD_LEVEL1 |           1 |         7 |           0 |     0 |   127 |     0 |   127 |   16384 |          0
 SAHSU_GRD_LEVEL1 |           1 |         8 |           0 |     0 |   255 |     0 |   255 |   65536 |          0
 SAHSU_GRD_LEVEL1 |           1 |         9 |           0 |     0 |   511 |     0 |   511 |  262144 |          0
 SAHSU_GRD_LEVEL1 |           1 |        10 |           0 |     0 |  1023 |     0 |  1023 | 1048576 |          0
 SAHSU_GRD_LEVEL1 |           1 |        11 |           0 |     0 |  2047 |     0 |  2047 | 4194304 |          0
(12 rows)
*/

/*
SELECT geolevel_name, geography, zoomlevel, x_tile_number, y_tile_number, 
       SUBSTRING(optimised_topojson::Text FROM 1 FOR 50) AS optimised_topojson, tile_id
  FROM rif40_sahsu_maptiles
 WHERE geolevel_name = 'LEVEL4'
   AND zoomlevel     = 9
   AND x_tile_number IN (245, 247)
   AND y_tile_number IN (160, 169)
 ORDER BY tile_id; 

 geolevel_name | geography | zoomlevel | x_tile_number | y_tile_number |                 optimised_topojson                 |  tile_id
---------------+-----------+-----------+---------------+---------------+----------------------------------------------------+--------------------------
 LEVEL4        | SAHSU     |         9 |           245 |           160 | {"type": "FeatureCollection","features":[]}        | SAHSU_4_LEVEL4_9_245_160
 LEVEL4        | SAHSU     |         9 |           245 |           169 | {"type": "FeatureCollection","features":[]}        | SAHSU_4_LEVEL4_9_245_169
 LEVEL4        | SAHSU     |         9 |           247 |           160 | {"type":"Topology","objects":{"9_247_160":{"type": | SAHSU_4_LEVEL4_9_247_160
 LEVEL4        | SAHSU     |         9 |           247 |           169 | {"type": "FeatureCollection","features":[]}        | SAHSU_4_LEVEL4_9_247_169
(4 rows)
 */
/* EXPLAIN (ANALYZE, BUFFERS) */ SELECT geolevel_name, geography, zoomlevel, x, y, 
       SUBSTRING(optimised_topojson::Text FROM 1 FOR 50) AS optimised_topojson, tile_id
  FROM tiles_sahsuland
 WHERE geolevel_id = 4
   AND zoomlevel   = 9
   AND x IN (245, 247)
   AND y IN (160, 169)
 ORDER BY tile_id; 
/*
  geolevel_name   | geography | zoomlevel |  x  |  y  |                 optimised_topojson                 |           tile_id
------------------+-----------+-----------+-----+-----+----------------------------------------------------+------------------------------
 SAHSU_GRD_LEVEL4 | SAHSULAND |         9 | 245 | 160 | {"type": "FeatureCollection","features":[]}        | 4_SAHSU_GRD_LEVEL4_9_245_160
 SAHSU_GRD_LEVEL4 | SAHSULAND |         9 | 245 | 169 | {"type": "FeatureCollection","features":[]}        | 4_SAHSU_GRD_LEVEL4_9_245_169
 SAHSU_GRD_LEVEL4 | SAHSULAND |         9 | 247 | 160 | {"type":"Topology","objects":{"collection":{"type" | 4_SAHSU_GRD_LEVEL4_9_247_160
 SAHSU_GRD_LEVEL4 | SAHSULAND |         9 | 247 | 169 | {"type": "FeatureCollection","features":[]}        | 4_SAHSU_GRD_LEVEL4_9_247_169
(4 rows)
 */

--
-- Test new rif40_get_geojson_tiles()
-- 	
WITH a AS (
	SELECT *
          FROM rif40_xml_pkg.rif40_getGeoLevelBoundsForArea('SAHSULAND', 'SAHSU_GRD_LEVEL2', '01.004')
), b AS (
	SELECT ST_Centroid(ST_MakeEnvelope(a.x_min, a.y_min, a.x_max, a.y_max)) AS centroid
	  FROM a
), c AS (
	SELECT ST_X(b.centroid) AS X_centroid, ST_Y(b.centroid) AS Y_centroid, 11 AS zoom_level	  
	  FROM b
), d AS (
	SELECT zoom_level, X_centroid, Y_centroid, 
		   rif40_geo_pkg.latitude2tile(Y_centroid, zoom_level) AS Y_tile,
		   rif40_geo_pkg.longitude2tile(X_centroid, zoom_level) AS X_tile
	  FROM c
), e AS (
	SELECT zoom_level, X_centroid, Y_centroid,
		   rif40_geo_pkg.tile2latitude(Y_tile, zoom_level) AS Y_min,
		   rif40_geo_pkg.tile2longitude(X_tile, zoom_level) AS X_min,	
		   rif40_geo_pkg.tile2latitude(Y_tile+1, zoom_level) AS Y_max,
		   rif40_geo_pkg.tile2longitude(X_tile+1, zoom_level) AS X_max,
		   X_tile, Y_tile
	  FROM d
) 
SELECT SUBSTRING(
		rif40_xml_pkg.rif40_get_geojson_tiles(
			'SAHSULAND'::VARCHAR 	/* Geography */, 
			'SAHSU_GRD_LEVEL4'::VARCHAR 	/* geolevel view */, 
			e.y_max::REAL, e.x_max::REAL, e.y_min::REAL, e.x_min::REAL, /* Bounding box - from cte */
			e.zoom_level::INTEGER /* Zoom level */,
			FALSE /* Check tile co-ordinates [Default: FALSE] */,			
			FALSE /* Lack of topoJSON is an error [Default: TRUE] */)::Text 
			FROM 1 FOR 160 /* Truncate to 160 chars */) AS json 
  FROM e LIMIT 4;
			
--
-- WARNING:  rif40_get_geojson_tiles(): Geography: SAHSU, <geoevel view> LEVEL4 bound [-2.8125, 50.7365, 0, 52.4828] returns no tiles, took: 00:00:00.031.
-- CONTEXT:  SQL statement "SELECT rif40_log_pkg.rif40_log('WARNING', 'rif40_get_geojson_tiles',
--                        'Geography: %, <geoevel view> % bound [%, %, %, %] returns no tiles, took: %.',
--                        l_geography::VARCHAR            /* Geography */,
--                        l_geolevel_view::VARCHAR        /* Geoelvel view */,
--                        x_min::VARCHAR                          /* Xmin */,
--                        y_min::VARCHAR                          /* Ymin */,
--                        x_max::VARCHAR                          /* Xmax */,
--                        y_max::VARCHAR                          /* Ymax */,
--                        took::VARCHAR                           /* Time taken */)"
--PL/pgSQL function rif40_xml_pkg.rif40_get_geojson_tiles(character varying,character varying,real,real,real,real,integer,boolean,boolean) line 612 at PERFORM
--           rif40_get_geojson_tiles
-----------------------------------------------
-- {"type": "FeatureCollection","features":[]}
--(1 row)
--			
--
-- Display tile summary [SLOW!]
-- 
/*
SELECT geolevel_name, zoomlevel, SUM(no_area_ids) AS tiles_with_no_area_ids, COUNT(optimised_topojson) AS aaas
  FROM rif40_sahsu_maptiles
 GROUP BY geolevel_name, zoomlevel
 ORDER BY geolevel_name, zoomlevel; 
 */
/*
                                                          rif40_GetMapAreas interface
 geolevel_name | geography | zoomlevel | x_tile_number | y_tile_number |             optimised_topojson              |         tile_id
---------------+-----------+-----------+---------------+---------------+---------------------------------------------+--------------------------
 LEVEL1        | SAHSU     |         9 |           264 |           330 | {"type": "FeatureCollection","features":[]} | SAHSU_1_LEVEL1_9_264_330
 LEVEL1        | SAHSU     |         9 |           265 |           330 | "X"                                         | SAHSU_1_LEVEL1_9_265_330
(2 rows)

Time: 31.834 ms
                 rif40_GetMapAreas interface
 geolevel_name | zoomlevel | tiles_with_no_area_ids |  aaas
---------------+-----------+------------------------+---------
 LEVEL1        |         0 |                      0 |       1
 LEVEL1        |         1 |                      3 |       4
 LEVEL1        |         2 |                     15 |      16
 LEVEL1        |         3 |                     63 |      64
 LEVEL1        |         4 |                    255 |     256
 LEVEL1        |         5 |                   1023 |    1024
 LEVEL1        |         6 |                   4094 |    4096
 LEVEL1        |         7 |                  16380 |   16384
 LEVEL1        |         8 |                  65527 |   65536
 LEVEL1        |         9 |                 262125 |  262144
 LEVEL1        |        10 |                1048515 | 1048576
 LEVEL1        |        11 |                4194109 | 4194304
 LEVEL2        |         0 |                      0 |       1
 LEVEL2        |         1 |                      3 |       4
 LEVEL2        |         2 |                     15 |      16
 LEVEL2        |         3 |                     63 |      64
 LEVEL2        |         4 |                    255 |     256
 LEVEL2        |         5 |                   1023 |    1024
 LEVEL2        |         6 |                   4094 |    4096
 LEVEL2        |         7 |                  16380 |   16384
 LEVEL2        |         8 |                  65527 |   65536
 LEVEL2        |         9 |                 262125 |  262144
 LEVEL2        |        10 |                1048515 | 1048576
 LEVEL2        |        11 |                4194109 | 4194304
 LEVEL3        |         0 |                      0 |       1
 LEVEL3        |         1 |                      3 |       4
 LEVEL3        |         2 |                     15 |      16
 LEVEL3        |         3 |                     63 |      64
 LEVEL3        |         4 |                    255 |     256
 LEVEL3        |         5 |                   1023 |    1024
 LEVEL3        |         6 |                   4094 |    4096
 LEVEL3        |         7 |                  16380 |   16384
 LEVEL3        |         8 |                  65527 |   65536
 LEVEL3        |         9 |                 262125 |  262144
 LEVEL3        |        10 |                1048515 | 1048576
 LEVEL3        |        11 |                4194109 | 4194304
 LEVEL4        |         0 |                      0 |       1
 LEVEL4        |         1 |                      3 |       4
 LEVEL4        |         2 |                     15 |      16
 LEVEL4        |         3 |                     63 |      64
 LEVEL4        |         4 |                    255 |     256
 LEVEL4        |         5 |                   1023 |    1024
 LEVEL4        |         6 |                   4094 |    4096
 LEVEL4        |         7 |                  16380 |   16384
 LEVEL4        |         8 |                  65527 |   65536
 LEVEL4        |         9 |                 262125 |  262144
 LEVEL4        |        10 |                1048515 | 1048576
 LEVEL4        |        11 |                4194109 | 4194304
(48 rows)
 */ 
 
--DO LANGUAGE plpgsql $$
--BEGIN
--	RAISE INFO 'Aborting (script being tested)';
--	RAISE EXCEPTION 'C20999: Abort';
--END;
--$$;
 
-- END;

--
-- Test new rif40_get_geojson_tiles() produces topoJSON
-- 	
WITH a AS (
	SELECT *
          FROM rif40_xml_pkg.rif40_getGeoLevelBoundsForArea('SAHSULAND', 'SAHSU_GRD_LEVEL2', '01.004')
), b AS (
	SELECT ST_Centroid(ST_MakeEnvelope(a.x_min, a.y_min, a.x_max, a.y_max)) AS centroid
	  FROM a
), c AS (
	SELECT ST_X(b.centroid) AS X_centroid, ST_Y(b.centroid) AS Y_centroid, 11 AS zoom_level	  
	  FROM b
), d AS (
	SELECT zoom_level, X_centroid, Y_centroid, 
		   rif40_geo_pkg.latitude2tile(Y_centroid, zoom_level) AS Y_tile,
		   rif40_geo_pkg.longitude2tile(X_centroid, zoom_level) AS X_tile
	  FROM c
), e AS (
	SELECT zoom_level, X_centroid, Y_centroid,
		   rif40_geo_pkg.tile2latitude(Y_tile, zoom_level) AS Y_min,
		   rif40_geo_pkg.tile2longitude(X_tile, zoom_level) AS X_min,	
		   rif40_geo_pkg.tile2latitude(Y_tile+1, zoom_level) AS Y_max,
		   rif40_geo_pkg.tile2longitude(X_tile+1, zoom_level) AS X_max,
		   X_tile, Y_tile
	  FROM d
) 
SELECT SUBSTRING(
		rif40_xml_pkg.rif40_get_geojson_tiles(
			'SAHSULAND'::VARCHAR 	/* Geography */, 
			'SAHSU_GRD_LEVEL4'::VARCHAR 	/* geolevel view */, 
			e.y_max::REAL, e.x_max::REAL, e.y_min::REAL, e.x_min::REAL, /* Bounding box - from cte */
			e.zoom_level::INTEGER /* Zoom level */,
			FALSE /* Check tile co-ordinates [Default: FALSE] */,
			TRUE /* Lack of topoJSON is an error [DEFAULT] */)::Text 
			FROM 1 FOR 160 /* Truncate to 160 chars */) AS json 
  FROM e LIMIT 4;
 
--
-- New function
-- 
SELECT substring(rif40_xml_pkg.rif40_get_geojson_tiles(
			'SAHSULAND'::VARCHAR 	/* Geography */, 
			'SAHSU_GRD_LEVEL4'::VARCHAR 	/* geolevel view */, 
			11::INTEGER 		/* Zoom level */,
			989::INTEGER 		/* X tile number */,
			660::INTEGER		/* Y tile number */)::Text from 1 for 100) AS json; 

SELECT geolevel_id, zoomlevel, 
       MIN(x) AS min_x_tile, MAX(x) AS max_x_tile,
       MIN(y) AS min_y_tile, MAX(y) AS max_y_tile, 
	   COUNT(zoomlevel) AS total
  FROM t_tiles_sahsuland
  GROUP BY geolevel_id, zoomlevel
  ORDER BY 1, 2;
/*  
 geolevel_id | zoomlevel | min_x_tile | max_x_tile | min_y_tile | max_y_tile | total
-------------+-----------+------------+------------+------------+------------+-------
           1 |         0 |          0 |          0 |          0 |          0 |     1
           2 |         0 |          0 |          0 |          0 |          0 |     1
           2 |         1 |          0 |          0 |          0 |          0 |     1
           2 |         2 |          1 |          1 |          1 |          1 |     1
           2 |         3 |          3 |          3 |          2 |          2 |     1
           2 |         4 |          7 |          7 |          5 |          5 |     1
           2 |         5 |         15 |         15 |         10 |         10 |     1
           2 |         6 |         30 |         31 |         20 |         20 |     2
           2 |         7 |         61 |         62 |         40 |         41 |     4
           2 |         8 |        122 |        124 |         80 |         83 |    11
           2 |         9 |        245 |        249 |        160 |        167 |    29
           2 |        10 |        490 |        498 |        321 |        335 |    92
           2 |        11 |        980 |        996 |        642 |        670 |   235
           3 |         0 |          0 |          0 |          0 |          0 |     1
           3 |         1 |          0 |          0 |          0 |          0 |     1
           3 |         2 |          1 |          1 |          1 |          1 |     1
           3 |         3 |          3 |          3 |          2 |          2 |     1
           3 |         4 |          7 |          7 |          5 |          5 |     1
           3 |         5 |         15 |         15 |         10 |         10 |     1
           3 |         6 |         30 |         31 |         20 |         20 |     2
           3 |         7 |         61 |         62 |         40 |         41 |     4
           3 |         8 |        122 |        124 |         80 |         83 |    11
           3 |         9 |        245 |        249 |        160 |        167 |    29
           3 |        10 |        490 |        498 |        321 |        335 |    93
           3 |        11 |        980 |        996 |        642 |        670 |   274
           4 |         0 |          0 |          0 |          0 |          0 |     1
           4 |         1 |          0 |          0 |          0 |          0 |     1
           4 |         2 |          1 |          1 |          1 |          1 |     1
           4 |         3 |          3 |          3 |          2 |          2 |     1
           4 |         4 |          7 |          7 |          5 |          5 |     1
           4 |         5 |         15 |         15 |         10 |         10 |     1
           4 |         6 |         30 |         31 |         20 |         20 |     2
           4 |         7 |         61 |         62 |         40 |         41 |     4
           4 |         8 |        122 |        124 |         80 |         83 |    11
           4 |         9 |        245 |        249 |        160 |        167 |    29
           4 |        10 |        490 |        498 |        321 |        335 |    93
           4 |        11 |        980 |        996 |        642 |        670 |   287
(37 rows)

Time: 1.191 ms
 */ 

--DO LANGUAGE plpgsql $$
--BEGIN
--	RAISE INFO 'Aborting (script being tested)';
--	RAISE EXCEPTION 'C20999: Abort';
--END;
--$$;

END;

--
-- Eof