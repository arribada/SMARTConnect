CREATE EXTENSION postgis;

/* Drop Tables */
DROP SCHEMA If exists connect CASCADE;
CREATE SCHEMA connect;

DROP TABLE IF EXISTS connect.ca_plug_version;
DROP TABLE IF EXISTS connect.conservation_area_info;
DROP TABLE IF EXISTS connect.ca_info;
DROP TABLE IF EXISTS connect.alerts;
DROP TABLE IF EXISTS connect.alert_types;
DROP TABLE IF EXISTS connect.style_configuration;
DROP TABLE IF EXISTS connect.alert_filter_defaults;
DROP TABLE IF EXISTS connect.plugin_version;
DROP TABLE IF EXISTS connect.connect_plugin_version;
DROP TABLE IF EXISTS connect.user_actions;
DROP TABLE IF EXISTS connect.users;
DROP TABLE IF EXISTS connect.user_roles;
DROP TABLE IF EXISTS connect.role;
DROP TABLE IF EXISTS connect.role_actions;
DROP TABLE IF EXISTS connect.upload_status;
DROP TABLE IF EXISTS connect.upload_item;
DROP TABLE IF EXISTS connect.work_item;
DROP TABLE IF EXISTS connect.map_layers;

DROP TABLE IF EXISTS connect.change_log;
DROP TABLE IF EXISTS connect.data_queue;

/* Create Tables */
CREATE TABLE connect.work_item
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	start_datetime timestamp not null,
	total_bytes bigint not null,
	local_filename varchar not null,
	type varchar(16) not null,
	status varchar(16) not null,
	locale varchar(56) not null,
	message varchar,
	PRIMARY KEY (uuid)
) WITHOUT OIDS;

ALTER TABLE connect.work_item ADD CONSTRAINT status_chk 
CHECK (status IN ('UPLOADING', 'PROCESSING', 'COMPLETE', 'ERROR'));

ALTER TABLE connect.work_item ADD CONSTRAINT type_chk 
CHECK (type IN ('UP_CA', 'UP_SYNC', 'DOWN_CA', 'DOWN_SYNC', 'UP_DATAQUEUE'));

	
CREATE TABLE connect.ca_plugin_version
(
	ca_uuid uuid NOT NULL,
	plugin_id varchar NOT NULL,
	version varchar NOT NULL,
	PRIMARY KEY (ca_uuid, plugin_id)
) WITHOUT OIDS;


CREATE TABLE connect.ca_info
(
	ca_uuid uuid NOT NULL,
	version uuid,
	label varchar not null,
	status varchar not null,
	lock_key serial not null,
	unique(lock_key),
	PRIMARY KEY (ca_uuid)
) WITHOUT OIDS;

ALTER TABLE connect.ca_info ADD CONSTRAINT status_chk 
CHECK (status IN ('UPLOADING', 'DATA', 'NODATA', 'CCAA'));

CREATE TABLE connect.connect_plugin_version
(
	plugin_id varchar NOT NULL,
	version varchar NOT NULL,
	PRIMARY KEY (plugin_id)
) WITHOUT OIDS;


CREATE TABLE connect.users
(
	uuid uuid NOT NULL,
	username varchar(32) NOT NULL,
	password char(60) NOT NULL,
	email varchar,
	resetid varchar,
	resetdatetime timestamp,
	UNIQUE(username),
	UNIQUE (uuid),
	UNIQUE(resetid),
	PRIMARY KEY (uuid, username)
) WITHOUT OIDS;


CREATE TABLE connect.user_actions
(
	username varchar NOT NULL,
	action varchar NOT NULL,
	resource uuid,
	uuid uuid NOT NULL,
	
	PRIMARY KEY (username, action, uuid)
) WITHOUT OIDS;

CREATE UNIQUE INDEX useractions_unq1 ON connect.user_actions(username, action) WHERE resource IS NULL;
CREATE UNIQUE INDEX useractions_unq2 ON connect.user_actions(username, action, resource) WHERE resource IS NOT NULL;


CREATE TABLE connect.user_roles
(
	username varchar NOT NULL,
	role_id varchar(32) NOT NULL,
	PRIMARY KEY (username, role_id)
) WITHOUT OIDS;

CREATE TABLE connect.roles
(
	role_id varchar(32) NOT NULL,
	rolename varchar NOT NULL,
	is_system boolean not null default false,
	PRIMARY KEY (role_id)
) WITHOUT OIDS;

CREATE TABLE connect.role_actions
(
	uuid uuid NOT NULL,	
	role_id varchar(32) NOT NULL,
	action varchar NOT NULL,
	resource uuid,
	PRIMARY KEY (uuid)
) WITHOUT OIDS;
CREATE UNIQUE INDEX roleactions_unq1 ON connect.role_actions(role_id, action) WHERE resource IS NULL;
CREATE UNIQUE INDEX roleactions_unq2 ON connect.role_actions(role_id, action, resource) WHERE resource IS NOT NULL;


CREATE TYPE connect.alert_status AS ENUM ('ACTIVE', 'DISABLED');

-- A list of all alerts in the system
CREATE TABLE connect.alerts
(
	-- A unqiue identifier for hibernate.
	uuid uuid NOT NULL,
	-- A unqiue identifier that the user generates.
	user_generated_id varchar NOT NULL,
	-- The date/time the alert was created.
	date timestamp with time zone NOT NULL, 
	-- Description associated with alert.
	description varchar,
	-- A link to the alert type.
	type_uuid uuid NOT NULL,
	-- A value of 1 (high) - 5(low).
	level smallint NOT NULL,
	-- Associated Conservation Area UUID
	ca_uuid uuid NOT NULL,
	--alert status, custom enum type defined above
	status connect.alert_status NOT NULL,
	-- the longitude of the alert location
	x double precision NOT NULL,
	-- the latitude of the alert location
	y double precision NOT NULL,
	-- The past points for this alert, as a line in json format:[[1, 1], [2, 2]]
	track varchar,
	-- A link to the user who created the alert.  The user will always be able to modify the alert.
	creator_uuid uuid NOT NULL,
	PRIMARY KEY (uuid)
) WITHOUT OIDS;

CREATE TABLE connect.alert_types(
	-- A unqiue identifier for hibernate.
	uuid uuid NOT NULL,
	-- Label for the type.
	label varchar(64),
	color varchar(16),
	fillColor varchar(16),
	opacity varchar(8),
	--http://fortawesome.github.io/Font-Awesome/icons/   shows valid values
	markerIcon varchar(16),
	--possible values for color are 'red', 'darkred', 'orange', 'green', 'darkgreen', 'blue', 'purple', 'darkpuple', 'cadetblue'
	markerColor varchar(16),
	spin boolean not null,
	PRIMARY KEY (uuid)
) WITHOUT OIDS;

insert into connect.alert_types values( '00000000-0000-0000-0000-000000000000' ,'Unknown Type','#000000','#000000','1', '', 'red', 'false');


CREATE TABLE connect.style_configuration(
	uuid uuid NOT NULL,
	style_id varchar(64) NOT NULL,
	active boolean NOT NULL,
	header_image bytea,
	header_style varchar(256),
	background_image bytea,
	body_style varchar(256),
	login_image bytea,
	server_name varchar(256),
	footer_text text,
	PRIMARY KEY(style_id)
) WITHOUT OIDS;

CREATE TABLE connect.map_layers(
	uuid uuid NOT NULL,
	-- layer type  1-mapbox.com layer, 2-giscloud.com (WMS-published), 3 - generic WMS
	layer_type int NOT NULL,
	active boolean NOT NULL,
	token varchar(256),
	mapboxid varchar(64),
	wms_layer_list text,
	layer_name varchar(32),
	layer_order int NOT NULL
) WITHOUT OIDS;

CREATE TABLE connect.alert_filter_defaults(
	uuid uuid NOT NULL,
	default_past_hours int,
	default_type_uuids varchar(925), --max 25 types to default to on, comma separated.
	default_active boolean,
	default_disabled boolean,
	default_level1 boolean,
	default_level2 boolean,
	default_level3 boolean,
	default_level4 boolean,
	default_level5 boolean,
	default_ca_uuids varchar(925),--max 25 uuids, comma separated.
	default_text varchar(128),
	seconds_refresh int,
	starting_zoom_level int,
	starting_long real,
	starting_lat real
)WITHOUT OIDS;


create table connect.connect_version 
(version varchar(16), 
last_updated timestamp default (now())
)WITHOUT OIDS;

--insert into connect.alert_filter_defaults values( 'a1bcbc77-9c0b-4ef8-bb6d-6bb9bd380a53' , 24, '',true, true, true, true, true, true, true,'','', 30, 8 , -7.5, 34);



/* Create Foreign Keys */
ALTER TABLE connect.work_item
	ADD FOREIGN KEY (ca_uuid)
	REFERENCES connect.ca_info (ca_uuid)
	ON UPDATE RESTRICT
	ON DELETE CASCADE;

ALTER TABLE connect.ca_plugin_version
	ADD FOREIGN KEY (ca_uuid)
	REFERENCES connect.ca_info (ca_uuid)
	ON UPDATE RESTRICT
	ON DELETE CASCADE;


ALTER TABLE connect.user_actions
	ADD FOREIGN KEY (username)
	REFERENCES connect.users (username)
	ON UPDATE CASCADE
	ON DELETE CASCADE;

ALTER TABLE connect.user_roles
	ADD FOREIGN KEY (username)
	REFERENCES connect.users (username)
	ON UPDATE CASCADE
	ON DELETE CASCADE;

ALTER TABLE connect.user_roles
	ADD FOREIGN KEY (role_id)
	REFERENCES connect.roles (role_id)
	ON UPDATE CASCADE
	ON DELETE CASCADE;
	
ALTER TABLE connect.role_actions
	ADD FOREIGN KEY (role_id)
	REFERENCES connect.roles (role_id)
	ON UPDATE CASCADE
	ON DELETE CASCADE;
	
	
ALTER TABLE connect.alerts
	ADD FOREIGN KEY (ca_uuid)
	REFERENCES connect.ca_info (ca_uuid)
	ON UPDATE RESTRICT
	ON DELETE CASCADE
;

ALTER TABLE connect.alerts
	ADD FOREIGN KEY (creator_uuid)
	REFERENCES connect.users (uuid)
	ON UPDATE RESTRICT
;

ALTER TABLE connect.alerts
	ADD FOREIGN KEY (type_uuid)
	REFERENCES connect.alert_types (uuid)
	ON UPDATE RESTRICT
;

INSERT INTO connect.roles (role_id, rolename, is_system) values ('smart', 'SYSTEM ROLE', true);

	
CREATE OR REPLACE FUNCTION manage_user_roles() RETURNS TRIGGER AS $$
    BEGIN
        --
        -- should only be called on insert; adds necessary smart role
        -- for web access
        --
        IF (TG_OP = 'INSERT') THEN
            INSERT INTO connect.user_roles (username, role_id) VALUES (NEW.username, 'smart');
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$$ LANGUAGE plpgsql;


--AFTER INSERT OR UPDATE OR DELETE ON connect.users
CREATE TRIGGER web_roles_mgr
AFTER INSERT ON connect.users
    FOR EACH ROW EXECUTE PROCEDURE manage_user_roles();


/* Comments */
COMMENT ON TABLE connect.work_item IS 'A table for tracking uploads and supporting upload apis.';
COMMENT ON COLUMN connect.work_item.uuid IS 'A unique system generated identifier.';
COMMENT ON COLUMN connect.work_item.ca_uuid IS 'The unique Conservation Area identifier.';
COMMENT ON COLUMN connect.work_item.start_datetime IS 'The start time of the upload.';
COMMENT ON COLUMN connect.work_item.total_bytes IS 'Total number of bytes to upload.';
COMMENT ON COLUMN connect.work_item.local_filename IS 'Name of the file in the local filestore.';
COMMENT ON COLUMN connect.work_item.type IS 'File type.';
COMMENT ON COLUMN connect.work_item.status IS 'Status of upload and processing';
COMMENT ON COLUMN connect.work_item.message IS 'Error message or other info message asociated with upload.';
COMMENT ON TABLE connect.ca_info IS 'Contains server details for Conservation Areas.';
COMMENT ON COLUMN connect.ca_info.ca_uuid IS 'The unique Conservation Area identifier.';
COMMENT ON COLUMN connect.ca_info.version IS 'The version of the data for the conservation area.';
COMMENT ON TABLE connect.ca_plugin_version IS 'A list of SMART plugins and their database schema version for each Conservation Area.';
COMMENT ON COLUMN connect.ca_plugin_version.ca_uuid IS 'The unique Conservation Area identifier.';
COMMENT ON COLUMN connect.ca_plugin_version.plugin_id IS 'The unique plugin identifier.';
COMMENT ON COLUMN connect.ca_plugin_version.version IS 'The plugin database schema version.';
COMMENT ON TABLE connect.connect_plugin_version IS 'The list of plugin supported by the SMART Connect Server and their associated versions.  The version field should be the database schema version not the code version.';
COMMENT ON COLUMN connect.connect_plugin_version.plugin_id IS 'The unique plugin identifier.';
COMMENT ON COLUMN connect.connect_plugin_version.version IS 'The plugin database schema version.';
COMMENT ON TABLE connect.users IS 'A list of smart connect users.';
COMMENT ON COLUMN connect.users.uuid IS 'A unqiue identifier for hibernate.';
COMMENT ON COLUMN connect.users.username IS 'The unique username';
COMMENT ON COLUMN connect.users.password IS 'The bcrypt has encoded password for the user.';
COMMENT ON COLUMN connect.users.email IS 'The user email address';
COMMENT ON COLUMN connect.users.resetid IS 'A unique key sent to the users for resetting their password.';
COMMENT ON COLUMN connect.users.resetdatetime IS 'The date/time the last reset link was sent to the user.';
COMMENT ON TABLE connect.user_actions IS 'A table for listing user permissions and associated resources.';
COMMENT ON COLUMN connect.user_actions.username IS 'The unique user identifier.';
COMMENT ON COLUMN connect.user_actions.action IS 'The action the user has permission to perform.';
COMMENT ON COLUMN connect.user_actions.resource IS 'Unique identifier to the resource (null implies all resources)';
COMMENT ON COLUMN connect.user_actions.uuid IS 'A unqiue identifier for hibernate.';
COMMENT ON TABLE connect.user_roles IS 'A list of webserver roles supported by each user.';
COMMENT ON COLUMN connect.user_roles.username IS 'The unique username.';
COMMENT ON COLUMN connect.user_roles.role_id IS 'The webserver role.';

CREATE TABLE connect.change_log(
	uuid UUID,
	revision BIGSERIAL,
	action varchar(15) CONSTRAINT action_check CHECK (action in ('INSERT', 'UPDATE', 'DELETE', 'FS_INSERT', 'FS_DELETE', 'FS_UPDATE')),
	filename varchar(32672),
	tablename varchar(256),
	ca_uuid UUID,
	key1_fieldname varchar(256),
	key1 UUID,
	key2_fieldname varchar(256),
	key2_str varchar(256),
	key2_uuid UUID,
	datetime timestamp default now(),
	primary key (revision)
);
ALTER TABLE connect.change_log ADD CONSTRAINT connect_changelog_ca_uuid_fk foreign key (ca_uuid) REFERENCES connect.ca_info(ca_uuid) ON UPDATE restrict ON DELETE cascade;
CREATE INDEX connect_change_log_uuid_idx on connect.change_log (uuid);
CREATE INDEX connect_change_log_ca_uuid_idx on connect.change_log (ca_uuid);

COMMENT ON TABLE connect.change_log IS 'Change log items.';
COMMENT ON COLUMN connect.change_log.uuid IS 'A unique identifier for each change log item.';
COMMENT ON COLUMN connect.change_log.revision IS 'The server defined revision number.';
COMMENT ON COLUMN connect.change_log.action IS 'Change log action.';
COMMENT ON COLUMN connect.change_log.filename IS 'The filename, if a datastore action.';
COMMENT ON COLUMN connect.change_log.tablename IS 'The tablename if a database action.';
COMMENT ON COLUMN connect.change_log.ca_uuid IS 'The conservation area uuid.';
COMMENT ON COLUMN connect.change_log.key1_fieldname IS 'The first unique key field name (required if database action).';
COMMENT ON COLUMN connect.change_log.key1 IS 'The first unique key uuid value (required if database action).';
COMMENT ON COLUMN connect.change_log.key2_fieldname IS 'The second unique key field name (optional, only required for composite primary keys).';
COMMENT ON COLUMN connect.change_log.key2_str IS 'The second unique key uuid value (optional).';
COMMENT ON COLUMN connect.change_log.key2_uuid IS 'The second unique key string value (optional)';
COMMENT ON COLUMN connect.change_log.datetime IS 'The server managed datetime the action is added to the table.';


CREATE TABLE connect.change_log_history(
	ca_uuid UUID,
	last_delete_revision BIGINT,
	primary key (ca_uuid)
);
ALTER TABLE connect.change_log_history ADD CONSTRAINT connect_changelog_history_ca_uuid_fk foreign key (ca_uuid) REFERENCES connect.ca_info(ca_uuid) ON UPDATE restrict ON DELETE cascade;
COMMENT ON TABLE connect.change_log_history IS 'Tracks history infor about the change log table, in particular the last removed records for each conservation area';
COMMENT ON COLUMN connect.change_log_history.ca_uuid IS 'The conservation area unique identifier.';
COMMENT ON COLUMN connect.change_log_history.last_delete_revision IS 'The last deleted revision number.';

-- DATA PROCESSING QUEUE TABLES
CREATE TABLE connect.data_queue(
	uuid UUID,
	type VARCHAR(32) NOT NULL,
	ca_uuid UUID NOT NULL,
	name VARCHAR,
	uploaded_date timestamp not null,
	lastmodified_date timestamp,
	uploaded_by varchar not null,
	file varchar,
	status varchar(32) NOT NULL,
	status_message varchar,
	work_item_uuid UUID,
	PRIMARY KEY (uuid)
);
ALTER TABLE connect.data_queue ADD CONSTRAINT 
data_queue_ca_uuid_fk foreign key (ca_uuid) 
REFERENCES connect.ca_info(ca_uuid) ON UPDATE restrict ON DELETE cascade;

ALTER TABLE connect.data_queue ADD CONSTRAINT status_chk 
CHECK (status IN ('UPLOADING', 'QUEUED', 'PROCESSING', 'COMPLETE', 'ERROR'));

ALTER TABLE connect.data_queue ADD CONSTRAINT type_chk 
CHECK (type IN ('PATROL_XML', 'INCIDENT_XML', 'MISSION_XML', 'INTELL_XML'));

CREATE OR REPLACE FUNCTION connect.dq_update_modified_column()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.lastmodified_date = now();
    RETURN NEW;	
END;
$$ language 'plpgsql';
CREATE TRIGGER dq_last_modified_trigger BEFORE UPDATE ON connect.data_queue FOR EACH ROW EXECUTE PROCEDURE connect.dq_update_modified_column();


drop schema If exists smart cascade;
create schema smart; 

CREATE OR REPLACE FUNCTION smart.trimhkeytolevel(level integer, str varchar) RETURNS VARCHAR AS $$
BEGIN
	RETURN (regexp_matches(str, '(?:[a-zA-Z_0-9]*\.){' || level+1 || '}'))[1];
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.pointinpolygon(x double precision ,y double precision, geom bytea) RETURNS BOOLEAN AS $$
BEGIN
	RETURN ST_INTERSECTS(ST_MAKEPOINT(x, y), st_geomfromwkb(geom));

END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.intersects(geom1 bytea, geom2 bytea) RETURNS BOOLEAN AS $$
BEGIN
	RETURN ST_INTERSECTS(st_geomfromwkb(geom1), st_geomfromwkb(geom2));

END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.distanceInMeter(geom bytea) RETURNS DOUBLE PRECISION AS $$
BEGIN
	RETURN ST_Length_Spheroid(st_force2d(st_geomfromwkb(geom)), 'SPHEROID["WGS 84",6378137,298.257223563]');

END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.intersection(geom1 bytea, geom2 bytea) RETURNS bytea AS $$
BEGIN
	RETURN st_asewkb(ST_INTERSECTION(st_geomfromwkb(geom1), st_geomfromwkb(geom2)), 'XDR');

END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.computeTileId(x double precision, y double precision, srid integer, originX double precision, originY double precision, gridSize double precision) RETURNS VARCHAR AS $$
DECLARE 
  pnt geometry;
  tx integer;
  ty integer;
BEGIN
	pnt := st_transform(st_setsrid(st_makepoint(x,y), 4326), srid);
	tx := floor ( (st_x(pnt) - originX ) / gridSize) + 1;
	ty := floor ( (st_y(pnt) - originY ) / gridSize) + 1;
	RETURN tx || '_' || ty;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.computeHoursPoly(polygon bytea, linestring bytea) RETURNS double precision AS $$
DECLARE
  ls geometry;
  p geometry;
  value double precision;
  ctime double precision;
  clength double precision;
  i integer;
  pnttemp geometry;
  pnttemp2 geometry;
  lstemp geometry;
BEGIN
	ls := st_geomfromwkb(linestring);
	p := st_geomfromwkb(polygon);
	
	--wholly contained use entire time
	IF (st_contains(p, ls)) THEN
		return (st_z(st_endpoint(ls)) - st_z(st_startpoint(ls))) / 3600000.0;
	END IF;
	
	value := 0;
	FOR i in 1..ST_NumPoints(ls)-1 LOOP
		pnttemp := st_pointn(ls, i);
		pnttemp2 := st_pointn(ls, i+1);
		lstemp := st_makeline(pnttemp, pnttemp2);	
		IF (NOT st_intersects(st_envelope(ls), st_envelope(lstemp))) THEN
			--do nothing; outside envelope
		ELSE
			IF (ST_COVERS(p, lstemp)) THEN
				value := value + st_z(pnttemp2) - st_z(pnttemp);
			ELSIF (ST_INTERSECTS(p, lstemp)) THEN
				ctime := st_z(pnttemp2) - st_z(pnttemp);
				clength := st_distance(pnttemp, pnttemp2);
				IF (clength = 0) THEN
					--points are the same and intersect so include the entire time
					value := value + ctime;
				ELSE
					--part in part out so linearly interpolate
					value := value + (ctime * (st_length(st_intersection(p, lstemp)) / clength));
				END IF;
			END IF;
		END IF;
	END LOOP;
	RETURN value / 3600000.0;
END;
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION smart.computeHours(geometry bytea, linestring bytea) RETURNS double precision AS $$
DECLARE
  type varchar;
  value double precision;
  i integer;
  p geometry;
BEGIN
	p := st_geomfromwkb(geometry);
	type := st_geometrytype(p);
	IF (upper(type) = 'ST_POLYGON') THEN
		RETURN smart.computeHoursPoly(geometry, linestring);
	ELSIF (upper(type) = 'ST_MULTIPOLYGON') THEN
		value := 0;
		FOR i in 1..ST_NumGeometries(p) LOOP
			value := value + computeHoursPoly( st_asewkb(ST_GeometryN(p, i), 'XDR'), linestring);
		END LOOP;
		RETURN value;
	ELSIF (upper(type) = 'ST_GEOMETRYCOLLECTION') THEN
		value := 0;
		FOR i in 1..ST_NumGeometries(p) LOOP
			value := value + computeHours(ST_GeometryN(p, i), linestring);
		END LOOP;
		RETURN value;
	END IF;
	RETURN 0;

END;
$$LANGUAGE plpgsql;

CREATE TABLE smart.agency
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.area_geometries
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   AREA_TYPE varchar(5) NOT NULL,
   KEYID varchar(256),
   GEOM bytea NOT NULL,
   PRIMARY KEY (UUID) 
);


CREATE TABLE smart.ca_projection
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   NAME varchar(1024) NOT NULL,
   DEFINITION varchar NOT NULL,
   IS_DEFAULT boolean,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.cm_attribute
(
   UUID uuid NOT NULL,
   NODE_UUID uuid NOT NULL,
   ATTRIBUTE_UUID uuid NOT NULL,
   ATTRIBUTE_ORDER smallint,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.cm_attribute_list
(
   UUID uuid NOT NULL,
   CM_UUID uuid NOT NULL,
   LIST_ELEMENT_UUID uuid NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   CM_ATTRIBUTE_UUID uuid,
   DM_ATTRIBUTE_UUID uuid,
   LIST_ORDER smallint,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.cm_attribute_option
(
   UUID uuid NOT NULL,
   CM_ATTRIBUTE_UUID uuid NOT NULL,
   OPTION_ID varchar(128) NOT NULL,
   NUMBER_VALUE float(52),
   STRING_VALUE varchar(1024),
   UUID_VALUE uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.cm_attribute_tree_node
(
   UUID uuid NOT NULL,
   CM_UUID uuid NOT NULL,
   DM_TREE_NODE_UUID uuid,
   IS_ACTIVE boolean NOT NULL,
   CM_ATTRIBUTE_UUID uuid,
   DM_ATTRIBUTE_UUID uuid,
   PARENT_UUID uuid,
   NODE_ORDER smallint,
   DISPLAY_MODE VARCHAR(10),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.cm_node
(
   UUID uuid NOT NULL,
   CM_UUID uuid NOT NULL,
   CATEGORY_UUID uuid,
   PARENT_NODE_UUID uuid,
   NODE_ORDER smallint,
   PHOTO_ALLOWED boolean,
   PHOTO_REQUIRED boolean,
   COLLECT_MULTIPLE_OBS boolean,
   USE_SINGLE_GPS_POINT boolean,
   DISPLAY_MODE VARCHAR(10),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.connect_alert
(
	UUID UUID NOT NULL,
	CM_UUID UUID NOT NULL,
	ALERT_ITEM_UUID UUID NOT NULL,
	CM_ATTRIBUTE_UUID UUID,
	LEVEL SMALLINT NOT NULL,
	TYPE VARCHAR(64),
	PRIMARY KEY (UUID)
);

CREATE TABLE smart.configurable_model
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   DISPLAY_MODE VARCHAR(10),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.connect_ct_properties 
( 
	UUID uuid NOT NULL, 
	CM_UUID uuid NOT NULL, 
	PING_FREQUENCY INTEGER, 
	PRIMARY KEY (UUID)
);

CREATE TABLE SMART.CM_DM_ATTRIBUTE_SETTINGS 
(
	CM_UUID UUID NOT NULL, 
	DM_ATTRIBUTE_UUID UUID NOT NULL, 
	DISPLAY_MODE VARCHAR(10), 
	PRIMARY KEY (CM_UUID, DM_ATTRIBUTE_UUID)
);

CREATE TABLE smart.conservation_area
(
   UUID uuid NOT NULL,
   ID varchar(8) NOT NULL,
   NAME varchar(256),
   DESIGNATION varchar(1024),
   DESCRIPTION varchar(2056),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.ct_properties_option
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   OPTION_ID varchar(32) NOT NULL,
   DOUBLE_VALUE float(52),
   INTEGER_VALUE int,
   STRING_VALUE varchar(1024),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.ct_properties_profile (
  uuid UUID NOT NULL, 
  ca_uuid UUID NOT NULL, 
  IS_DEFAULT BOOLEAN, 
  PRIMARY KEY (UUID)
);

CREATE TABLE smart.ct_properties_profile_option (
  uuid UUID NOT NULL, 
  profile_uuid UUID NOT NULL, 
  OPTION_ID VARCHAR(32) NOT NULL, 
  DOUBLE_VALUE DOUBLE PRECISION, 
  INTEGER_VALUE INTEGER, 
  STRING_VALUE VARCHAR(1024), 
  PRIMARY KEY (UUID));

CREATE TABLE smart.cm_ct_properties_profile (
	cm_uuid UUID NOT NULL, 
	profile_uuid UUID NOT NULL, PRIMARY KEY (cm_uuid));


CREATE TABLE smart.db_version
(
   VERSION varchar(15) NOT NULL,
   PLUGIN_ID varchar(512) NOT NULL
);

CREATE TABLE smart.dm_aggregation
(
   NAME varchar(16) NOT NULL,
   PRIMARY KEY (NAME)
);

CREATE TABLE smart.dm_aggregation_i18n
(
   NAME varchar(16) NOT NULL,
   LANG_CODE varchar(5) NOT NULL,
   GUI_NAME varchar(96) NOT NULL,
   PRIMARY KEY (NAME,LANG_CODE)
);

CREATE TABLE smart.dm_att_agg_map
(
   ATTRIBUTE_UUID uuid NOT NULL,
   AGG_NAME varchar(16) NOT NULL,
   PRIMARY KEY (ATTRIBUTE_UUID,AGG_NAME)
);

CREATE TABLE smart.dm_attribute
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   IS_REQUIRED boolean NOT NULL,
   ATT_TYPE varchar(7) NOT NULL,
   MIN_VALUE float(52),
   MAX_VALUE float(52),
   REGEX varchar(1024),
   PRIMARY KEY (uuid) 
);

CREATE TABLE smart.dm_attribute_list
(
   UUID uuid NOT NULL,
   ATTRIBUTE_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   LIST_ORDER smallint NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.dm_attribute_tree
(
   UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   NODE_ORDER smallint NOT NULL,
   PARENT_UUID uuid,
   ATTRIBUTE_UUID uuid,
   IS_ACTIVE boolean NOT NULL,
   HKEY varchar NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.dm_cat_att_map
(
   CATEGORY_UUID uuid NOT NULL,
   ATTRIBUTE_UUID uuid NOT NULL,
   ATT_ORDER smallint NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   PRIMARY KEY (CATEGORY_UUID,ATTRIBUTE_UUID)
);

CREATE TABLE smart.dm_category
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   PARENT_CATEGORY_UUID uuid,
   IS_MULTIPLE boolean,
   CAT_ORDER smallint,
   IS_ACTIVE boolean NOT NULL,
   HKEY varchar NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.employee
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(32) NOT NULL,
   GIVENNAME varchar(64) NOT NULL,
   FAMILYNAME varchar(64) NOT NULL,
   STARTEMPLOYMENTDATE date NOT NULL,
   ENDEMPLOYMENTDATE date,
   DATECREATED date NOT NULL,
   BIRTHDATE date,
   GENDER char(1) NOT NULL,
   SMARTUSERID varchar(16),
   SMARTPASSWORD varchar(256),
   SMARTUSERLEVEL smallint,
   AGENCY_UUID uuid,
   RANK_UUID uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity
(
   UUID uuid NOT NULL,
   ENTITY_TYPE_UUID uuid NOT NULL,
   ID varchar(32) NOT NULL,
   STATUS varchar(8) NOT NULL,
   ATTRIBUTE_LIST_ITEM_UUID uuid NOT NULL,
   X float(52),
   Y float(52),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_attribute
(
   UUID uuid NOT NULL,
   ENTITY_TYPE_UUID uuid NOT NULL,
   DM_ATTRIBUTE_UUID uuid NOT NULL,
   IS_REQUIRED boolean DEFAULT false NOT NULL,
   IS_PRIMARY boolean DEFAULT true NOT NULL,
   ATTRIBUTE_ORDER int DEFAULT 1 NOT NULL,
   KEYID varchar(128) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_attribute_value
(
   ENTITY_ATTRIBUTE_UUID uuid NOT NULL,
   ENTITY_UUID uuid NOT NULL,
   NUMBER_VALUE float(52),
   STRING_VALUE varchar(1024),
   LIST_ELEMENT_UUID uuid,
   TREE_NODE_UUID uuid,
   PRIMARY KEY (ENTITY_ATTRIBUTE_UUID,ENTITY_UUID)
);

CREATE TABLE smart.entity_gridded_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   QUERY_DEF varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   CRS_DEFINITION varchar NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_observation_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_summary_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   CA_FILTER varchar,
   QUERY_DEF varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_type
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   DATE_CREATED timestamp NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   STATUS varchar(16) NOT NULL,
   DM_ATTRIBUTE_UUID uuid NOT NULL,
   ENTITY_TYPE varchar(16),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.entity_waypoint_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.gridded_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   QUERY_DEF varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   CRS_DEFINITION varchar NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.i18n_label
(
   LANGUAGE_UUID uuid NOT NULL,
   ELEMENT_UUID uuid NOT NULL,
   VALUE varchar(1024) NOT NULL,
   PRIMARY KEY (LANGUAGE_UUID,ELEMENT_UUID)
);

CREATE TABLE smart.informant
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(128),
   IS_ACTIVE boolean NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intel_record_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intel_summary_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intelligence
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   RECEIVED_DATE date NOT NULL,
   PATROL_UUID uuid,
   FROM_DATE date NOT NULL,
   TO_DATE date,
   DESCRIPTION varchar,
   CREATOR_UUID uuid,
   SOURCE_UUID uuid,
   INFORMANT_UUID uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intelligence_attachment
(
   UUID uuid NOT NULL,
   INTELLIGENCE_UUID uuid NOT NULL,
   FILENAME varchar(1024) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intelligence_point
(
   UUID uuid NOT NULL,
   INTELLIGENCE_UUID uuid NOT NULL,
   X float NOT NULL,
   Y float NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.intelligence_source
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128),
   IS_ACTIVE boolean NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.language
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   ISDEFAULT boolean DEFAULT false NOT NULL,
   CODE varchar(5),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.map_styles
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   STYLE_STRING varchar NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.mission
(
   UUID uuid NOT NULL,
   SURVEY_UUID uuid NOT NULL,
   ID varchar(128) NOT NULL,
   START_DATETIME timestamp NOT NULL,
   END_DATETIME timestamp NOT NULL,
   COMMENT varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.mission_attribute
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   ATT_TYPE varchar(7) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.mission_attribute_list
(
   UUID uuid  NOT NULL,
   MISSION_ATTRIBUTE_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   LIST_ORDER smallint NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.mission_day
(
   UUID uuid NOT NULL,
   MISSION_UUID uuid NOT NULL,
   MISSION_DAY date NOT NULL,
   START_TIME time NOT NULL,
   END_TIME time NOT NULL,
   REST_MINUTES int,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.mission_member
(
   MISSION_UUID uuid NOT NULL,
   EMPLOYEE_UUID uuid NOT NULL,
   IS_LEADER boolean NOT NULL,
   PRIMARY KEY (MISSION_UUID,EMPLOYEE_UUID)
);

CREATE TABLE smart.mission_property
(
   SURVEY_DESIGN_UUID uuid NOT NULL,
   MISSION_ATTRIBUTE_UUID uuid NOT NULL,
   ATTRIBUTE_ORDER int NOT NULL,
   PRIMARY KEY (SURVEY_DESIGN_UUID,MISSION_ATTRIBUTE_UUID)
);

CREATE TABLE smart.mission_property_value
(
   MISSION_UUID uuid NOT NULL,
   MISSION_ATTRIBUTE_UUID uuid NOT NULL,
   NUMBER_VALUE float(52),
   STRING_VALUE varchar(1024),
   LIST_ELEMENT_UUID uuid,
   PRIMARY KEY (MISSION_UUID,MISSION_ATTRIBUTE_UUID)
);

CREATE TABLE smart.mission_track
(
   UUID uuid NOT NULL,
   MISSION_DAY_UUID uuid NOT NULL,
   SAMPLING_UNIT_UUID uuid,
   TRACK_TYPE varchar(32) NOT NULL,
   GEOMETRY bytea NOT NULL,
   ID varchar(128),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.obs_gridded_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   QUERY_DEF varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   CRS_DEFINITION varchar NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.obs_observation_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.obs_summary_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   CA_FILTER varchar,
   QUERY_DEF varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.obs_waypoint_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.observation_attachment
(
   UUID uuid NOT NULL,
   OBS_UUID uuid NOT NULL,
   FILENAME varchar(1024) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.observation_options
(
   CA_UUID uuid NOT NULL,
   DISTANCE_DIRECTION boolean NOT NULL,
   EDIT_TIME smallint,
   VIEW_PROJECTION_UUID uuid,
   OBSERVER boolean DEFAULT false NOT NULL,
   PRIMARY KEY (CA_UUID)
);

CREATE TABLE smart.observation_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(32) NOT NULL,
   STATION_UUID uuid,
   TEAM_UUID uuid,
   OBJECTIVE varchar,
   MANDATE_UUID uuid,
   PATROL_TYPE varchar(6) NOT NULL,
   IS_ARMED boolean NOT NULL,
   START_DATE date NOT NULL,
   END_DATE date NOT NULL,
   COMMENT varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol_intelligence
(
   PATROL_UUID uuid NOT NULL,
   INTELLIGENCE_UUID uuid NOT NULL,
   PRIMARY KEY (PATROL_UUID,INTELLIGENCE_UUID)
)
;
CREATE TABLE smart.patrol_leg
(
   UUID uuid NOT NULL,
   PATROL_UUID uuid NOT NULL,
   START_DATE date NOT NULL,
   END_DATE date NOT NULL,
   TRANSPORT_UUID uuid NOT NULL,
   ID varchar(50) NOT NULL,
   PRIMARY KEY (UUID)
   
);

CREATE TABLE smart.patrol_leg_day
(
   UUID uuid NOT NULL,
   PATROL_LEG_UUID uuid NOT NULL,
   PATROL_DAY date NOT NULL,
   START_TIME time,
   REST_MINUTES int,
   END_TIME time,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol_leg_members
(
   PATROL_LEG_UUID uuid NOT NULL,
   EMPLOYEE_UUID uuid NOT NULL,
   IS_LEADER boolean  NOT NULL,
   IS_PILOT boolean NOT NULL,
   PRIMARY KEY (PATROL_LEG_UUID,EMPLOYEE_UUID)
);

CREATE TABLE smart.patrol_mandate
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   KEYID varchar(128),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol_plan
(
   PATROL_UUID uuid NOT NULL,
   PLAN_UUID uuid NOT NULL,
   PRIMARY KEY (PATROL_UUID,PLAN_UUID)
);

CREATE TABLE smart.patrol_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol_transport
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   PATROL_TYPE varchar(6) NOT NULL,
   KEYID varchar(128),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.patrol_type
(
   CA_UUID uuid NOT NULL,
   PATROL_TYPE varchar(6) NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   max_speed INTEGER,
   PRIMARY KEY (CA_UUID,PATROL_TYPE)
);

CREATE TABLE smart.patrol_waypoint
(
   WP_UUID uuid NOT NULL,
   LEG_DAY_UUID uuid NOT NULL,
   PRIMARY KEY (WP_UUID,LEG_DAY_UUID)
);

CREATE TABLE smart.plan
(
   UUID uuid NOT NULL,
   ID varchar(32) NOT NULL,
   START_DATE date NOT NULL,
   END_DATE date,
   TYPE varchar(32) NOT NULL,
   DESCRIPTION varchar(256),
   CA_UUID uuid NOT NULL,
   STATION_UUID uuid,
   TEAM_UUID uuid,
   ACTIVE_EMPLOYEES int,
   UNAVAILABLE_EMPLOYEES int,
   PARENT_UUID uuid,
   CREATOR_UUID uuid,
   COMMENT varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.plan_target
(
   UUID uuid NOT NULL,
   NAME varchar(32) NOT NULL,
   DESCRIPTION varchar(256),
   VALUE float,
   OP varchar(10),
   TYPE varchar(32),
   PLAN_UUID uuid NOT NULL,
   CATEGORY varchar(16) NOT NULL,
   COMPLETED boolean DEFAULT false NOT NULL,
   SUCCESS_DISTANCE int,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.plan_target_point
(
   UUID uuid NOT NULL,
   PLAN_TARGET_UUID uuid NOT NULL,
   X float NOT NULL,
   Y float NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.query_folder
(
   UUID uuid NOT NULL,
   EMPLOYEE_UUID uuid,
   CA_UUID uuid NOT NULL,
   PARENT_UUID uuid,
   PRIMARY KEY (UUID)
   
);

CREATE TABLE smart.rank
(
   UUID uuid NOT NULL,
   AGENCY_UUID uuid NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.report
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   FILENAME varchar(2048) NOT NULL,
   CA_UUID uuid NOT NULL,
   SHARED boolean NOT NULL,
   FOLDER_UUID uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.report_folder
(
   UUID uuid NOT NULL,
   EMPLOYEE_UUID uuid,
   CA_UUID uuid NOT NULL,
   PARENT_UUID uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.report_query
(
   REPORT_UUID uuid NOT NULL,
   QUERY_UUID uuid NOT NULL,
   PRIMARY KEY (REPORT_UUID,QUERY_UUID)
);

CREATE TABLE smart.sampling_unit
(
   UUID uuid NOT NULL,
   SURVEY_DESIGN_UUID uuid NOT NULL,
   UNIT_TYPE varchar(32) NOT NULL,
   ID varchar(128),
   STATE varchar(8) NOT NULL,
   GEOMETRY bytea NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.sampling_unit_attribute
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128),
   ATT_TYPE varchar(7),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.sampling_unit_attribute_list
(
   UUID uuid NOT NULL,
   SAMPLING_UNIT_ATTRIBUTE_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   LIST_ORDER smallint NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.sampling_unit_attribute_value
(
   SU_ATTRIBUTE_UUID uuid NOT NULL,
   SU_UUID uuid NOT NULL,
   STRING_VALUE varchar(1024),
   NUMBER_VALUE float(52),
   LIST_ELEMENT_UUID uuid,
   PRIMARY KEY (SU_ATTRIBUTE_UUID,SU_UUID)
);

CREATE TABLE smart.saved_maps
(
   UUID uuid NOT NULL,
   CA_UUID uuid,
   IS_DEFAULT boolean NOT NULL,
   MAP_DEF text NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.screen_option
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   TYPE varchar(10),
   IS_VISIBLE boolean,
   STRING_VALUE varchar,
   BOOLEAN_VALUE boolean,
   UUID_VALUE uuid,
   RESOURCE varchar(10),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.screen_option_uuid
(
   UUID uuid NOT NULL,
   OPTION_UUID uuid NOT NULL,
   UUID_VALUE uuid NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.station
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   DESC_UUID uuid,
   IS_ACTIVE boolean NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.summary_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   CA_FILTER varchar,
   QUERY_DEF  varchar,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   CA_UUID uuid NOT NULL,
   ID varchar(6) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey
(
   UUID uuid NOT NULL,
   SURVEY_DESIGN_UUID uuid NOT NULL,
   ID varchar(128) NOT NULL,
   START_DATE date,
   END_DATE date,
   PRIMARY KEY (UUID)
)
;
CREATE TABLE smart.survey_design
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   KEYID varchar(128) NOT NULL,
   STATE varchar(16) NOT NULL,
   START_DATE date,
   END_DATE date,
   DISTANCE_DIRECTION boolean DEFAULT FALSE NOT NULL,
   DESCRIPTION varchar,
   CONFIGURABLE_MODEL_UUID uuid,
   OBSERVER boolean DEFAULT false NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_design_property
(
   UUID uuid NOT NULL,
   SURVEY_DESIGN_UUID uuid NOT NULL,
   NAME varchar(256) NOT NULL,
   VALUE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_design_sampling_unit
(
   SURVEY_DESIGN_UUID uuid NOT NULL,
   SU_ATTRIBUTE_UUID uuid NOT NULL,
   PRIMARY KEY (SURVEY_DESIGN_UUID,SU_ATTRIBUTE_UUID)
);

CREATE TABLE smart.survey_gridded_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   QUERY_DEF varchar,
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   CRS_DEFINITION varchar,
   SURVEYDESIGN_KEY varchar(128),
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_mission_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SURVEYDESIGN_KEY varchar(128),
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_mission_track_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SURVEYDESIGN_KEY varchar(128),
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_observation_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SURVEYDESIGN_KEY varchar(128),
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_summary_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_DEF varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   SURVEYDESIGN_KEY varchar(128),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.survey_waypoint
(
   WP_UUID uuid NOT NULL,
   MISSION_DAY_UUID uuid NOT NULL,
   SAMPLING_UNIT_UUID uuid,
   MISSION_TRACK_UUID uuid,
   PRIMARY KEY (WP_UUID)
);

CREATE TABLE smart.survey_waypoint_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SURVEYDESIGN_KEY varchar(128),
   SHARED boolean NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.team
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   IS_ACTIVE boolean NOT NULL,
   DESC_UUID uuid,
   PATROL_MANDATE_UUID uuid,
   KEYID varchar(128),
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.track
(
   UUID uuid NOT NULL,
   PATROL_LEG_DAY_UUID uuid NOT NULL,
   GEOMETRY bytea NOT NULL,
   DISTANCE real NOT NULL,
   PRIMARY KEY (UUID,PATROL_LEG_DAY_UUID)
);

CREATE TABLE smart.waypoint
(
   UUID uuid NOT NULL,
   CA_UUID uuid NOT NULL,
   SOURCE varchar(16) NOT NULL,
   ID int NOT NULL,
   X float NOT NULL,
   Y float NOT NULL,
   DATETIME timestamp NOT NULL,
   DIRECTION real,
   DISTANCE real,
   WP_COMMENT varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.waypoint_query
(
   UUID uuid NOT NULL,
   CREATOR_UUID uuid NOT NULL,
   QUERY_FILTER varchar,
   CA_FILTER varchar,
   CA_UUID uuid NOT NULL,
   FOLDER_UUID uuid,
   COLUMN_FILTER varchar,
   SHARED boolean DEFAULT false NOT NULL,
   ID varchar(6) NOT NULL,
   STYLE varchar,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.wp_attachments
(
   UUID uuid NOT NULL,
   WP_UUID uuid NOT NULL,
   FILENAME varchar(1024) NOT NULL,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.wp_observation
(
   UUID uuid NOT NULL,
   WP_UUID uuid NOT NULL,
   CATEGORY_UUID uuid NOT NULL,
   EMPLOYEE_UUID uuid,
   PRIMARY KEY (UUID)
);

CREATE TABLE smart.wp_observation_attributes
(
   OBSERVATION_UUID uuid NOT NULL,
   ATTRIBUTE_UUID uuid NOT NULL,
   LIST_ELEMENT_UUID uuid,
   TREE_NODE_UUID uuid,
   NUMBER_VALUE float(52),
   STRING_VALUE varchar(1024),
   PRIMARY KEY (OBSERVATION_UUID,ATTRIBUTE_UUID)
);

ALTER TABLE smart.agency
ADD CONSTRAINT AGENCY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE
DEFERRABLE;

ALTER TABLE smart.AREA_GEOMETRIES
ADD CONSTRAINT AREA_GEOMETRIES_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE
DEFERRABLE;

ALTER TABLE smart.CA_PROJECTION
ADD CONSTRAINT CA_PROJECTION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE 
DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE
ADD CONSTRAINT CM_ATTRIBUTE_NODE_UUID_FK
FOREIGN KEY (NODE_UUID)
REFERENCES smart.CM_NODE(UUID) ON DELETE CASCADE
DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE
ADD CONSTRAINT CM_ATTRIBUTE_ATTRIBUTE_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE
DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_LIST
ADD CONSTRAINT CM_ATTRIBUTE_LIST_CM_UUID_FK
FOREIGN KEY (CM_UUID)
REFERENCES smart.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE
DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_LIST
ADD CONSTRAINT CM_ATTRIBUTE_LIST_CM_ATTRIBUTE_UUID_FK
FOREIGN KEY (CM_ATTRIBUTE_UUID)
REFERENCES smart.CM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_LIST
ADD CONSTRAINT CM_ATTRIBUTE_LIST_DM_ATTRIBUTE_UUID_FK
FOREIGN KEY (DM_ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_LIST
ADD CONSTRAINT CM_ATTRIBUTE_LIST_LIST_ELEMENT_UUID_FK
FOREIGN KEY (LIST_ELEMENT_UUID)
REFERENCES smart.DM_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_OPTION
ADD CONSTRAINT CM_ATTRIBUTE_OPTION_CM_ATTRIBUTE_UUID_FK
FOREIGN KEY (CM_ATTRIBUTE_UUID)
REFERENCES smart.CM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_TREE_NODE
ADD CONSTRAINT CM_ATTRIBUTE_TREE_NODE_TREE_NODE_UUID_FK
FOREIGN KEY (DM_TREE_NODE_UUID)
REFERENCES smart.DM_ATTRIBUTE_TREE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_TREE_NODE
ADD CONSTRAINT CM_ATTRIBUTE_TREE_NODE_CM_UUID_FK
FOREIGN KEY (CM_UUID)
REFERENCES smart.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_TREE_NODE
ADD CONSTRAINT CM_ATTRIBUTE_TREE_NODE_CM_ATTRIBUTE_UUID_FK
FOREIGN KEY (CM_ATTRIBUTE_UUID)
REFERENCES smart.CM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_TREE_NODE
ADD CONSTRAINT CM_ATTRIBUTE_TREE_NODE_DM_ATTRIBUTE_UUID_FK
FOREIGN KEY (DM_ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_ATTRIBUTE_TREE_NODE
ADD CONSTRAINT CM_ATTRIBUTE_TREE_NODE_PARENT_UUID_FK
FOREIGN KEY (PARENT_UUID)
REFERENCES smart.CM_ATTRIBUTE_TREE_NODE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_NODE
ADD CONSTRAINT CM_NODE_CATEGORY_UUID_FK
FOREIGN KEY (CATEGORY_UUID)
REFERENCES smart.DM_CATEGORY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CM_NODE
ADD CONSTRAINT CM_NODE_CM_UUID_FK
FOREIGN KEY (CM_UUID)
REFERENCES smart.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE SMART.CM_DM_ATTRIBUTE_SETTINGS 
ADD CONSTRAINT CM_DM_ATTRIBUTE_SETTINGS_CM_UUID_FK 
FOREIGN KEY (CM_UUID) 
REFERENCES SMART.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE SMART.CM_DM_ATTRIBUTE_SETTINGS 
ADD CONSTRAINT CM_DM_ATTRIBUTE_SETTINGS_DM_ATTRIBUTE_UUID_FK 
FOREIGN KEY (DM_ATTRIBUTE_UUID) 
REFERENCES SMART.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CONFIGURABLE_MODEL
ADD CONSTRAINT CONFIGURABLE_MODEL_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.connect_alert 
ADD CONSTRAINT connect_alert_cm_uuid_fk 
FOREIGN KEY (CM_UUID) 
REFERENCES smart.configurable_model(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.connect_alert 
ADD CONSTRAINT connect_alert_cm_attribute_uuid_fk 
FOREIGN KEY (CM_ATTRIBUTE_UUID) 
REFERENCES smart.cm_attribute(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.CT_PROPERTIES_OPTION
ADD CONSTRAINT CT_PROPERTIES_OPTION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ct_properties_profile 
ADD CONSTRAINT CT_PROPERTIES_PROFILE_CA_UUID_FK 
FOREIGN KEY (CA_UUID) 
REFERENCES SMART.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE ;

ALTER TABLE smart.ct_properties_profile_option 
ADD CONSTRAINT CT_PROPERTIES_PROFILE_OPTION_PROFILE_UUID_FK 
FOREIGN KEY (profile_uuid) 
REFERENCES smart.ct_properties_profile(UUID) ON DELETE CASCADE DEFERRABLE ;

ALTER TABLE smart.cm_ct_properties_profile 
ADD CONSTRAINT CM_CT_PROPERTIES_PROFILE_CM_UUID_FK 
FOREIGN KEY (CM_UUID) 
REFERENCES SMART.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.cm_ct_properties_profile 
ADD CONSTRAINT CM_CT_PROPERTIES_PROFILE_PROFILE_UUID_FK 
FOREIGN KEY (PROFILE_UUID)
REFERENCES SMART.CT_PROPERTIES_PROFILE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_AGGREGATION_I18N
ADD CONSTRAINT DM_AGGREGATION_I18N_FK
FOREIGN KEY (NAME)
REFERENCES smart.DM_AGGREGATION(NAME) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_ATT_AGG_MAP
ADD CONSTRAINT DM_ATT_AGG_MAP_AGG_NAME_FK
FOREIGN KEY (AGG_NAME)
REFERENCES smart.DM_AGGREGATION(NAME)  DEFERRABLE;

ALTER TABLE smart.DM_ATT_AGG_MAP
ADD CONSTRAINT DM_ATT_AGG_MAP_ATTRIBUTE_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.DM_ATTRIBUTE
ADD CONSTRAINT DM_ATTRIBUTE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.DM_ATTRIBUTE_LIST
ADD CONSTRAINT DM_ATTRIBUTE_LIST_ATTRIBUTE_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.DM_ATTRIBUTE_TREE
ADD CONSTRAINT DM_ATTRIBUT_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_ATTRIBUTE_TREE
ADD CONSTRAINT DM_ATTRIBUT_TREE_PARENT_UUID_FK
FOREIGN KEY (PARENT_UUID)
REFERENCES smart.DM_ATTRIBUTE_TREE(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.DM_CAT_ATT_MAP
ADD CONSTRAINT DM_CAT_ATT_MAP_ATTRIBUTE_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_CAT_ATT_MAP
ADD CONSTRAINT DM_CAT_ATT_MAP_CATEGORY_UUID_FK
FOREIGN KEY (CATEGORY_UUID)
REFERENCES smart.DM_CATEGORY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_CATEGORY
ADD CONSTRAINT DM_CATEGORY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.DM_CATEGORY
ADD CONSTRAINT DM_CATEGORY_PARENT_CATEGORY_UUID_FK
FOREIGN KEY (PARENT_CATEGORY_UUID)
REFERENCES smart.DM_CATEGORY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.EMPLOYEE
ADD CONSTRAINT EMPLOYEE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.EMPLOYEE
ADD CONSTRAINT EMPLOYEE_AGENCY_UUID_FK
FOREIGN KEY (AGENCY_UUID)
REFERENCES smart.AGENCY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.EMPLOYEE
ADD CONSTRAINT EMPLOYEE_RANK_UUID_FK
FOREIGN KEY (RANK_UUID)
REFERENCES smart.RANK(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY
ADD CONSTRAINT ENTITY_TYPE_UUID_FK
FOREIGN KEY (ENTITY_TYPE_UUID)
REFERENCES smart.ENTITY_TYPE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY
ADD CONSTRAINT ENTITY_ATTRIBUTE_LIST_ITEM_UUID_FK
FOREIGN KEY (ATTRIBUTE_LIST_ITEM_UUID)
REFERENCES smart.DM_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE
ADD CONSTRAINT ENTITY_ATTRIBUTE_DM_ATTRIBUTE_FK
FOREIGN KEY (DM_ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE
ADD CONSTRAINT ENTITY_ATTRIBUTE_TYPE_UUID_FK
FOREIGN KEY (ENTITY_TYPE_UUID)
REFERENCES smart.ENTITY_TYPE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE_VALUE
ADD CONSTRAINT ENTITY_ATTRIBUTE_VALUE_LISTELEMENT_FK
FOREIGN KEY (LIST_ELEMENT_UUID)
REFERENCES smart.DM_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE_VALUE
ADD CONSTRAINT ENTITY_ATTRIBUTE_VALUE_ENTITY_FK
FOREIGN KEY (ENTITY_UUID)
REFERENCES smart.ENTITY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE_VALUE
ADD CONSTRAINT ENTITY_ATTRIBUTE_VALUE_TREENODE_FK
FOREIGN KEY (TREE_NODE_UUID)
REFERENCES smart.DM_ATTRIBUTE_TREE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_ATTRIBUTE_VALUE
ADD CONSTRAINT ENTITY_ATTRIBUTE_VALUE_ATTRIBUTE_FK
FOREIGN KEY (ENTITY_ATTRIBUTE_UUID)
REFERENCES smart.ENTITY_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_GRIDDED_QUERY
ADD CONSTRAINT ENTITY_GRIDDED_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_GRIDDED_QUERY
ADD CONSTRAINT ENTITY_GRIDDED_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_GRIDDED_QUERY
ADD CONSTRAINT ENTITY_GRIDDED_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_OBSERVATION_QUERY
ADD CONSTRAINT ENTITY_OBSERVATION_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_OBSERVATION_QUERY
ADD CONSTRAINT ENTITYOBSERVATION_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_OBSERVATION_QUERY
ADD CONSTRAINT ENTITY_OBSERVATION_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_SUMMARY_QUERY
ADD CONSTRAINT ENTITY_SUMMARY_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_SUMMARY_QUERY
ADD CONSTRAINT ENTITY_SUMMARY_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_SUMMARY_QUERY
ADD CONSTRAINT ENTITY_SUMMARY_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_TYPE
ADD CONSTRAINT ENTITY_TYPE_DM_ATTRIBUTE_FK
FOREIGN KEY (DM_ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_TYPE
ADD CONSTRAINT ENTITY_TYPE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_WAYPOINT_QUERY
ADD CONSTRAINT ENTITY_WAYPOINT_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_WAYPOINT_QUERY
ADD CONSTRAINT ENTITY_WAYPOINT_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.ENTITY_WAYPOINT_QUERY
ADD CONSTRAINT ENTITYWAYPOINT_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.GRIDDED_QUERY
ADD CONSTRAINT GRIDDED_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.GRIDDED_QUERY
ADD CONSTRAINT GRIDDED_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.GRIDDED_QUERY
ADD CONSTRAINT GRIDDED_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.I18N_LABEL
ADD CONSTRAINT LANGUAGES_CA_UUID_FK
FOREIGN KEY (LANGUAGE_UUID)
REFERENCES smart.LANGUAGE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INFORMANT
ADD CONSTRAINT INFORMANT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_RECORD_QUERY
ADD CONSTRAINT INTEL_RECORD_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_RECORD_QUERY
ADD CONSTRAINT INTEL_RECORD_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_RECORD_QUERY
ADD CONSTRAINT INTEL_RECORD_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_SUMMARY_QUERY
ADD CONSTRAINT INTEL_SUMMARY_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_SUMMARY_QUERY
ADD CONSTRAINT INTEL_SUMMARY_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTEL_SUMMARY_QUERY
ADD CONSTRAINT INTEL_SUMMARY_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE
ADD CONSTRAINT INTELLIGENCE_INFORMANT_UUID_FK
FOREIGN KEY (INFORMANT_UUID)
REFERENCES smart.INFORMANT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE
ADD CONSTRAINT INTELLIGENCE_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE
ADD CONSTRAINT INTELLIGENCE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE
ADD CONSTRAINT INTELLIGENCE_PATROL_UUID_FK
FOREIGN KEY (PATROL_UUID)
REFERENCES smart.PATROL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE
ADD CONSTRAINT INTELLIGENCE_SOURCE_UUID_FK
FOREIGN KEY (SOURCE_UUID)
REFERENCES smart.INTELLIGENCE_SOURCE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE_ATTACHMENT
ADD CONSTRAINT INTELLIGENCE_ATTACHMENT_INTELLIGENCE_UUID_FK
FOREIGN KEY (INTELLIGENCE_UUID)
REFERENCES smart.INTELLIGENCE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE_POINT
ADD CONSTRAINT INTELLIGENCE_POINT_INTELLIGENCE_UUID_FK
FOREIGN KEY (INTELLIGENCE_UUID)
REFERENCES smart.INTELLIGENCE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.INTELLIGENCE_SOURCE
ADD CONSTRAINT INTELLIGENCE_SOURCE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.LANGUAGE
ADD CONSTRAINT LANGUAGE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MAP_STYLES
ADD CONSTRAINT MAPSTYLE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION
ADD CONSTRAINT MISSION_SURVEY_UUID
FOREIGN KEY (SURVEY_UUID)
REFERENCES smart.SURVEY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_ATTRIBUTE
ADD CONSTRAINT MISSION_ATT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_ATTRIBUTE_LIST
ADD CONSTRAINT MISSION_ATT_LIST_MISSION_ATT_UUID_FK
FOREIGN KEY (MISSION_ATTRIBUTE_UUID)
REFERENCES smart.MISSION_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_DAY
ADD CONSTRAINT MISSION_DAY_MISSION_UUID_FK
FOREIGN KEY (MISSION_UUID)
REFERENCES smart.MISSION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_MEMBER
ADD CONSTRAINT MISSION_MEMBER_MISSION_UUID_FK
FOREIGN KEY (MISSION_UUID)
REFERENCES smart.MISSION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_PROPERTY
ADD CONSTRAINT MISSION_PROP_SURVEY_DSG_UUID
FOREIGN KEY (SURVEY_DESIGN_UUID)
REFERENCES smart.SURVEY_DESIGN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_PROPERTY
ADD CONSTRAINT MISSION_PROP_MISSION_ATT_UUID_FK
FOREIGN KEY (MISSION_ATTRIBUTE_UUID)
REFERENCES smart.MISSION_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_PROPERTY_VALUE
ADD CONSTRAINT MISSION_PROP_VALUE_MISSION_ATT_UUID
FOREIGN KEY (MISSION_ATTRIBUTE_UUID)
REFERENCES smart.MISSION_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_PROPERTY_VALUE
ADD CONSTRAINT MISSION_PROP_VALUE_LISTELEMENT_UUID
FOREIGN KEY (LIST_ELEMENT_UUID)
REFERENCES smart.MISSION_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_PROPERTY_VALUE
ADD CONSTRAINT MISSION_PROP_VALUE_MISSION_UUID
FOREIGN KEY (MISSION_UUID)
REFERENCES smart.MISSION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_TRACK
ADD CONSTRAINT MISSION_TRACK_MISSIONDAY_UUID
FOREIGN KEY (MISSION_DAY_UUID)
REFERENCES smart.MISSION_DAY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.MISSION_TRACK
ADD CONSTRAINT MISSION_TRACK
FOREIGN KEY (SAMPLING_UNIT_UUID)
REFERENCES smart.SAMPLING_UNIT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_GRIDDED_QUERY
ADD CONSTRAINT OBS_GRIDDED_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_GRIDDED_QUERY
ADD CONSTRAINT OBS_GRIDDED_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_GRIDDED_QUERY
ADD CONSTRAINT OBS_GRIDDED_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_OBSERVATION_QUERY
ADD CONSTRAINT OBSOBSERVATION_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_OBSERVATION_QUERY
ADD CONSTRAINT OBS_OBSERVATION_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_OBSERVATION_QUERY
ADD CONSTRAINT OBS_OBSERVATION_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_SUMMARY_QUERY
ADD CONSTRAINT OBS_SUMMARY_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_SUMMARY_QUERY
ADD CONSTRAINT OBS_SUMMARY_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_SUMMARY_QUERY
ADD CONSTRAINT OBS_SUMMARY_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_WAYPOINT_QUERY
ADD CONSTRAINT OBS_WAYPOINT_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_WAYPOINT_QUERY
ADD CONSTRAINT OBSWAYPOINT_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBS_WAYPOINT_QUERY
ADD CONSTRAINT OBS_WAYPOINT_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBSERVATION_ATTACHMENT
ADD CONSTRAINT OBSERVATION_ATTACHMENT_OBS_UUID_FK
FOREIGN KEY (OBS_UUID)
REFERENCES smart.WP_OBSERVATION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBSERVATION_OPTIONS
ADD CONSTRAINT PATROL_OPTIONS_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBSERVATION_QUERY
ADD CONSTRAINT OBSERVATION_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBSERVATION_QUERY
ADD CONSTRAINT OBSERVATION_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.OBSERVATION_QUERY
ADD CONSTRAINT OBSERVATION_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL
ADD CONSTRAINT PATROL_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL
ADD CONSTRAINT PATROL_MANDATE_UUID_FK
FOREIGN KEY (MANDATE_UUID)
REFERENCES smart.PATROL_MANDATE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL
ADD CONSTRAINT PATROL_TEAM_UUID_FK
FOREIGN KEY (TEAM_UUID)
REFERENCES smart.TEAM(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL
ADD CONSTRAINT PATROL_STATION_UUID_FK
FOREIGN KEY (STATION_UUID)
REFERENCES smart.STATION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_INTELLIGENCE
ADD CONSTRAINT PATROL_INTELLIGENCE_INTELLIGENCE_UUID_FK
FOREIGN KEY (INTELLIGENCE_UUID)
REFERENCES smart.INTELLIGENCE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_INTELLIGENCE
ADD CONSTRAINT PATROL_INTELLIGENCE_PATROL_UUID_FK
FOREIGN KEY (PATROL_UUID)
REFERENCES smart.PATROL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_LEG
ADD CONSTRAINT PATROL_LEG_PATROL_UUID_FK
FOREIGN KEY (PATROL_UUID)
REFERENCES smart.PATROL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_LEG
ADD CONSTRAINT PATROL_LEG_TRANSPORT_UUID_FK
FOREIGN KEY (TRANSPORT_UUID)
REFERENCES smart.PATROL_TRANSPORT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_LEG_DAY
ADD CONSTRAINT PATROL_LEG_DAY_LEG_UUID_FK
FOREIGN KEY (PATROL_LEG_UUID)
REFERENCES smart.PATROL_LEG(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_LEG_MEMBERS
ADD CONSTRAINT LEG_MEMBERS_EMPLOYEE_UUID_FK
FOREIGN KEY (EMPLOYEE_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_LEG_MEMBERS
ADD CONSTRAINT LEG_MEMBERS_PATROL_LEG_UUID_FK
FOREIGN KEY (PATROL_LEG_UUID)
REFERENCES smart.PATROL_LEG(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_MANDATE
ADD CONSTRAINT PATROL_MANDATE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_PLAN
ADD CONSTRAINT PATROL_PLAN_PATROL_UUID_FK
FOREIGN KEY (PATROL_UUID)
REFERENCES smart.PATROL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_PLAN
ADD CONSTRAINT PATROL_PLAN_PLAN_UUID_FK
FOREIGN KEY (PLAN_UUID)
REFERENCES smart.PLAN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_QUERY
ADD CONSTRAINT PATROL_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_QUERY
ADD CONSTRAINT PATROL_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_QUERY
ADD CONSTRAINT PATROL_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_TRANSPORT
ADD CONSTRAINT PATROL_TRANSPORT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_TYPE
ADD CONSTRAINT PATROL_TYPE_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_WAYPOINT
ADD CONSTRAINT PATROL_WAYPOINT_WP_UUID_FK
FOREIGN KEY (WP_UUID)
REFERENCES smart.WAYPOINT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PATROL_WAYPOINT
ADD CONSTRAINT PATROL_WAYPOINT_LEG_DAY_UUID_FK
FOREIGN KEY (LEG_DAY_UUID)
REFERENCES smart.PATROL_LEG_DAY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN
ADD CONSTRAINT PLAN_PARENT_UUID_FK
FOREIGN KEY (PARENT_UUID)
REFERENCES smart.PLAN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN
ADD CONSTRAINT PLAN_TEAM_UUID_FK
FOREIGN KEY (TEAM_UUID)
REFERENCES smart.TEAM(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN
ADD CONSTRAINT PLAN_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN
ADD CONSTRAINT PLAN_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN
ADD CONSTRAINT PLAN_STATION_UUID_FK
FOREIGN KEY (STATION_UUID)
REFERENCES smart.STATION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN_TARGET
ADD CONSTRAINT TARGET_PLAN_UUID_FK
FOREIGN KEY (PLAN_UUID)
REFERENCES smart.PLAN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.PLAN_TARGET_POINT
ADD CONSTRAINT PLAN_TARGET_POINT_PLAN_TARGET_UUID_FK
FOREIGN KEY (PLAN_TARGET_UUID)
REFERENCES smart.PLAN_TARGET(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.QUERY_FOLDER
ADD CONSTRAINT QUERY_FOLDER_EMPLOYEE_UUID_FK
FOREIGN KEY (EMPLOYEE_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.QUERY_FOLDER
ADD CONSTRAINT QUERY_FOLDER_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.QUERY_FOLDER
ADD CONSTRAINT QUERY_FOLDER_PARENT_UUID_FK
FOREIGN KEY (PARENT_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.RANK
ADD CONSTRAINT RANK_AGENCY_UUID_FK
FOREIGN KEY (AGENCY_UUID)
REFERENCES smart.AGENCY(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.REPORT
ADD CONSTRAINT REPORT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.REPORT
ADD CONSTRAINT REPORT_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.REPORT
ADD CONSTRAINT REPORT_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.REPORT_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.REPORT_FOLDER
ADD CONSTRAINT REPORT_FOLDER_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.REPORT_FOLDER
ADD CONSTRAINT REPORT_FOLDER_PARENT_UUID_FK
FOREIGN KEY (PARENT_UUID)
REFERENCES smart.REPORT_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.REPORT_FOLDER
ADD CONSTRAINT REPORT_EMPLOYEE_UUID_FK
FOREIGN KEY (EMPLOYEE_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.REPORT_QUERY
ADD CONSTRAINT REPORT_QUERY_REPORT_UUID_FK
FOREIGN KEY (REPORT_UUID)
REFERENCES smart.REPORT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAMPLING_UNIT
ADD CONSTRAINT SAMPLING_UNIT_SURVEY_DSG_UUID
FOREIGN KEY (SURVEY_DESIGN_UUID)
REFERENCES smart.SURVEY_DESIGN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAMPLING_UNIT_ATTRIBUTE
ADD CONSTRAINT SU_ATTRIBUTE_CA_UUID
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;


ALTER TABLE smart.SAMPLING_UNIT_ATTRIBUTE_LIST
ADD CONSTRAINT SU_ATT_LIST_MISSION_ATT_UUID_FK
FOREIGN KEY (SAMPLING_UNIT_ATTRIBUTE_UUID)
REFERENCES smart.SAMPLING_UNIT_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAMPLING_UNIT_ATTRIBUTE_VALUE
ADD CONSTRAINT SU_SU_ATTRIBUTE_UUID
FOREIGN KEY (SU_ATTRIBUTE_UUID)
REFERENCES smart.SAMPLING_UNIT_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAMPLING_UNIT_ATTRIBUTE_VALUE
ADD CONSTRAINT SU_SU_LIST_ELEMENT_UUID
FOREIGN KEY (LIST_ELEMENT_UUID)
REFERENCES smart.SAMPLING_UNIT_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAMPLING_UNIT_ATTRIBUTE_VALUE
ADD CONSTRAINT SU_SU_UUID
FOREIGN KEY (SU_UUID)
REFERENCES smart.SAMPLING_UNIT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SAVED_MAPS
ADD CONSTRAINT SAVED_MAPS_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SCREEN_OPTION
ADD CONSTRAINT SCREEN_OPTION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SCREEN_OPTION_UUID
ADD CONSTRAINT SCREEN_OPTION_UUID_OPTION_UUID_FK
FOREIGN KEY (OPTION_UUID)
REFERENCES smart.SCREEN_OPTION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.STATION
ADD CONSTRAINT STATION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SUMMARY_QUERY
ADD CONSTRAINT SUMMARY_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SUMMARY_QUERY
ADD CONSTRAINT SUMMARY_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SUMMARY_QUERY
ADD CONSTRAINT SUMMARY_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY
ADD CONSTRAINT SURVEY_SURVEY_DSG_UUID
FOREIGN KEY (SURVEY_DESIGN_UUID)
REFERENCES smart.SURVEY_DESIGN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_DESIGN
ADD CONSTRAINT CONFIGURABLE_MODEL_UUID_FK
FOREIGN KEY (CONFIGURABLE_MODEL_UUID)
REFERENCES smart.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_DESIGN
ADD CONSTRAINT SD_CAL_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_DESIGN_PROPERTY
ADD CONSTRAINT SURVEY_DSG_PROP_SURVEY_DSG_UUID
FOREIGN KEY (SURVEY_DESIGN_UUID)
REFERENCES smart.SURVEY_DESIGN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_DESIGN_SAMPLING_UNIT
ADD CONSTRAINT SD_SU_SURVEY_DESIGN_UUID
FOREIGN KEY (SURVEY_DESIGN_UUID)
REFERENCES smart.SURVEY_DESIGN(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_DESIGN_SAMPLING_UNIT
ADD CONSTRAINT SD_SU_SU_ATTRIBUTE_UUID
FOREIGN KEY (SU_ATTRIBUTE_UUID)
REFERENCES smart.SAMPLING_UNIT_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_GRIDDED_QUERY
ADD CONSTRAINT SVY_GRIDDED_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_GRIDDED_QUERY
ADD CONSTRAINT SVY_GRIDDED_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_GRIDDED_QUERY
ADD CONSTRAINT SVY_GRIDDED_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_QUERY
ADD CONSTRAINT SVY_MISSION_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_QUERY
ADD CONSTRAINT SVY_MISSION_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_QUERY
ADD CONSTRAINT SVY_MISSION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_TRACK_QUERY
ADD CONSTRAINT SVY_MISSION_TRACK_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_TRACK_QUERY
ADD CONSTRAINT SVY_MISSION_TRACK_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_MISSION_TRACK_QUERY
ADD CONSTRAINT SVY_MISSION_TRACK_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_OBSERVATION_QUERY
ADD CONSTRAINT SVY_OBSERVATION_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_OBSERVATION_QUERY
ADD CONSTRAINT SVY_OBSERVATION_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_OBSERVATION_QUERY
ADD CONSTRAINT SVY_OBSERVATION_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_SUMMARY_QUERY
ADD CONSTRAINT SVY_SUMMARY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_SUMMARY_QUERY
ADD CONSTRAINT SVY_SUMMARY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_SUMMARY_QUERY
ADD CONSTRAINT SVY_SUMMARY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT
ADD CONSTRAINT SURVEY_WP_MISSION_TRK_UUID
FOREIGN KEY (MISSION_TRACK_UUID)
REFERENCES smart.MISSION_TRACK(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT
ADD CONSTRAINT SURVEY_WP_SAMPLING_UNIT_UUID
FOREIGN KEY (SAMPLING_UNIT_UUID)
REFERENCES smart.SAMPLING_UNIT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT
ADD CONSTRAINT SURVEY_WP_MISSIONDAY_UUID
FOREIGN KEY (MISSION_DAY_UUID)
REFERENCES smart.MISSION_DAY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT_QUERY
ADD CONSTRAINT SVY_WAYPOINT_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT_QUERY
ADD CONSTRAINT SVY_WAYPOINT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.SURVEY_WAYPOINT_QUERY
ADD CONSTRAINT SVY_WAYPOINT_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.TEAM
ADD CONSTRAINT TEAM_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.TEAM
ADD CONSTRAINT TEAM_PATROL_MANDATE_UUID_FK
FOREIGN KEY (PATROL_MANDATE_UUID)
REFERENCES smart.PATROL_MANDATE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.TRACK
ADD CONSTRAINT TRACK_LEG_DAY_UUID_FK
FOREIGN KEY (PATROL_LEG_DAY_UUID)
REFERENCES smart.PATROL_LEG_DAY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WAYPOINT
ADD CONSTRAINT WAYPOINT_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WAYPOINT_QUERY
ADD CONSTRAINT WAYPOINT_QUERY_CA_UUID_FK
FOREIGN KEY (CA_UUID)
REFERENCES smart.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WAYPOINT_QUERY
ADD CONSTRAINT WAYPOINT_QUERY_FOLDER_UUID_FK
FOREIGN KEY (FOLDER_UUID)
REFERENCES smart.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WAYPOINT_QUERY
ADD CONSTRAINT WAYPOINT_QUERY_CREATOR_UUID_FK
FOREIGN KEY (CREATOR_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_ATTACHMENTS
ADD CONSTRAINT WP_ATTACHMENTS_WP_UUID_FK
FOREIGN KEY (WP_UUID)
REFERENCES smart.WAYPOINT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION
ADD CONSTRAINT OBSERVATION_WP_UUID_FK
FOREIGN KEY (WP_UUID)
REFERENCES smart.WAYPOINT(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION
ADD CONSTRAINT OBS_EMPLOYEE_UUID_FK
FOREIGN KEY (EMPLOYEE_UUID)
REFERENCES smart.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION
ADD CONSTRAINT OBSERVATION_CATEGORY_UUID_FK
FOREIGN KEY (CATEGORY_UUID)
REFERENCES smart.DM_CATEGORY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION_ATTRIBUTES
ADD CONSTRAINT OBSERVATION_ATTRIBUTE_ATT_TREE_UUID_FK
FOREIGN KEY (TREE_NODE_UUID)
REFERENCES smart.DM_ATTRIBUTE_TREE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION_ATTRIBUTES
ADD CONSTRAINT OBSERVATION_ATTRIBUTE_ATT_LIST_UUID_FK
FOREIGN KEY (LIST_ELEMENT_UUID)
REFERENCES smart.DM_ATTRIBUTE_LIST(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION_ATTRIBUTES
ADD CONSTRAINT OBS_ATTRIBUTE_OBS_UUID_FK
FOREIGN KEY (OBSERVATION_UUID)
REFERENCES smart.WP_OBSERVATION(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.WP_OBSERVATION_ATTRIBUTES
ADD CONSTRAINT OBSERVATION_ATTRIBUTE_ATT_UUID_FK
FOREIGN KEY (ATTRIBUTE_UUID)
REFERENCES smart.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.connect_ct_properties 
ADD CONSTRAINT connect_ct_properties_cm_uuid_fk 
FOREIGN KEY (CM_UUID) 
REFERENCES smart.configurable_model(UUID) ON DELETE CASCADE DEFERRABLE;

-- Unique Constraints
alter table smart.PATROL_MANDATE add constraint patrol_mandate_keyid_unq UNIQUE(ca_uuid, keyid) DEFERRABLE ;
alter table smart.PATROL_TRANSPORT add constraint patrol_transport_keyid_unq UNIQUE(ca_uuid, keyid) DEFERRABLE ;
alter table smart.TEAM add constraint team_keyid_unq UNIQUE(ca_uuid, keyid) DEFERRABLE ;
alter table smart.DM_ATTRIBUTE add constraint dm_attribute_keyid_unq UNIQUE(ca_uuid, keyid) DEFERRABLE ;
alter table smart.DM_ATTRIBUTE_LIST add constraint dm_attribute_list_keyid_unq UNIQUE(attribute_uuid, keyid) DEFERRABLE ;
alter table smart.DM_CATEGORY add constraint dm_category_keyid_unq UNIQUE(ca_uuid, hkey) DEFERRABLE ;
alter table smart.DM_ATTRIBUTE_TREE add constraint dm_attribute_tree_keyid_unq UNIQUE(attribute_uuid, hkey) DEFERRABLE ;
alter table smart.INTELLIGENCE_SOURCE add constraint intell_source_keyid_unq unique(ca_uuid, keyid) DEFERRABLE ;
alter table smart.ENTITY_ATTRIBUTE add constraint entity_attribute_keyid_unq unique(entity_type_uuid, keyid) DEFERRABLE ;
alter table smart.ENTITY_TYPE add constraint entity_type_keyid_unq unique(ca_uuid, keyid) DEFERRABLE ;
alter table smart.MISSION_ATTRIBUTE add constraint mission_attribute_keyid_unq unique(ca_uuid, keyid) DEFERRABLE ;
alter table smart.MISSION_ATTRIBUTE_LIST add constraint mission_attribute_list_keyid_unq unique(mission_attribute_uuid, keyid) DEFERRABLE ;
alter table smart.SAMPLING_UNIT_ATTRIBUTE add constraint su_attribute_keyid_unq unique(ca_uuid, keyid) DEFERRABLE ;
alter table smart.SAMPLING_UNIT_ATTRIBUTE_LIST add constraint su_list_attribute_keyid_unq unique(sampling_unit_attribute_uuid, keyid) DEFERRABLE ;
alter table smart.SURVEY_DESIGN add constraint survey_design_keyid_unq unique(ca_uuid, keyid) DEFERRABLE ;


insert into smart.dm_aggregation(name) values ('sum');
insert into smart.dm_aggregation(name) values ('avg');
insert into smart.dm_aggregation(name) values ('min');
insert into smart.dm_aggregation(name) values ('max');
insert into smart.dm_aggregation(name) values ('stddev_samp');
insert into smart.dm_aggregation(name) values ('var_samp');

insert into smart.dm_aggregation_i18n values ('stddev_samp', 'en', 'standard deviation (samp.)');
insert into smart.dm_aggregation_i18n values ('var_samp', 'en', 'variance (samp.)');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'es', 'DesviaciÃ³n estÃ¡ndar');
insert into smart.dm_aggregation_i18n values ('var_samp', 'es', 'Varianza');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'fr', 'Ecart type');
insert into smart.dm_aggregation_i18n values ('var_samp', 'fr', 'Variance');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'vi', 'Ä�á»™ lá»‡ch chuáº©n');
insert into smart.dm_aggregation_i18n values ('var_samp', 'vi', 'PhÆ°Æ¡ng sai');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'th', 'à¸ªà¹ˆà¸§à¸™à¹€à¸šà¸µà¹ˆà¸¢à¸‡à¹€à¸šà¸™à¸¡à¸²à¸•à¸£à¸�à¸²à¸™');
insert into smart.dm_aggregation_i18n values ('var_samp', 'th', 'à¸„à¹ˆà¸²à¸„à¸§à¸²à¸¡à¹�à¸›à¸£à¸›à¸£à¸§à¸™');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'zh', 'æ ‡å‡†å·®');
insert into smart.dm_aggregation_i18n values ('var_samp', 'zh', 'æ–¹å·®');
insert into smart.dm_aggregation_i18n values ('stddev_samp', 'in', 'Standar Deviasi');
insert into smart.dm_aggregation_i18n values ('var_samp', 'in', 'Varians');		

			
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','en','sum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','en','minimum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','en','maximum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','en','average');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','fr','total');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','fr','minimum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','fr','maximum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','fr','moyenne');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','es','total');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','es','mÃ­nimo');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','es','mÃ¡ximo');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','es','promedio');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','in','jumlah');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','in','minimum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','in','maksimum');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','in','rata-rata');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','th','à¸œà¸¥à¸£à¸§à¸¡');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','th','à¸„à¹ˆà¸²à¸•à¹ˆà¸³à¸ªà¸¸à¸”');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','th','à¸„à¹ˆà¸²à¸ªà¸¹à¸‡à¸ªà¸¸à¸”');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','th','à¸„à¹ˆà¸²à¹€à¸‰à¸¥à¸µà¹ˆà¸¢');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','zh','å�ˆè®¡');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','zh','æœ€å°�');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','zh','æœ€å¤§');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','zh','å¹³å�‡');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('sum','ru','Ð¸Ñ‚Ð¾Ð³Ð°');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('min','ru','Ð¼Ð¸Ð½Ð¸Ð¼Ð°Ð»ÑŒÐ½Ñ‹Ð¹');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('max','ru','Ð¼Ð°ÐºÑ�Ð¸Ð¼Ð°Ð»ÑŒÐ½Ñ‹Ð¹');
insert into smart.DM_AGGREGATION_i18n (name, lang_code, gui_name) values ('avg','ru','Ñ�Ñ€ÐµÐ´Ð½Ð¸Ð¹');


create table smart.connect_server(
uuid UUID not null,
ca_uuid UUID,
url varchar(2064),
certificate varchar(32000),
PRIMARY KEY (uuid));

alter table smart.connect_server add constraint server_ca_uuid_fk foreign key (ca_uuid) 
references smart.conservation_area (uuid) on update restrict on delete cascade DEFERRABLE;

CREATE TABLE smart.connect_server_option(
server_uuid UUID not null, 
option_key varchar(32), 
value varchar(2048), 
primary key (server_uuid, option_key));

ALTER TABLE smart.connect_server_option ADD CONSTRAINT cnt_svr_opt_server_fk FOREIGN KEY (server_uuid) 
REFERENCES smart.connect_server (uuid)   ON UPDATE restrict ON DELETE cascade DEFERRABLE ;


create table smart.connect_account(
employee_uuid UUID not null,
connect_uuid UUID not null,
connect_user varchar(32),
connect_pass varchar(1024),
primary key(employee_uuid, connect_uuid));

alter table smart.connect_account add constraint connect_employee_uuid_fk foreign key (employee_uuid) 
references smart.employee (uuid) on update restrict on delete cascade DEFERRABLE;

-- DATA PROCESSING QUEUE TABLES
CREATE TABLE smart.connect_data_queue(
	uuid UUID NOT NULL,
	type VARCHAR(32) NOT NULL,
	ca_uuid UUID,
	name VARCHAR(4096),
	status varchar(32) NOT NULL,
	queue_order integer,
	error_message VARCHAR(8192),
	local_file varchar(4096),
	date_processed timestamp,
	server_item_uuid UUID,
	PRIMARY KEY (uuid)
);
		
ALTER TABLE smart.connect_data_queue ADD CONSTRAINT 
connect_data_queue_ca_uuid_fk foreign key (ca_uuid) 
REFERENCES smart.conservation_area(uuid) ON UPDATE restrict ON DELETE cascade DEFERRABLE;

ALTER TABLE smart.connect_data_queue ADD CONSTRAINT status_chk 
CHECK (status IN ('DOWNLOADING', 'REQUEUED', 'QUEUED', 'PROCESSING', 'COMPLETE', 'COMPLETE_WARN', 'ERROR'));
		
ALTER TABLE smart.connect_data_queue ADD CONSTRAINT type_chk 
CHECK (type IN ('PATROL_XML', 'INCIDENT_XML', 'MISSION_XML', 'INTELL_XML'));


CREATE TABLE smart.connect_data_queue_option(
	ca_uuid UUID not null, 
	keyid varchar(256) NOT NULL, 
	value varchar(512), 
	primary key (ca_uuid, keyid)
);
ALTER TABLE smart.connect_data_queue_option 
ADD CONSTRAINT data_queue_option_ca_uuid_fk foreign key (ca_uuid) 
REFERENCES smart.conservation_area(uuid) ON UPDATE restrict ON DELETE cascade DEFERRABLE;

insert into connect.connect_version (version) values ('4.0');

insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart', '4.0.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.intelligence', '4.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.intelligence.query', '2.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.plan', '4.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.cybertracker', '4.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.entity.query', '3.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.entity', '2.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.er', '2.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.er.query', '3.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.connect', '1.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.connect.dataqueue', '1.0');
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.connect.cybertracker', '1.0');

-- the user should configure all of these; running these statements for anything other than
--testing may cause issues with uuids in the future
insert into connect.users (uuid, username, password, email) values ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a36', 'smart', '$2a$12$85fjO64uLvgwaS1WtavLZ.J4OToU8fFo1pQFUlh6EIPVLbFgDffcS', 'smart@smart.com');
insert into connect.user_actions(uuid, username, action) values ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a37', 'smart', 'admin');

insert into connect.alert_types values('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a50', 'Emergency','#80AEFF','#000000','.8','exclamation','orage','f');
insert into connect.alert_types values('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a51', 'Observation','#a0AEFF','#000000','.8','fire','green','f');
insert into connect.alert_types values('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a52', 'Intelligence','#20AE4F','#000000','.8','home','blue','f');
insert into connect.alert_types values('e0eebc99-9c0b-4ef8-bb6d-91b9bd380a53', 'Patrol Position','#305E5F','#000000','.8','eye','red','f');

insert into connect.ca_info values('a0eedf99-9c0c-4ef8-bb6d-6bb9bd340a36','b0efdf99-9c0c-4ee4-bb6d-6bb9bd340a36','test ca 1','NODATA');
insert into connect.alerts values('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a21','mynewalert',to_date('05 Dec 2000', 'DD Mon YYYY'),'test description, some stuffsdfsdr drsdf','c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a51',2,'a0eedf99-9c0c-4ef8-bb6d-6bb9bd340a36','ACTIVE',12,23,'TRACK','a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a36');
insert into connect.map_layers values('c5aabc99-9c0b-4ef8-bf6d-6bb9bd350a80',1,true, 'pk.eyJ1IjoiamVmZmxvdW4iLCJhIjoiOTYyMGFkZDk5ZWM2ZDQ5NDc5Njc2Y2ZlOGM4YjQ1YWIifQ.R715pq8aRAM9hRdGcy10Xg', 'jeffloun.mp3jogfm','','streets',0);
insert into connect.map_layers values('d5aabc99-9c0b-4ef8-bf6d-6bb9bd350a80',2,true, 'bdd66dd4ade33e6b69aed41b64b2b294', '','1084716:canada_major_lakes,1138164:bcschool','Schools and Lakes',1);


UPDATE smart.ca_projection set IS_DEFAULT = 'false' WHERE ca_uuid in (SELECT ca_uuid FROM smart.observation_options);
UPDATE smart.ca_projection set IS_DEFAULT = 'true' WHERE uuid IN (SELECT view_projection_uuid FROM smart.observation_options);
ALTER TABLE smart.observation_options DROP column view_projection_uuid;


--compound query tables
CREATE TABLE smart.compound_query(
	uuid UUID not null, 
	creator_uuid UUID not null, 
	ca_uuid UUID not null, 
	ca_filter varchar(32672), 
	folder_uuid UUID, 
	shared boolean, 
	id varchar(6), 
	primary key (uuid));

CREATE TABLE smart.compound_query_layer(
	uuid UUID not null, 
	compound_query_uuid UUID not null, 
	query_uuid UUID not null, 
	query_type varchar(32), 
	style varchar, 
	layer_order integer not null, 
	date_filter varchar(256), 
	primary key (uuid));
		
ALTER TABLE SMART.COMPOUND_QUERY 
ADD CONSTRAINT COMPOUNDQUERY_CA_UUID_FK 
FOREIGN KEY (CA_UUID) 
REFERENCES SMART.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE SMART.COMPOUND_QUERY 
ADD CONSTRAINT COMPOUNDQUERY_FOLDER_UUID_FK 
FOREIGN KEY (FOLDER_UUID) 
REFERENCES SMART.QUERY_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE SMART.COMPOUND_QUERY 
ADD CONSTRAINT COMPOUNDQUERY_CREATOR_UUID_FK 
FOREIGN KEY (CREATOR_UUID) 
REFERENCES SMART.EMPLOYEE(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE SMART.COMPOUND_QUERY_LAYER 
ADD CONSTRAINT COMPOUNDQUERYLAYER_PARENT_UUID_FK 
FOREIGN KEY (COMPOUND_QUERY_UUID) 
REFERENCES SMART.COMPOUND_QUERY(UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.connect_ct_properties add column data_frequency INTEGER;
ALTER TABLE smart.connect_ct_properties add column ping_type UUID;

ALTER TABLE connect.data_queue DROP CONSTRAINT type_chk;
ALTER TABLE connect.data_queue ADD CONSTRAINT type_chk CHECK (type IN (
'PATROL_XML', 'INCIDENT_XML', 'MISSION_XML', 'INTELL_XML', 'JSON_CT', 'JSON_ZLIB_CT')); 

ALTER TABLE CONNECT.ALERTS ADD CONSTRAINT valid_level CHECK (level > 0 AND level < 6);		

-- Cybertracker patrol data queue plugin
CREATE TABLE smart.ct_patrol_link ( 
	CT_UUID UUID NOT NULL, 
	PATROL_LEG_UUID UUID NOT NULL,
	CT_DEVICE_ID VARCHAR(36) NOT NULL,
	LAST_OBSERVATION_CNT integer,
	GROUP_START_TIME timestamp,
	PRIMARY KEY (CT_UUID)
);

ALTER TABLE smart.ct_patrol_link 
ADD CONSTRAINT patrol_key_uuid_fk 
FOREIGN KEY (patrol_leg_uuid) 
REFERENCES smart.patrol_leg ON DELETE cascade DEFERRABLE;


CREATE TABLE smart.ct_mission_link ( 
	CT_UUID uuid NOT NULL, 
	MISSION_UUID uuid NOT NULL, 
	ct_device_id varchar(36) not null, 
	last_observation_cnt integer, 
	group_start_time timestamp, 
	su_uuid uuid,
PRIMARY KEY (CT_UUID));

ALTER TABLE smart.ct_mission_link 
ADD CONSTRAINT mission_uuid_fk 
FOREIGN KEY (mission_uuid) 
REFERENCES smart.mission ON DELETE cascade DEFERRABLE;
	
ALTER TABLE smart.ct_mission_link 
ADD CONSTRAINT mission_link_su_uuid_fk 
FOREIGN KEY (su_uuid) 
REFERENCES smart.sampling_unit ON DELETE cascade DEFERRABLE;

insert into connect.connect_plugin_version (version, plugin_id) values('1.0', 'org.wcs.smart.connect.dataqueue.cybertracker.patrol');
insert into connect.connect_plugin_version (version, plugin_id) values('1.0', 'org.wcs.smart.connect.dataqueue.cybertracker.survey');

update connect.connect_plugin_version set version = '2.0' where plugin_id = 'org.wcs.smart.connect.cybertracker';
update connect.ca_plugin_version set version = '2.0' where plugin_id = 'org.wcs.smart.connect.cybertracker';

update connect.connect_plugin_version set version = '2.0' where plugin_id = 'org.wcs.smart.connect.dataqueue';
update connect.ca_plugin_version set version = '2.0' where plugin_id = 'org.wcs.smart.connect.dataqueue';
		
update connect.connect_plugin_version set version = '4.0.1' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '4.0.1' where plugin_id = 'org.wcs.smart';


update connect.connect_version set version = '4.0.1';


CREATE TABLE connect.shared_links(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	owner_uuid uuid NOT NULL,
	expires_at timestamp NOT NULL,
	expires_after int NOT NULL,
	url varchar(2083) NOT NULL, --IE's supposed URL max, "no one will ever need more than 2083 characters"
	PRIMARY KEY (uuid)
)WITHOUT OIDS;

ALTER TABLE connect.shared_links ADD CONSTRAINT connect_shared_link_owner_uuid_fk foreign key (owner_uuid) REFERENCES connect.users(uuid) ON UPDATE restrict ON DELETE cascade;
ALTER TABLE connect.shared_links
	ADD FOREIGN KEY (ca_uuid)
	REFERENCES connect.ca_info (ca_uuid)
	ON UPDATE RESTRICT
	ON DELETE CASCADE;

alter table smart.conservation_area add column organization varchar(256);
alter table smart.conservation_area add column pointofcontact varchar(256);
alter table smart.conservation_area add column country varchar(256);
alter table smart.conservation_area add column owner varchar(256);
insert into smart.PATROL_TYPE (CA_UUID, PATROL_TYPE, IS_ACTIVE, MAX_SPEED) 
select DISTINCT CA_UUID, 'MIXED', true, 10000 from smart.PATROL_TYPE;

--update plugin versions
update connect.connect_plugin_version set version = '4.1.0' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '4.1.0' where plugin_id = 'org.wcs.smart';

update connect.connect_version set version = '4.1.0';
ALTER TABLE smart.employee ADD COLUMN usertemp VARCHAR(5000);
UPDATE smart.employee set usertemp = case when smartuserlevel = 0 THEN 'ADMIN' when smartuserlevel = 1 THEN 'DATAENTRY' WHEN smartuserlevel = 2  THEN 'ANALYST' when smartuserlevel=3 THEN 'MANAGER' ELSE null END;
ALTER TABLE smart.employee DROP COLUMN smartuserlevel;
ALTER TABLE smart.employee ADD COLUMN smartuserlevel VARCHAR(5000);
UPDATE smart.employee SET smartuserlevel = usertemp;
ALTER TABLE smart.employee DROP COLUMN usertemp;

alter table smart.CONFIGURABLE_MODEL ADD COLUMN instant_gps BOOLEAN;
alter table smart.CONFIGURABLE_MODEL ADD COLUMN photo_first BOOLEAN;

alter table connect.shared_links ADD COLUMN is_user_token BOOLEAN NOT NULL DEFAULT FALSE;
alter table connect.shared_links ADD COLUMN allowed_ip VARCHAR(24);
alter table connect.shared_links ADD COLUMN date_created timestamp NOT Null DEFAULT now();
ALTER TABLE connect.shared_links ALTER COLUMN url DROP NOT null;

CREATE OR REPLACE FUNCTION smart.trackIntersects(geom1 bytea, geom2 bytea) RETURNS BOOLEAN AS $$
DECLARE
  ls geometry;
  pnt geometry;
BEGIN
	ls := st_geomfromwkb(geom1);
	if not st_isvalid(ls) and st_length(ls) = 0 then
		pnt = st_pointn(ls, 1);
		return smart.pointinpolygon(st_x(pnt),st_y(pnt),geom2);
	else
		RETURN ST_INTERSECTS(ls, st_geomfromwkb(geom2));
	end if;

END;
$$LANGUAGE plpgsql;


--Below are all the tables to support new intelligence plugin
CREATE TABLE smart.i_attachment
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	date_created timestamp NOT NULL,
	created_by uuid NOT NULL,
	description varchar(2048),
	filename varchar(1024) NOT NULL,
	PRIMARY KEY (uuid)
);
	
CREATE TABLE smart.i_attribute
(
	uuid uuid NOT NULL,
	keyid varchar(128) NOT NULL,
	type char(8) NOT NULL,
	ca_uuid uuid NOT NULL,
	PRIMARY KEY (uuid)
);
	
CREATE TABLE smart.i_attribute_list_item
(
	uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	keyid varchar(128) NOT NULL,
	PRIMARY KEY (uuid)
);
	
CREATE TABLE smart.i_entity
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	date_created timestamp NOT NULL,
	date_modified timestamp,
	created_by uuid NOT NULL,
	last_modified_by uuid,
	primary_attachment_uuid uuid,
	entity_type_uuid uuid NOT NULL,
	comment varchar,
	PRIMARY KEY (uuid)
);
	
CREATE TABLE smart.i_entity_attachment
(
	entity_uuid uuid NOT NULL,
	attachment_uuid uuid NOT NULL,
	PRIMARY KEY (entity_uuid, attachment_uuid)
);
 	
CREATE TABLE smart.i_entity_attribute_value
(
	entity_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	string_value varchar(1024),
	double_value double precision,
	double_value2 double precision,
	list_item_uuid uuid,
	metaphone varchar(32600),
 	PRIMARY KEY (entity_uuid, attribute_uuid)
);

CREATE TABLE smart.i_entity_location
(
	entity_uuid uuid NOT NULL,
	location_uuid uuid NOT NULL,
	PRIMARY KEY (entity_uuid,location_uuid)
);

CREATE TABLE smart.i_entity_record
(
	entity_uuid uuid NOT NULL,
	record_uuid uuid NOT NULL,
	PRIMARY KEY (entity_uuid,record_uuid)
);

CREATE TABLE smart.i_entity_relationship
(
	uuid uuid NOT NULL,
	src_entity_uuid uuid NOT NULL,
	relationship_type_uuid uuid NOT NULL,
	target_entity_uuid uuid NOT NULL,
	source varchar(16) not null,
	source_uuid uuid,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_entity_relationship_attribute_value
(
	entity_relationship_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	string_value varchar(1024),
	double_value double precision,
	double_value2 double precision,
	list_item_uuid uuid,
	PRIMARY KEY (entity_relationship_uuid,attribute_uuid)
);

CREATE TABLE smart.i_entity_search(
	uuid uuid NOT NULL,
	search_string varchar,
	ca_uuid uuid NOT NULL,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_entity_type(
	uuid uuid NOT NULL,
	keyid varchar(128) NOT NULL,
	ca_uuid uuid NOT NULL,
	id_attribute_uuid uuid NOT NULL,
	icon bytea,
	birt_template varchar(4096),
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_entity_type_attribute
(
	entity_type_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	attribute_group_uuid uuid,
	seq_order integer not null,
	PRIMARY KEY (entity_type_uuid, attribute_uuid)
);

CREATE TABLE smart.i_entity_type_attribute_group
(
	uuid uuid NOT NULL,
	entity_type_uuid uuid not null,
	seq_order integer not null,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_location
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	geometry bytea NOT NULL,
	datetime timestamp,
	comment varchar(4096),
	id varchar(1028),
	record_uuid uuid,
	PRIMARY KEY (uuid)
);
CREATE TABLE smart.i_observation
(
	uuid uuid NOT NULL,
	location_uuid uuid NOT NULL,
	category_uuid uuid ,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_observation_attribute
(
	observation_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	list_element_uuid uuid,
	tree_node_uuid uuid,
	string_value varchar(1024),
	double_value double precision,
	PRIMARY KEY (observation_uuid, attribute_uuid)
);

CREATE TABLE smart.i_record
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	source_uuid uuid,
	title varchar(1024) NOT NULL,
	date_created timestamp NOT NULL,
	last_modified_date timestamp,
	created_by uuid NOT NULL,
	last_modified_by uuid,
	date_exported timestamp,
	status varchar(16) NOT NULL,
	description varchar,
	comment varchar,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_record_attachment
(
	record_uuid uuid NOT NULL,
	attachment_uuid uuid NOT NULL,
	PRIMARY KEY (record_uuid, attachment_uuid)
);

CREATE TABLE smart.i_record_obs_query
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	style varchar,
	query_string varchar,
	column_filter varchar,
	date_created timestamp NOT NULL,
	last_modified_date timestamp,
	created_by uuid NOT NULL,
	last_modified_by uuid,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_relationship_type_attribute
(
	relationship_type_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	seq_order integer not null,
	PRIMARY KEY (relationship_type_uuid, attribute_uuid)
);

CREATE TABLE smart.i_relationship_group
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	keyid varchar(128) NOT NULL,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_relationship_type
(
	uuid uuid NOT NULL,
	keyid varchar(128) NOT NULL,
	ca_uuid uuid NOT NULL,
	icon bytea,
	relationship_group_uuid uuid,
	src_entity_type uuid,
	target_entity_type uuid,
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_working_set
(
	uuid uuid NOT NULL,
	ca_uuid uuid NOT NULL,
	date_created timestamp NOT NULL,
	last_modified_date timestamp,
	created_by uuid NOT NULL,
	last_modified_by uuid,
	entity_date_filter varchar(1024),
	PRIMARY KEY (uuid)
);

CREATE TABLE smart.i_working_set_entity
(
	working_set_uuid uuid NOT NULL,
	entity_uuid uuid NOT NULL,
	map_style varchar,
	is_visible boolean not null default true,
	PRIMARY KEY (working_set_uuid, entity_uuid)
);

CREATE TABLE smart.i_working_set_query
(
	working_set_uuid uuid NOT NULL,
	query_uuid uuid NOT NULL,
	date_filter varchar(1024),
	map_style varchar,
	is_visible boolean not null default true,
	PRIMARY KEY (working_set_uuid, query_uuid)
);

CREATE TABLE smart.i_working_set_record
(
	working_set_uuid uuid NOT NULL,
	record_uuid uuid NOT NULL,
	map_style varchar,
	is_visible boolean not null default true,
	PRIMARY KEY (working_set_uuid, record_uuid)
);

CREATE TABLE smart.i_record_attribute_value
(
	uuid uuid NOT NULL,
	record_uuid uuid NOT NULL,
	attribute_uuid uuid NOT NULL,
	string_value varchar(1024),
	double_value double precision,
	double_value2 double precision,
	PRIMARY KEY (uuid),
	UNIQUE(record_uuid, attribute_uuid)
);
 
CREATE TABLE smart.i_record_attribute_value_list
(
	value_uuid uuid not null,
	element_uuid uuid not null,
	primary key (value_uuid, element_uuid)
);

CREATE TABLE smart.i_recordsource_attribute
(
	uuid uuid,
	source_uuid uuid NOT NULL,
	attribute_uuid uuid,
	entity_type_uuid uuid,
	seq_order integer,
	is_multi boolean,
	PRIMARY KEY(uuid),
	UNIQUE (source_uuid, attribute_uuid, entity_type_uuid)
);

CREATE TABLE smart.i_recordsource 
(
	uuid uuid not null,
	ca_uuid uuid not null,
	keyid varchar(128) not null,
	icon bytea,
	PRIMARY KEY (uuid)
);


--FOREIGN KEYs

ALTER TABLE smart.i_location 
ADD CONSTRAINT ilocation_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_location 
ADD CONSTRAINT location_recorduuid_fk 
FOREIGN KEY (record_uuid) 
REFERENCES smart.i_record (uuid) ON DELETE CASCADE DEFERRABLE ;

ALTER TABLE smart.i_entity_search 
ADD CONSTRAINT ientitysearch_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE ;

ALTER TABLE smart.i_attribute 
ADD CONSTRAINT iattribute_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE; 

ALTER TABLE smart.i_record 
ADD CONSTRAINT irecord_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record 
ADD CONSTRAINT irecord_createdby_fk 
FOREIGN KEY (created_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record 
ADD CONSTRAINT irecord_modifiedby_fk 
FOREIGN KEY (lasT_modified_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type 
ADD CONSTRAINT ientitytype_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type 
ADD CONSTRAINT ientitytype_idattributeuuid_fk 
FOREIGN KEY (id_attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_attachment 
ADD CONSTRAINT iattachment_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_attachment 
ADD CONSTRAINT iattachment_createdby_fk 
FOREIGN KEY (created_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_relationship_type 
ADD CONSTRAINT irelationshiptype_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set 
ADD CONSTRAINT iworkingset_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set 
ADD CONSTRAINT iworkingset_createdby_fk 
FOREIGN KEY (created_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set 
ADD CONSTRAINT iworkingset_lastmodifiedby_fk 
FOREIGN KEY (last_modified_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity 
ADD CONSTRAINT ientity_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_obs_query 
ADD CONSTRAINT irecordquery_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_obs_query 
ADD CONSTRAINT irecordquery_createdby_fk 
FOREIGN KEY (created_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_obs_query 
ADD CONSTRAINT irecordquery_modifiedby_fk 
FOREIGN KEY (last_modified_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_observation_attribute 
ADD CONSTRAINT iobservationattribute_attributeuuid_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.DM_ATTRIBUTE (UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_observation_attribute 
ADD CONSTRAINT iobservationattribute_list_fk 
FOREIGN KEY (list_element_uuid) 
REFERENCES smart.DM_ATTRIBUTE_LIST (UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_observation_attribute 
ADD CONSTRAINT iobservationattribute_tree_fk 
FOREIGN KEY (tree_node_uuid) 
REFERENCES smart.DM_ATTRIBUTE_TREE (UUID) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_attachment 
ADD CONSTRAINT irecordattachment_attchment_fk 
FOREIGN KEY (attachment_uuid) 
REFERENCES smart.i_attachment (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_attachment 
ADD CONSTRAINT ientityattachment_attchment_fk 
FOREIGN KEY (attachment_uuid) 
REFERENCES smart.i_attachment (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_attribute_value 
ADD CONSTRAINT ientityattribute_attribute_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_attribute_list_item 
ADD CONSTRAINT iattributelist_attribute_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_relationship_type_attribute 
ADD CONSTRAINT irelationshipattribute_attribute_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type_attribute 
ADD CONSTRAINT ientitytypeattribute_attribute_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type_attribute 
ADD CONSTRAINT iattributegroupuuid_fk 
FOREIGN KEY (attribute_group_uuid) 
REFERENCES smart.i_entity_type_attribute_group (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type_attribute_group 
ADD CONSTRAINT ientitytypeattributegroupentitytypeuuid_fk 
FOREIGN KEY (entity_type_uuid) 
REFERENCES smart.i_entity_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship_attribute_value 
ADD CONSTRAINT ientityrelationshipattribute_attribute_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship_attribute_value 
ADD CONSTRAINT ientityrelationshipattribute_list_fk 
FOREIGN KEY (list_item_uuid) 
REFERENCES smart.i_attribute_list_item (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_attribute_value 
ADD CONSTRAINT ientityattributevalue_list_fk 
FOREIGN KEY (list_item_uuid) 
REFERENCES smart.i_attribute_list_item (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship 
ADD CONSTRAINT ientityrelationship_srcentity_fk 
FOREIGN KEY (src_entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship 
ADD CONSTRAINT ientityrelationship_targetentity_fk 
FOREIGN KEY (target_entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_record 
ADD CONSTRAINT ientityrecord_entity_fk 
FOREIGN KEY (entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_entity 
ADD CONSTRAINT iworkingsetentity_entity_fk 
FOREIGN KEY (entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_attribute_value 
ADD CONSTRAINT ientityattributevalue_entity_fk 
FOREIGN KEY (entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_attachment 
ADD CONSTRAINT ientityattachment_entity_fk 
FOREIGN KEY (entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_location 
ADD CONSTRAINT ientitylocation_entity_fk 
FOREIGN KEY (entity_uuid) 
REFERENCES smart.i_entity (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship_attribute_value 
ADD CONSTRAINT ientityrelationshipattribute_entityrelationship_fk 
FOREIGN KEY (entity_relationship_uuid) 
REFERENCES smart.i_entity_relationship (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_type_attribute 
ADD CONSTRAINT ientitytypeattribute_entitytype_fk 
FOREIGN KEY (entity_type_uuid) 
REFERENCES smart.i_entity_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity 
ADD CONSTRAINT ientity_entitytype_fk 
FOREIGN KEY (entity_type_uuid) 
REFERENCES smart.i_entity_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity 
ADD CONSTRAINT ientity_createdby_fk 
FOREIGN KEY (created_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity 
ADD CONSTRAINT ientity_lastmodifiedby_fk 
FOREIGN KEY (last_modified_by) 
REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_location 
ADD CONSTRAINT ientitylocation_location_fk 
FOREIGN KEY (location_uuid) 
REFERENCES smart.i_location (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_observation 
ADD CONSTRAINT iobservation_location_fk 
FOREIGN KEY (location_uuid) 
REFERENCES smart.i_location (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_observation 
ADD CONSTRAINT iobservation_category_fk 
FOREIGN KEY (category_uuid) 
REFERENCES smart.dm_category (uuid) ON DELETE CASCADE DEFERRABLE; 

ALTER TABLE smart.i_observation_attribute 
ADD CONSTRAINT iobservationattribute_observation_fk 
FOREIGN KEY (observation_uuid) 
REFERENCES smart.i_observation (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_record 
ADD CONSTRAINT ientityrecord_record_fk 
FOREIGN KEY (record_uuid) 
REFERENCES smart.i_record (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_record 
ADD CONSTRAINT iworkingsetrecord_record_fk 
FOREIGN KEY (record_uuid) 
REFERENCES smart.i_record (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_attachment 
ADD CONSTRAINT irecordattachment_record_fk 
FOREIGN KEY (record_uuid) 
REFERENCES smart.i_record (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_query 
ADD CONSTRAINT iworkingsetquery_query_fk 
FOREIGN KEY (query_uuid) 
REFERENCES smart.i_record_obs_query (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_relationship_type 
ADD CONSTRAINT irelationshiptype_group_fk 
FOREIGN KEY (relationship_group_uuid) 
REFERENCES smart.i_relationship_group (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_relationship_type_attribute 
ADD CONSTRAINT irelationshipattribute_type_fk 
FOREIGN KEY (relationship_type_uuid) 
REFERENCES smart.i_relationship_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.I_RELATIONSHIP_TYPE 
ADD CONSTRAINT I_RELATIONSHIP_TYPE_SRC_TYPE_FK  
FOREIGN KEY (src_entity_type) 
REFERENCES smart.I_ENTITY_TYPE(uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.I_RELATIONSHIP_TYPE 
ADD CONSTRAINT I_RELATIONSHIP_TYPE_TRG_TYPE_FK  
FOREIGN KEY (target_entity_type) 
REFERENCES smart.I_ENTITY_TYPE(uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_entity_relationship 
ADD CONSTRAINT ientityrelationship_type_fk 
FOREIGN KEY (relationship_type_uuid) 
REFERENCES smart.i_relationship_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_query 
ADD CONSTRAINT iworkingsetquery_workingset_fk 
FOREIGN KEY (working_set_uuid) 
REFERENCES smart.i_working_set (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_record 
ADD CONSTRAINT iworkingsetrecord_workingset_fk 
FOREIGN KEY (working_set_uuid) 
REFERENCES smart.i_working_set (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_working_set_entity 
ADD CONSTRAINT iworkginsetentity_workingset_fk 
FOREIGN KEY (working_set_uuid) 
REFERENCES smart.i_working_set (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_relationship_group 
ADD CONSTRAINT relationshipgroup_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_recordsource 
ADD CONSTRAINT irecordsource_cauuid_fk 
FOREIGN KEY (ca_uuid) 
REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_recordsource_attribute 
ADD CONSTRAINT irecordsourceattribute_sourceuuid_fk 
FOREIGN KEY (source_uuid) 
REFERENCES smart.i_recordsource (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_recordsource_attribute 
ADD CONSTRAINT irecordsourceattribute_attributeuuid_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_recordsource_attribute 
ADD CONSTRAINT irecordsourceattribute_entitytypeuuid_fk 
FOREIGN KEY (entity_type_uuid) 
REFERENCES smart.i_entity_type (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_attribute_value 
ADD CONSTRAINT irecordattvalue_sourceuuid_fk 
FOREIGN KEY (record_uuid) 
REFERENCES smart.i_record (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_attribute_value 
ADD CONSTRAINT irecordattvalue_attributeuuid_fk 
FOREIGN KEY (attribute_uuid) 
REFERENCES smart.i_recordsource_attribute (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record 
ADD CONSTRAINT irecord_sourceuuid_fk 
FOREIGN KEY (source_uuid) 
REFERENCES smart.i_recordsource (uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE smart.i_record_attribute_value_list 
ADD CONSTRAINT i_recordattributelist_valueuuid_fk 
FOREIGN KEY (value_uuid) 
REFERENCES smart.i_record_attribute_value (uuid) ON DELETE CASCADE DEFERRABLE;


--Update Sharedlinks to allow for longer URLS
Alter table connect.shared_links alter column url type varchar(262143);


--Tables to Support Quicklinks and DashBoards 

CREATE TABLE connect.dashboards
(
	uuid uuid not null,
	label varchar(256),
	report_uuid_1 uuid,
	report_uuid_2 uuid,
	date_range1 int not null,
	date_range2 int not null,
	custom_date1_from text,
	custom_date1_to text,
	custom_date2_from text,
	custom_date2_to text,
	report_parameterlist_1 text,
	report_parameterlist_2 text,
	PRIMARY KEY (uuid)
);

CREATE TABLE connect.users_default_dashboard 
(
	user_uuid uuid not null,
	dashboard_uuid uuid not null,
	date_range1 int not null,
	date_range2 int not null,
	custom_date1_from text,
	custom_date1_to text,
	custom_date2_from text,
	custom_date2_to text,
	PRIMARY KEY (user_uuid)
);

ALTER TABLE connect.users_default_dashboard
ADD CONSTRAINT default_dashboard_user_fk
FOREIGN KEY (user_uuid) 
REFERENCES connect.users(uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE connect.users_default_dashboard
ADD CONSTRAINT default_dashboard_dashboard_fk
FOREIGN KEY (dashboard_uuid) 
REFERENCES connect.dashboards(uuid) ON DELETE CASCADE DEFERRABLE;


CREATE TABLE connect.quicklinks
(
	uuid uuid not null,
	url text not null,
	label varchar(256),
	created_on timestamp not null,
	created_by_user_uuid uuid not null,
	is_admin_created boolean not null,
	PRIMARY KEY (uuid)
);

ALTER TABLE connect.quicklinks
ADD CONSTRAINT quicklink_user_fk
FOREIGN KEY (created_by_user_uuid) 
REFERENCES connect.users(uuid) ON DELETE CASCADE DEFERRABLE;


CREATE TABLE connect.user_quicklinks 
(
	uuid uuid not null,
	user_uuid uuid not null,
	quicklink_uuid uuid not null,
	label_override varchar(256),
	link_order int,
	PRIMARY KEY (uuid)
);

ALTER TABLE connect.user_quicklinks
ADD CONSTRAINT quicklink_user_fk
FOREIGN KEY (user_uuid) 
REFERENCES connect.users(uuid) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE connect.user_quicklinks
ADD CONSTRAINT userquicklink_quicklink_fk
FOREIGN KEY (quicklink_uuid) 
REFERENCES connect.quicklinks(uuid) ON DELETE CASCADE DEFERRABLE;

-- UPDATES TO SUPPORT DISABLING QUERY COLUMNS
ALTER TABLE smart.observation_query ADD COLUMN show_data_columns_only BOOLEAN;
ALTER TABLE smart.obs_observation_query ADD COLUMN show_data_columns_only BOOLEAN;
ALTER TABLE smart.survey_observation_query ADD COLUMN show_data_columns_only BOOLEAN;
ALTER TABLE smart.entity_observation_query ADD COLUMN show_data_columns_only BOOLEAN;


-- UPDATES TO VERSIONS

INSERT INTO connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.i2', '1.0');

UPDATE connect.connect_plugin_version SET version = '4.0' WHERE plugin_id = 'org.wcs.smart.entity.query';
UPDATE connect.connect_plugin_version SET version = '4.0' WHERE plugin_id = 'org.wcs.smart.er.query';
UPDATE connect.ca_plugin_version SET version = '4.0' WHERE plugin_id = 'org.wcs.smart.entity.query';
UPDATE connect.ca_plugin_version SET version = '4.0' WHERE plugin_id = 'org.wcs.smart.er.query';

update connect.connect_plugin_version set version = '5.0.0' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '5.0.0' where plugin_id = 'org.wcs.smart';
update connect.connect_version set version = '5.0.0';

--schema creation was accidentally left out of -> 5.0.0 sql script. Drop it if it already exists and add it.
DROP SCHEMA If exists query_temp CASCADE;
CREATE SCHEMA query_temp;

alter table connect.shared_links drop column expires_after;
alter table connect.shared_links ALTER COLUMN ca_uuid DROP NOT null;

update connect.connect_version set version = '5.0.1';
CREATE OR REPLACE FUNCTION smart.computeHoursPoly(polygon bytea, linestring bytea) RETURNS double precision AS $$
DECLARE
  ls geometry;
  p geometry;
  value double precision;
  ctime double precision;
  clength double precision;
  i integer;
  pnttemp geometry;
  pnttemp2 geometry;
  lstemp geometry;
BEGIN
	ls := st_geomfromwkb(linestring);
	p := st_geomfromwkb(polygon);
	
	--wholly contained use entire time
	IF not st_isvalid(ls) and st_length(ls) = 0 THEN
		pnttemp = st_pointn(ls, 1);
		IF (smart.pointinpolygon(st_x(pnttemp),st_y(pnttemp), p)) THEN
			RETURN (st_z(st_endpoint(ls)) - st_z(st_startpoint(ls))) / 3600000.0;
		END IF;
		RETURN 0;
	END IF;
	
	IF (st_contains(p, ls)) THEN
		return (st_z(st_endpoint(ls)) - st_z(st_startpoint(ls))) / 3600000.0;
	END IF;
	
	value := 0;
	FOR i in 1..ST_NumPoints(ls)-1 LOOP
		pnttemp := st_pointn(ls, i);
		pnttemp2 := st_pointn(ls, i+1);
		lstemp := st_makeline(pnttemp, pnttemp2);	
		IF (NOT st_intersects(st_envelope(ls), st_envelope(lstemp))) THEN
			--do nothing; outside envelope
		ELSE
			IF (ST_COVERS(p, lstemp)) THEN
				value := value + st_z(pnttemp2) - st_z(pnttemp);
			ELSIF (ST_INTERSECTS(p, lstemp)) THEN
				ctime := st_z(pnttemp2) - st_z(pnttemp);
				clength := st_distance(pnttemp, pnttemp2);
				IF (clength = 0) THEN
					--points are the same and intersect so include the entire time
					value := value + ctime;
				ELSE
					--part in part out so linearly interpolate
					value := value + (ctime * (st_length(st_intersection(p, lstemp)) / clength));
				END IF;
			END IF;
		END IF;
	END LOOP;
	RETURN value / 3600000.0;
END;
$$LANGUAGE plpgsql;


update connect.connect_version set version = '5.0.3';
ALTER TABLE connect.users add column home_ca_uuid UUID;

ALTER TABLE connect.alert_types ADD COLUMN custom_icon varchar(2);

ALTER TABLE smart.patrol_leg ADD COLUMN mandate_uuid UUID;

UPDATE smart.patrol_leg SET mandate_uuid = (SELECT p.mandate_uuid FROM smart.patrol p WHERE p.uuid = smart.patrol_leg.patrol_uuid);

ALTER TABLE SMART.PATROL_LEG 
ADD CONSTRAINT MANDATE_UUID_FK FOREIGN KEY (MANDATE_UUID) REFERENCES SMART.PATROL_MANDATE(UUID)  
ON DELETE RESTRICT ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE smart.patrol DROP COLUMN mandate_uuid;

ALTER TABLE connect.data_queue DROP CONSTRAINT type_chk;


CREATE OR REPLACE FUNCTION smart.hkeylength(hkey varchar) RETURNS integer AS $$
BEGIN
	RETURN length(hkey) - length(replace(hkey, '.', '')) - 1;

END;
$$LANGUAGE plpgsql;

ALTER TABLE connect.users ALTER COLUMN username TYPE varchar(256);

--changes to map layers table and removing all non-wms map layers
delete from connect.map_layers where layer_type != 3;
alter table connect.map_layers add column layer_type_tmp varchar(16);
update connect.map_layers set layer_type_tmp = 'WMS';
alter table connect.map_layers alter column layer_type_tmp set not null;
alter table connect.map_layers drop column layer_type;
alter table connect.map_layers rename column layer_type_tmp to layer_type;
alter table connect.map_layers add constraint type_chk check (layer_type in ('WMS'));
alter table connect.map_layers add primary key (uuid);
alter table connect.map_layers drop column mapboxid;

--unique user id constraint
ALTER TABLE smart.employee ADD CONSTRAINT smartuseridunq UNIQUE(ca_uuid, smartuserid);
 
--agency key ids
ALTER table smart.agency add column keyid varchar(128);
 
UPDATE smart.agency SET keyId = lower(regexp_replace(a.value, '[^a-zA-Z0-9]', '', 'g')) 
from smart.i18n_label a, smart.language b 
where b.uuid = a.language_uuid and a.element_uuid = smart.agency.uuid and b.isdefault;

UPDATE smart.agency SET keyId = cast(uuid as varchar) where keyId is null or trim(keyId) = '';
 
--ensure unique keys by using uuids
 update smart.agency
 set keyId = keyId || replace(cast(uuid as varchar), '-', '')  WHERE uuid IN (
 select uuid from smart.agency a, 
 (select ca_uuid, keyid from smart.agency group by ca_uuid, keyid having count(*) > 1) b
 WHERE a.ca_uuid = b.ca_uuid and a.keyid = b.keyid
 );

ALTER TABLE smart.agency ADD CONSTRAINT keyunq UNIQUE (keyid, ca_uuid);
 

-- Update to intelligence/profiles plugin
CREATE TABLE smart.i_entity_summary_query(
  uuid uuid NOT NULL,
  ca_uuid uuid NOT NULL,
  query_string varchar,
  date_created timestamp NOT NULL
  ,last_modified_date timestamp,
  created_by uuid NOT NULL,
  last_modified_by uuid,
  PRIMARY KEY (uuid));
  
  
ALTER TABLE smart.i_entity_summary_query ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_entity_summary_query ADD FOREIGN KEY (created_by) REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_entity_summary_query ADD FOREIGN KEY (last_modified_by) REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE smart.i_entity_record_query(
  uuid uuid NOT NULL,
  ca_uuid uuid NOT NULL,
  query_string varchar,
  date_created timestamp NOT NULL
  ,last_modified_date timestamp,
  created_by uuid NOT NULL,
  last_modified_by uuid,
  PRIMARY KEY (uuid));
  
  
ALTER TABLE smart.i_entity_record_query ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_entity_record_query ADD FOREIGN KEY (created_by) REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_entity_record_query ADD FOREIGN KEY (last_modified_by) REFERENCES smart.employee (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

alter table smart.i_working_set_query drop constraint iworkingsetquery_query_fk;
ALTER TABLE smart.I_WORKING_SET_QUERY add column query_type varchar(32);
UPDATE smart.i_working_set_query set query_type = 'I2_OBS_QUERY';
ALTER TABLE smart.i_working_set_query alter column query_type set not null;


CREATE TABLE smart.i_diagram_style (
  uuid UUID NOT NULL, 
  ca_uuid UUID NOT NULL, 
  IS_DEFAULT BOOLEAN, 
  OPTIONS VARCHAR(2048), 
  PRIMARY KEY (UUID)
);

ALTER TABLE smart.i_diagram_style ADD FOREIGN KEY (CA_UUID) REFERENCES SMART.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
		

CREATE TABLE smart.i_diagram_entity_type_style (
  uuid UUID NOT NULL, 
  style_uuid UUID NOT NULL, 
  entity_type_uuid UUID NOT NULL, 
  OPTIONS VARCHAR(1024), 
  PRIMARY KEY (UUID)
);
ALTER TABLE smart.i_diagram_entity_type_style ADD FOREIGN KEY (STYLE_UUID) REFERENCES SMART.I_DIAGRAM_STYLE(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_diagram_entity_type_style ADD FOREIGN KEY (ENTITY_TYPE_UUID) REFERENCES SMART.I_ENTITY_TYPE(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
			
CREATE TABLE smart.i_diagram_relationship_type_style (
  uuid UUID NOT NULL, 
  style_uuid UUID NOT NULL, 
  relationship_type_uuid UUID NOT NULL, 
  OPTIONS VARCHAR(1024), 
  PRIMARY KEY (UUID)
);
			
ALTER TABLE smart.i_diagram_relationship_type_style ADD FOREIGN KEY (STYLE_UUID) REFERENCES SMART.I_DIAGRAM_STYLE(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_diagram_relationship_type_style ADD FOREIGN KEY (RELATIONSHIP_TYPE_UUID) REFERENCES SMART.I_RELATIONSHIP_TYPE(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


-- QA Plugin

insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.qa', '1.0');
insert into connect.ca_plugin_version (ca_uuid, plugin_id, version) select uuid, 'org.wcs.smart.qa', '1.0' from smart.conservation_area;

CREATE TABLE smart.qa_error( 
  uuid UUID NOT NULL, 
  ca_uuid UUID not null, 
  qa_routine_uuid UUID NOT NULL, 
  data_provider_id varchar(128) not null, 
  status varchar(32) NOT NULL, 
  validate_date timestamp NOT NULL, 
  error_id varchar(1024) NOT NULL, 
  error_description varchar(32600), 
  fix_message varchar(32600), 
  src_identifier UUID NOT NULL, 
  geometry bytea, 
  PRIMARY KEY (uuid)
);

CREATE TABLE smart.qa_routine(
  uuid UUID NOT NULL, 
  ca_uuid UUID NOT NULL, 
  routine_type_id varchar(1024) NOT NULL, 
  description varchar(32600), 
  auto_check boolean DEFAULT false NOT NULL, 
  PRIMARY KEY (uuid)
);

CREATE TABLE smart.qa_routine_parameter( 
  uuid UUID NOT NULL, 
  qa_routine_uuid UUID NOT NULL, 
  id varchar(256) NOT NULL, 
  str_value varchar(32600), 
  byte_value bytea, 
  PRIMARY KEY (uuid, qa_routine_uuid)
);

ALTER TABLE smart.qa_routine ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.qa_error ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.qa_routine_parameter ADD FOREIGN KEY (qa_routine_uuid) REFERENCES smart.qa_routine (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.qa_error ADD FOREIGN KEY (qa_routine_uuid) REFERENCES smart.qa_routine (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



-- UPGRADE CONFIGURABLE MODEL CONFIGURATIONS
-- SEE UpgradeServlet.java for full Configurable Model update code
--create new tables
CREATE TABLE smart.cm_attribute_config(uuid UUID not null, cm_uuid UUID not null, dm_attribute_uuid UUID not null, display_mode varchar(10), is_default boolean, primary key (uuid));
ALTER TABLE smart.cm_attribute_config ADD FOREIGN KEY (CM_UUID) REFERENCES SMART.CONFIGURABLE_MODEL(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.cm_attribute_config ADD FOREIGN KEY (DM_ATTRIBUTE_UUID) REFERENCES SMART.DM_ATTRIBUTE(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

alter table smart.cm_attribute add column config_uuid UUID;
ALTER TABLE smart.cm_attribute ADD FOREIGN KEY (CONFIG_UUID) REFERENCES SMART.CM_ATTRIBUTE_CONFIG(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
alter table smart.cm_attribute_list add column config_uuid UUID;
ALTER TABLE SMART.CM_ATTRIBUTE_LIST ADD FOREIGN KEY (CONFIG_UUID) REFERENCES SMART.CM_ATTRIBUTE_CONFIG(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ; 
alter table smart.cm_attribute_tree_node add column config_uuid UUID;
ALTER TABLE SMART.CM_ATTRIBUTE_TREE_NODE ADD FOREIGN KEY (CONFIG_UUID) REFERENCES SMART.CM_ATTRIBUTE_CONFIG(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

-- the following run in the upgradeservlet code
--drop table SMART.CM_DM_ATTRIBUTE_SETTINGS;
--alter table smart.cm_attribute_list drop column CM_ATTRIBUTE_UUID;
--alter table smart.cm_attribute_list drop column DM_ATTRIBUTE_UUID;
--alter table smart.cm_attribute_list drop column CM_UUID;
--alter table smart.cm_attribute_list alter column config_uuid SET NOT NULL;

--alter table smart.cm_attribute_tree_node drop column CM_ATTRIBUTE_UUID;
--alter table smart.cm_attribute_tree_node drop column DM_ATTRIBUTE_UUID;
--alter table smart.cm_attribute_tree_node drop column CM_UUID;
--alter table smart.cm_attribute_tree_node alter column config_uuid SET NOT NULL;

--delete from smart.CM_ATTRIBUTE_OPTION where OPTION_ID = 'DISPLAY_MODE' OR OPTION_ID = 'CUSTOM_CONFIG';
---- END OF SECTION


--i2 UPDATES
alter table smart.i_record ADD COLUMN primary_date timestamp;
update smart.i_record set primary_date = (select a.maxdatetime from (select record_uuid, max(datetime) as maxdatetime from smart.I_LOCATION group by record_uuid) a where a.record_uuid = smart.i_record.uuid );
update smart.i_record set primary_date = date_created where primary_date is null;
alter table smart.i_record ALTER COLUMN primary_date SET NOT NULL;

UPDATE connect.connect_plugin_version SET version = '2.0' WHERE plugin_id = 'org.wcs.smart.i2';
UPDATE connect.ca_plugin_version SET version = '2.0' WHERE plugin_id = 'org.wcs.smart.i2';


CREATE OR REPLACE FUNCTION smart.metaphoneContains(metaphone varchar(4), searchstring varchar) RETURNS boolean AS $$
DECLARE
	part varchar;
BEGIN
	IF (metaphone IS NULL OR searchstring IS NULL) THEN RETURN false; END IF;
	FOREACH PART IN ARRAY string_to_array(searchstring, ' ')
	LOOP
    		IF (metaphone = part) THEN RETURN TRUE; END IF;
	END LOOP;
	RETURN FALSE;
END;
$$LANGUAGE plpgsql;

create table smart.i_config_option (
  uuid uuid, 
  ca_uuid uuid not null,
  keyid varchar(32000) not null, 
  value varchar(32000), 
  unique(ca_uuid, keyid),
  primary key (uuid));

ALTER TABLE SMART.i_config_option ADD FOREIGN KEY (ca_uuid) REFERENCES SMART.conservation_area(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

 ALTER TABLE smart.i_attribute_list_item add column list_order integer not null default 0;
 
-- EVENTS
CREATE TABLE smart.e_event_filter(
  uuid UUID not null, 
  ca_uuid UUID not null, 
  id varchar(128) not null, 
  filter_string varchar(32000) not null, 
PRIMARY KEY(uuid));

ALTER TABLE smart.e_event_filter ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

CREATE TABLE smart.e_action( 
  uuid UUID not null, 
  ca_uuid UUID not null, 
  id varchar(128) not null, 
  type_key varchar(128) not null, 
  PRIMARY KEY (uuid));

ALTER TABLE smart.e_action ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

CREATE TABLE smart.e_action_parameter_value( 
  action_uuid UUID not null, 
  parameter_key varchar(128)  not null, 
  parameter_value varchar(4096) not null, 
  PRIMARY KEY (action_uuid, parameter_key));
  
ALTER TABLE smart.e_action_parameter_value ADD FOREIGN KEY (action_uuid) REFERENCES smart.e_action(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;


CREATE TABLE smart.e_event_action(
  uuid UUID not null, 
  filter_uuid UUID not null, 
  action_uuid UUID not null, 
  is_enabled boolean not null default true, 
  PRIMARY KEY (uuid) );
  
ALTER TABLE smart.e_event_action ADD FOREIGN KEY (action_uuid) REFERENCES smart.e_action(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
ALTER TABLE smart.e_event_action ADD FOREIGN KEY (filter_uuid) REFERENCES smart.e_event_filter(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

INSERT INTO connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.event', '1.0');



 -- TRIGGERS FOR CHANGELOG

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TRIGGER IF EXISTS trg_query_folder ON smart.query_folder;                                                                                  
DROP TRIGGER IF EXISTS trg_report ON smart.report;                                                                                              
DROP TRIGGER IF EXISTS trg_report_folder ON smart.report_folder;                                                                                
DROP TRIGGER IF EXISTS trg_saved_maps ON smart.saved_maps;                                                                                      
DROP TRIGGER IF EXISTS trg_station ON smart.station;                                                                                            
DROP TRIGGER IF EXISTS trg_summary_query ON smart.summary_query;                                                                                
DROP TRIGGER IF EXISTS trg_team ON smart.team;                                                                                                  
DROP TRIGGER IF EXISTS trg_waypoint ON smart.waypoint;                                                                                          
DROP TRIGGER IF EXISTS trg_waypoint_query ON smart.waypoint_query;                                                                              
DROP TRIGGER IF EXISTS trg_configurable_model ON smart.configurable_model;                                                                      
DROP TRIGGER IF EXISTS trg_screen_option ON smart.screen_option;                                                                                
DROP TRIGGER IF EXISTS trg_compound_query ON smart.compound_query;                                                                              
DROP TRIGGER IF EXISTS trg_agency ON smart.agency;                                                                                              
DROP TRIGGER IF EXISTS trg_area_geometries ON smart.area_geometries;                                                                            
DROP TRIGGER IF EXISTS trg_ca_projection ON smart.ca_projection;                                                                                
DROP TRIGGER IF EXISTS trg_conservation_area ON smart.conservation_area;                                                                        
DROP TRIGGER IF EXISTS trg_dm_attribute ON smart.dm_attribute;                                                                                  
DROP TRIGGER IF EXISTS trg_dm_category ON smart.dm_category;                                                                                    
DROP TRIGGER IF EXISTS trg_employee ON smart.employee;                                                                                          
DROP TRIGGER IF EXISTS trg_gridded_query ON smart.gridded_query;                                                                                
DROP TRIGGER IF EXISTS trg_language ON smart.language;                                                                                          
DROP TRIGGER IF EXISTS trg_map_styles ON smart.map_styles;                                                                                      
DROP TRIGGER IF EXISTS trg_observation_options ON smart.observation_options;                                                                    
DROP TRIGGER IF EXISTS trg_observation_query ON smart.observation_query;                                                                        
DROP TRIGGER IF EXISTS trg_obs_gridded_query ON smart.obs_gridded_query;                                                                            
DROP TRIGGER IF EXISTS trg_obs_observation_query ON smart.obs_observation_query;                                                                
DROP TRIGGER IF EXISTS trg_obs_summary_query ON smart.obs_summary_query;                                                                        
DROP TRIGGER IF EXISTS trg_obs_waypoint_query ON smart.obs_waypoint_query;                                                                      
DROP TRIGGER IF EXISTS trg_patrol ON smart.patrol;                                                                                              
DROP TRIGGER IF EXISTS trg_patrol_mandate ON smart.patrol_mandate;                                                                              
DROP TRIGGER IF EXISTS trg_patrol_query ON smart.patrol_query;                                                                                  
DROP TRIGGER IF EXISTS trg_patrol_transport ON smart.patrol_transport;                                                                          
DROP TRIGGER IF EXISTS trg_patrol_type ON smart.patrol_type;                                                                                    
DROP TRIGGER IF EXISTS trg_dm_attribute_list ON smart.dm_attribute_list;                                                                        
DROP TRIGGER IF EXISTS trg_dm_attribute_tree ON smart.dm_attribute_tree;                                                                        
DROP TRIGGER IF EXISTS trg_dm_att_agg_map ON smart.dm_att_agg_map;                                                                              
DROP TRIGGER IF EXISTS trg_dm_cat_att_map ON smart.dm_cat_att_map;                                                                              
DROP TRIGGER IF EXISTS trg_i18n_label ON smart.i18n_label;                                                                                      
DROP TRIGGER IF EXISTS trg_patrol_leg ON smart.patrol_leg;                                                                                      
DROP TRIGGER IF EXISTS trg_patrol_leg_day ON smart.patrol_leg_day;                                                                              
DROP TRIGGER IF EXISTS trg_patrol_leg_members ON smart.patrol_leg_members;                                                                      
DROP TRIGGER IF EXISTS trg_patrol_waypoint ON smart.patrol_waypoint;                                                                            
DROP TRIGGER IF EXISTS trg_rank ON smart.rank;                                                                                                  
DROP TRIGGER IF EXISTS trg_report_query ON smart.report_query;                                                                                  
DROP TRIGGER IF EXISTS trg_track ON smart.track;                                                                                                
DROP TRIGGER IF EXISTS trg_wp_attachments ON smart.wp_attachments;                                                                              
DROP TRIGGER IF EXISTS trg_wp_observation ON smart.wp_observation;                                                                              
DROP TRIGGER IF EXISTS trg_wp_observation_attributes ON smart.wp_observation_attributes;                                                        
DROP TRIGGER IF EXISTS trg_cm_attribute ON smart.cm_attribute;                                                                                  
DROP TRIGGER IF EXISTS trg_cm_attribute_list ON smart.cm_attribute_list;                                                                        
DROP TRIGGER IF EXISTS trg_cm_attribute_option ON smart.cm_attribute_option;                                                                    
DROP TRIGGER IF EXISTS trg_cm_attribute_tree_node ON smart.cm_attribute_tree_node;                                                              
DROP TRIGGER IF EXISTS trg_cm_node ON smart.cm_node;                                                                                            
DROP TRIGGER IF EXISTS trg_screen_option_uuid ON smart.screen_option_uuid;                                                                      
DROP TRIGGER IF EXISTS trg_cm_attribute_config ON smart.cm_attribute_config;                                                                    
DROP TRIGGER IF EXISTS trg_compound_query_layer ON smart.compound_query_layer;                                                                  
DROP TRIGGER IF EXISTS trg_connect_ct_properties ON smart.connect_ct_properties;                                                                
DROP TRIGGER IF EXISTS trg_connect_alert ON smart.connect_alert;                                                                                
DROP TRIGGER IF EXISTS trg_plan ON smart.plan;                                                                                                  
DROP TRIGGER IF EXISTS trg_plan_target ON smart.plan_target;                                                                                    
DROP TRIGGER IF EXISTS trg_plan_target_point ON smart.plan_target_point;                                                                        
DROP TRIGGER IF EXISTS trg_patrol_plan ON smart.patrol_plan;                                                                                    
DROP TRIGGER IF EXISTS trg_ct_patrol_link ON smart.ct_patrol_link;                                                                              
DROP TRIGGER IF EXISTS trg_ct_mission_link ON smart.ct_mission_link;                                                                            
DROP TRIGGER IF EXISTS trg_informant ON smart.informant;                                                                                        
DROP TRIGGER IF EXISTS trg_intelligence ON smart.intelligence;                                                                                  
DROP TRIGGER IF EXISTS trg_intelligence_source ON smart.intelligence_source;                                                                    
DROP TRIGGER IF EXISTS trg_patrol_intelligence ON smart.patrol_intelligence;                                                                    
DROP TRIGGER IF EXISTS trg_intelligence_attachment ON smart.intelligence_attachment;                                                            
DROP TRIGGER IF EXISTS trg_intelligence_point ON smart.intelligence_point;                                                                      
DROP TRIGGER IF EXISTS trg_intel_record_query ON smart.intel_record_query;                                                                      
DROP TRIGGER IF EXISTS trg_intel_summary_query ON smart.intel_summary_query;                                                                    
DROP TRIGGER IF EXISTS trg_i_attachment ON smart.i_attachment;                                                                                  
DROP TRIGGER IF EXISTS trg_i_attribute ON smart.i_attribute;                                                                                    
DROP TRIGGER IF EXISTS trg_i_entity ON smart.i_entity;                                                                                          
DROP TRIGGER IF EXISTS trg_i_entity_search ON smart.i_entity_search;                                                                            
DROP TRIGGER IF EXISTS trg_i_entity_type ON smart.i_entity_type;                                                                                
DROP TRIGGER IF EXISTS trg_i_location ON smart.i_location;                                                                                      
DROP TRIGGER IF EXISTS trg_i_record ON smart.i_record;                                                                                          
DROP TRIGGER IF EXISTS trg_i_record_obs_query ON smart.i_record_obs_query;
DROP TRIGGER IF EXISTS trg_i_entity_summary_query ON smart.i_entity_summary_query;
DROP TRIGGER IF EXISTS trg_i_entity_record_query ON smart.i_entity_record_query;
DROP TRIGGER IF EXISTS trg_i_relationship_group ON smart.i_relationship_group;                                                                  
DROP TRIGGER IF EXISTS trg_i_relationship_type ON smart.i_relationship_type;                                                                    
DROP TRIGGER IF EXISTS trg_i_working_set ON smart.i_working_set;                                                                                
DROP TRIGGER IF EXISTS trg_i_recordsource ON smart.i_recordsource;                                                                              
DROP TRIGGER IF EXISTS trg_i_attribute_list_item ON smart.i_attribute_list_item;                                                                
DROP TRIGGER IF EXISTS trg_i_entity_attachment ON smart.i_entity_attachment;                                                                    
DROP TRIGGER IF EXISTS trg_i_entity_attribute_value ON smart.i_entity_attribute_value;                                                          
DROP TRIGGER IF EXISTS trg_i_entity_location ON smart.i_entity_location;                                                                        
DROP TRIGGER IF EXISTS trg_i_entity_record ON smart.i_entity_record;                                                                            
DROP TRIGGER IF EXISTS trg_i_entity_relationship ON smart.i_entity_relationship;                                                                
DROP TRIGGER IF EXISTS trg_i_entity_relationship_attribute_value ON smart.i_entity_relationship_attribute_value;                                
DROP TRIGGER IF EXISTS trg_i_entity_type_attribute ON smart.i_entity_type_attribute;                                                            
DROP TRIGGER IF EXISTS trg_i_entity_type_attribute_group ON smart.i_entity_type_attribute_group;                                                
DROP TRIGGER IF EXISTS trg_i_observation ON smart.i_observation;                                                                                
DROP TRIGGER IF EXISTS trg_i_observation_attribute ON smart.i_observation_attribute;                                                            
DROP TRIGGER IF EXISTS trg_i_record_attachment ON smart.i_record_attachment;                                                                    
DROP TRIGGER IF EXISTS trg_i_relationship_type_attribute ON smart.i_relationship_type_attribute;                                                
DROP TRIGGER IF EXISTS trg_i_working_set_entity ON smart.i_working_set_entity;                                                                  
DROP TRIGGER IF EXISTS trg_i_working_set_query ON smart.i_working_set_query;                                                                    
DROP TRIGGER IF EXISTS trg_i_working_set_record ON smart.i_working_set_record;                                                                  
DROP TRIGGER IF EXISTS trg_i_record_attribute_value ON smart.i_record_attribute_value;                                                          
DROP TRIGGER IF EXISTS trg_i_record_attribute_value_list ON smart.i_record_attribute_value_list;                                                
DROP TRIGGER IF EXISTS trg_i_recordsource_attribute ON smart.i_recordsource_attribute;                                                          
DROP TRIGGER IF EXISTS trg_mission_attribute ON smart.mission_attribute;                                                                        
DROP TRIGGER IF EXISTS trg_sampling_unit_attribute ON smart.sampling_unit_attribute;                                                            
DROP TRIGGER IF EXISTS trg_survey_design ON smart.survey_design;                                                                                
DROP TRIGGER IF EXISTS trg_mission ON smart.mission;                                                                                            
DROP TRIGGER IF EXISTS trg_mission_attribute_list ON smart.mission_attribute_list;                                                              
DROP TRIGGER IF EXISTS trg_mission_day ON smart.mission_day;                                                                                    
DROP TRIGGER IF EXISTS trg_mission_member ON smart.mission_member;                                                                              
DROP TRIGGER IF EXISTS trg_mission_property ON smart.mission_property;                                                                          
DROP TRIGGER IF EXISTS trg_mission_property_value ON smart.mission_property_value;                                                              
DROP TRIGGER IF EXISTS trg_mission_track ON smart.mission_track;                                                                                
DROP TRIGGER IF EXISTS trg_sampling_unit ON smart.sampling_unit;                                                                                
DROP TRIGGER IF EXISTS trg_sampling_unit_attribute_list ON smart.sampling_unit_attribute_list;                                                  
DROP TRIGGER IF EXISTS trg_sampling_unit_attribute_value ON smart.sampling_unit_attribute_value;                                                
DROP TRIGGER IF EXISTS trg_survey ON smart.survey;                                                                                              
DROP TRIGGER IF EXISTS trg_survey_waypoint ON smart.survey_waypoint;                                                                            
DROP TRIGGER IF EXISTS trg_survey_design_property ON smart.survey_design_property;                                                              
DROP TRIGGER IF EXISTS trg_survey_design_sampling_unit ON smart.survey_design_sampling_unit;                                                    
DROP TRIGGER IF EXISTS trg_survey_gridded_query ON smart.survey_gridded_query;                                                                  
DROP TRIGGER IF EXISTS trg_survey_mission_query ON smart.survey_mission_query;                                                                  
DROP TRIGGER IF EXISTS trg_survey_mission_track_query ON smart.survey_mission_track_query;                                                      
DROP TRIGGER IF EXISTS trg_survey_observation_query ON smart.survey_observation_query;                                                          
DROP TRIGGER IF EXISTS trg_survey_summary_query ON smart.survey_summary_query;                                                                  
DROP TRIGGER IF EXISTS trg_survey_waypoint_query ON smart.survey_waypoint_query;                                                                
DROP TRIGGER IF EXISTS trg_entity_type ON smart.entity_type;                                                                                    
DROP TRIGGER IF EXISTS trg_entity ON smart.entity;                                                                                              
DROP TRIGGER IF EXISTS trg_entity_attribute ON smart.entity_attribute;                                                                          
DROP TRIGGER IF EXISTS trg_entity_attribute_value ON smart.entity_attribute_value;                                                              
DROP TRIGGER IF EXISTS trg_entity_gridded_query ON smart.entity_gridded_query;                                                                  
DROP TRIGGER IF EXISTS trg_entity_observation_query ON smart.entity_observation_query;                                                          
DROP TRIGGER IF EXISTS trg_entity_summary_query ON smart.entity_summary_query;                                                                  
DROP TRIGGER IF EXISTS trg_entity_waypoint_query ON smart.entity_waypoint_query;                                                                
DROP TRIGGER IF EXISTS trg_ct_properties_option ON smart.ct_properties_option;                                                                  
DROP TRIGGER IF EXISTS trg_ct_properties_profile ON smart.ct_properties_profile;                                                                
DROP TRIGGER IF EXISTS trg_ct_properties_profile_option ON smart.ct_properties_profile_option;                                                  
DROP TRIGGER IF EXISTS trg_cm_ct_properties_profile ON smart.cm_ct_properties_profile;                                                          
DROP TRIGGER IF EXISTS trg_connect_account ON smart.connect_account;                                                                            
DROP TRIGGER IF EXISTS trg_qa_routine ON smart.qa_routine;                                                                                      
DROP TRIGGER IF EXISTS trg_qa_error ON smart.qa_error;                                                                                          
DROP TRIGGER IF EXISTS trg_qa_routine_parameter ON smart.qa_routine_parameter;                                                                  
DROP TRIGGER IF EXISTS trg_observation_attachment on smart.observation_attachment;
DROP TRIGGER IF EXISTS trg_e_event_filter on smart.e_event_filter;
DROP TRIGGER IF EXISTS trg_e_action on smart.e_action;
DROP TRIGGER IF EXISTS trg_e_action_parameter_value on smart.e_action_parameter_value;
DROP TRIGGER IF EXISTS trg_e_event_action on smart.e_event_action;

DROP FUNCTION IF EXISTS connect.trg_changelog_common();
DROP FUNCTION IF EXISTS connect.trg_cm_attribute();
DROP FUNCTION IF EXISTS connect.trg_cm_attribute_config();
DROP FUNCTION IF EXISTS connect.trg_cm_attribute_list();
DROP FUNCTION IF EXISTS connect.trg_cm_attribute_option();
DROP FUNCTION IF EXISTS connect.trg_cm_attribute_tree_node();
DROP FUNCTION IF EXISTS connect.trg_cm_ct_properties_profile();
DROP FUNCTION IF EXISTS connect.trg_cm_node();
DROP FUNCTION IF EXISTS connect.trg_compound_query_layer();
DROP FUNCTION IF EXISTS connect.trg_connect_account();
DROP FUNCTION IF EXISTS connect.trg_connect_alert();
DROP FUNCTION IF EXISTS connect.trg_connect_ct_properties();
DROP FUNCTION IF EXISTS connect.trg_ct_mission_link();
DROP FUNCTION IF EXISTS connect.trg_ct_patrol_link();
DROP FUNCTION IF EXISTS connect.trg_ct_properties_profile_option();
DROP FUNCTION IF EXISTS connect.trg_dm_att_agg_map();
DROP FUNCTION IF EXISTS connect.trg_dm_attribute_list();
DROP FUNCTION IF EXISTS connect.trg_dm_attribute_tree();
DROP FUNCTION IF EXISTS connect.trg_dm_cat_att_map();
DROP FUNCTION IF EXISTS connect.trg_entity();
DROP FUNCTION IF EXISTS connect.trg_entity_attribute();
DROP FUNCTION IF EXISTS connect.trg_entity_attribute_value();
DROP FUNCTION IF EXISTS connect.trg_i18n_label();
DROP FUNCTION IF EXISTS connect.trg_i_attribute_list_item();
DROP FUNCTION IF EXISTS connect.trg_i_entity_attachment();
DROP FUNCTION IF EXISTS connect.trg_i_entity_attribute_value();
DROP FUNCTION IF EXISTS connect.trg_i_entity_location();
DROP FUNCTION IF EXISTS connect.trg_i_entity_record();
DROP FUNCTION IF EXISTS connect.trg_i_entity_relationship();
DROP FUNCTION IF EXISTS connect.trg_i_entity_relationship_attribute_value();
DROP FUNCTION IF EXISTS connect.trg_i_entity_type_attribute();
DROP FUNCTION IF EXISTS connect.trg_i_entity_type_attribute_group();
DROP FUNCTION IF EXISTS connect.trg_i_observation();
DROP FUNCTION IF EXISTS connect.trg_i_observation_attribute();
DROP FUNCTION IF EXISTS connect.trg_i_record_attachment();
DROP FUNCTION IF EXISTS connect.trg_i_record_attribute_value();
DROP FUNCTION IF EXISTS connect.trg_i_record_attribute_value_list();
DROP FUNCTION IF EXISTS connect.trg_i_recordsource_attribute();
DROP FUNCTION IF EXISTS connect.trg_i_relationship_type_attribute();
DROP FUNCTION IF EXISTS connect.trg_i_working_set_entity();
DROP FUNCTION IF EXISTS connect.trg_i_working_set_query();
DROP FUNCTION IF EXISTS connect.trg_i_working_set_record();
DROP FUNCTION IF EXISTS connect.trg_intelligence_attachment();
DROP FUNCTION IF EXISTS connect.trg_intelligence_point();
DROP FUNCTION IF EXISTS connect.trg_mission();
DROP FUNCTION IF EXISTS connect.trg_mission_attribute_list();
DROP FUNCTION IF EXISTS connect.trg_mission_day();
DROP FUNCTION IF EXISTS connect.trg_mission_member();
DROP FUNCTION IF EXISTS connect.trg_mission_property();
DROP FUNCTION IF EXISTS connect.trg_mission_property_value();
DROP FUNCTION IF EXISTS connect.trg_mission_track();
DROP FUNCTION IF EXISTS connect.trg_observation_attachment();
DROP FUNCTION IF EXISTS connect.trg_patrol_intelligence();
DROP FUNCTION IF EXISTS connect.trg_patrol_leg();
DROP FUNCTION IF EXISTS connect.trg_patrol_leg_day();
DROP FUNCTION IF EXISTS connect.trg_patrol_leg_members();
DROP FUNCTION IF EXISTS connect.trg_patrol_plan();
DROP FUNCTION IF EXISTS connect.trg_patrol_type();
DROP FUNCTION IF EXISTS connect.trg_patrol_waypoint();
DROP FUNCTION IF EXISTS connect.trg_plan_target();
DROP FUNCTION IF EXISTS connect.trg_plan_target_point();
DROP FUNCTION IF EXISTS connect.trg_qa_routine_parameter();
DROP FUNCTION IF EXISTS connect.trg_rank();
DROP FUNCTION IF EXISTS connect.trg_report_query();
DROP FUNCTION IF EXISTS connect.trg_sampling_unit();
DROP FUNCTION IF EXISTS connect.trg_sampling_unit_attribute_list();
DROP FUNCTION IF EXISTS connect.trg_sampling_unit_attribute_value();
DROP FUNCTION IF EXISTS connect.trg_screen_option_uuid();
DROP FUNCTION IF EXISTS connect.trg_survey();
DROP FUNCTION IF EXISTS connect.trg_survey_design_property();
DROP FUNCTION IF EXISTS connect.trg_survey_design_sampling_unit();
DROP FUNCTION IF EXISTS connect.trg_survey_waypoint();
DROP FUNCTION IF EXISTS connect.trg_track();
DROP FUNCTION IF EXISTS connect.trg_wp_attachments();
DROP FUNCTION IF EXISTS connect.trg_wp_observation();
DROP FUNCTION IF EXISTS connect.trg_wp_observation_attributes();
DROP FUNCTION IF EXISTS connect.trg_conservation_area();
DROP FUNCTION IF EXISTS connect.trg_observation_options();
DROP FUNCTION IF EXISTS connect.trg_e_action_parameter_value();
DROP FUNCTION IF EXISTS connect.trg_e_event_action();

CREATE OR REPLACE FUNCTION connect.trg_changelog_common() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str,  ca_uuid) 
 		VALUES
 		(uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, ROW.CA_UUID);
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';



--- QA MODULE TRIGGERS --- 
CREATE OR REPLACE FUNCTION connect.trg_qa_routine_parameter() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, r.CA_UUID FROM smart.qa_routine r WHERE r.uuid = ROW.qa_routine_uuid;
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_qa_routine AFTER INSERT OR UPDATE OR DELETE ON smart.qa_routine FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_qa_error AFTER INSERT OR UPDATE OR DELETE ON smart.qa_error FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_qa_routine_parameter AFTER INSERT OR UPDATE OR DELETE ON smart.qa_routine_parameter FOR EACH ROW execute procedure connect.trg_qa_routine_parameter();





-- CONNECT ACCOUNT -- 
CREATE OR REPLACE FUNCTION connect.trg_connect_account() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'employee_uuid', ROW.EMPLOYEE_UUID, null, null, null, server.CA_UUID FROM smart.connect_server server WHERE server.uuid = ROW.connect_uuid;
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';
CREATE TRIGGER trg_connect_account AFTER INSERT OR UPDATE OR DELETE ON smart.connect_account FOR EACH ROW execute procedure connect.trg_connect_account();



-- CT PROPERTIES -- 

CREATE OR REPLACE FUNCTION connect.trg_ct_properties_profile_option() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, p.CA_UUID FROM smart.ct_properties_profile p WHERE p.uuid = ROW.profile_uuid;
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_cm_ct_properties_profile() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'cm_uuid', ROW.CM_UUID, null, null, null, cm.CA_UUID FROM smart.configurable_model cm WHERE cm.uuid = ROW.cm_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_ct_properties_option AFTER INSERT OR UPDATE OR DELETE ON smart.ct_properties_option FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_ct_properties_profile AFTER INSERT OR UPDATE OR DELETE ON smart.ct_properties_profile FOR EACH ROW execute procedure connect.trg_changelog_common();

CREATE TRIGGER trg_ct_properties_profile_option AFTER INSERT OR UPDATE OR DELETE ON smart.ct_properties_profile_option FOR EACH ROW execute procedure connect.trg_ct_properties_profile_option();
CREATE TRIGGER trg_cm_ct_properties_profile AFTER INSERT OR UPDATE OR DELETE ON smart.cm_ct_properties_profile FOR EACH ROW execute procedure connect.trg_cm_ct_properties_profile();



--ENTITY QUERIES

CREATE TRIGGER trg_entity_gridded_query AFTER INSERT OR UPDATE OR DELETE ON smart.entity_gridded_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_entity_observation_query AFTER INSERT OR UPDATE OR DELETE ON smart.entity_observation_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_entity_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.entity_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_entity_waypoint_query AFTER INSERT OR UPDATE OR DELETE ON smart.entity_waypoint_query FOR EACH ROW execute procedure connect.trg_changelog_common();

--ENTITIES

CREATE OR REPLACE FUNCTION connect.trg_entity() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, et.CA_UUID FROM smart.entity_type et WHERE et.uuid = ROW.entity_type_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION connect.trg_entity_attribute() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, et.CA_UUID FROM smart.entity_type et WHERE et.uuid = ROW.entity_type_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_entity_attribute_value() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_attribute_uuid', ROW.entity_attribute_uuid, 'entity_uuid', ROW.entity_uuid, null, et.CA_UUID FROM smart.entity_type et, smart.entity e WHERE e.entity_type_uuid = et.uuid and e.uuid = ROW.entity_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_entity_type AFTER INSERT OR UPDATE OR DELETE ON smart.entity_type FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_entity AFTER INSERT OR UPDATE OR DELETE ON smart.entity FOR EACH ROW execute procedure connect.trg_entity();
CREATE TRIGGER trg_entity_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.entity_attribute FOR EACH ROW execute procedure connect.trg_entity_attribute();
CREATE TRIGGER trg_entity_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.entity_attribute_value FOR EACH ROW execute procedure connect.trg_entity_attribute_value();


-- ER QUERIES
CREATE TRIGGER trg_survey_gridded_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_gridded_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_mission_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_mission_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_mission_track_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_mission_track_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_observation_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_observation_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_waypoint_query AFTER INSERT OR UPDATE OR DELETE ON smart.survey_waypoint_query FOR EACH ROW execute procedure connect.trg_changelog_common();

-- ER CORE
CREATE OR REPLACE FUNCTION connect.trg_mission() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID FROM smart.survey s, smart.survey_design sd WHERE s.survey_design_uuid = sd.uuid and s.uuid = ROW.survey_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION connect.trg_mission_attribute_list() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, ma.CA_UUID FROM smart.mission_attribute ma WHERE ma.uuid = ROW.mission_attribute_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_mission_day() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID FROM smart.mission m, smart.survey s, smart.survey_design sd 
 		WHERE s.survey_design_uuid = sd.uuid and s.uuid = m.survey_uuid and m.uuid = ROW.mission_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_mission_member() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'mission_uuid', ROW.mission_uuid, 'employee_uuid', ROW.employee_uuid, null, e.CA_UUID FROM smart.employee e
 		WHERE e.uuid = ROW.employee_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_mission_property() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'survey_design_uuid', ROW.survey_design_uuid, 'mission_attribute_uuid', ROW.mission_attribute_uuid, null, sd.CA_UUID FROM smart.survey_design sd
 		WHERE sd.uuid = ROW.survey_design_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_mission_property_value() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'mission_uuid', ROW.mission_uuid, 'mission_attribute_uuid', ROW.mission_attribute_uuid, null, ma.CA_UUID 
 		FROM smart.mission_attribute ma
 		WHERE ma.uuid = ROW.mission_attribute_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_mission_track() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID 
 		FROM smart.mission_day md, smart.mission m, smart.survey s, smart.survey_design sd 
 		WHERE s.survey_design_uuid = sd.uuid and s.uuid = m.survey_uuid and m.uuid = md.mission_uuid and md.uuid = ROW.mission_day_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

 
 
CREATE OR REPLACE FUNCTION connect.trg_sampling_unit() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID 
 		FROM smart.survey_design sd 
 		WHERE sd.uuid = ROW.survey_design_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_sampling_unit_attribute_list() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sa.CA_UUID 
 		FROM smart.sampling_unit_attribute sa
 		WHERE sa.uuid = ROW.sampling_unit_attribute_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_sampling_unit_attribute_value() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'su_attribute_uuid', ROW.su_attribute_uuid, 'su_uuid', ROW.su_uuid, null, sa.CA_UUID 
 		FROM smart.sampling_unit_attribute sa
 		WHERE sa.uuid = ROW.su_attribute_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

 
CREATE OR REPLACE FUNCTION connect.trg_survey() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID 
 		FROM smart.survey_design sd
 		WHERE sd.uuid = ROW.survey_design_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION connect.trg_survey_design_property() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, sd.CA_UUID 
 		FROM smart.survey_design sd
 		WHERE sd.uuid = ROW.survey_design_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_survey_design_sampling_unit() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'survey_design_uuid', ROW.survey_design_uuid, 'su_attribute_uuid', ROW.su_attribute_uuid, null, sd.CA_UUID 
 		FROM smart.survey_design sd
 		WHERE sd.uuid = ROW.survey_design_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_survey_waypoint() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'wp_uuid', ROW.wp_uuid, 'mission_day_uuid', ROW.mission_day_uuid, null, wp.CA_UUID 
 		FROM smart.waypoint wp
 		WHERE wp.uuid = ROW.wp_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';
 
CREATE TRIGGER trg_mission_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.mission_attribute FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_sampling_unit_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.sampling_unit_attribute FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_survey_design AFTER INSERT OR UPDATE OR DELETE ON smart.survey_design FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_mission AFTER INSERT OR UPDATE OR DELETE ON smart.mission FOR EACH ROW execute procedure connect.trg_mission();
CREATE TRIGGER trg_mission_attribute_list AFTER INSERT OR UPDATE OR DELETE ON smart.mission_attribute_list FOR EACH ROW execute procedure connect.trg_mission_attribute_list();
CREATE TRIGGER trg_mission_day AFTER INSERT OR UPDATE OR DELETE ON smart.mission_day FOR EACH ROW execute procedure connect.trg_mission_day();
CREATE TRIGGER trg_mission_member AFTER INSERT OR UPDATE OR DELETE ON smart.mission_member FOR EACH ROW execute procedure connect.trg_mission_member();
CREATE TRIGGER trg_mission_property AFTER INSERT OR UPDATE OR DELETE ON smart.mission_property FOR EACH ROW execute procedure connect.trg_mission_property();
CREATE TRIGGER trg_mission_property_value AFTER INSERT OR UPDATE OR DELETE ON smart.mission_property_value FOR EACH ROW execute procedure connect.trg_mission_property_value();
CREATE TRIGGER trg_mission_track AFTER INSERT OR UPDATE OR DELETE ON smart.mission_track FOR EACH ROW execute procedure connect.trg_mission_track();
CREATE TRIGGER trg_sampling_unit AFTER INSERT OR UPDATE OR DELETE ON smart.sampling_unit FOR EACH ROW execute procedure connect.trg_sampling_unit();
CREATE TRIGGER trg_sampling_unit_attribute_list AFTER INSERT OR UPDATE OR DELETE ON smart.sampling_unit_attribute_list FOR EACH ROW execute procedure connect.trg_sampling_unit_attribute_list();
CREATE TRIGGER trg_sampling_unit_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.sampling_unit_attribute_value FOR EACH ROW execute procedure connect.trg_sampling_unit_attribute_value();
CREATE TRIGGER trg_survey AFTER INSERT OR UPDATE OR DELETE ON smart.survey FOR EACH ROW execute procedure connect.trg_survey();
CREATE TRIGGER trg_survey_waypoint AFTER INSERT OR UPDATE OR DELETE ON smart.survey_waypoint FOR EACH ROW execute procedure connect.trg_survey_waypoint(); 
CREATE TRIGGER trg_survey_design_property AFTER INSERT OR UPDATE OR DELETE ON smart.survey_design_property FOR EACH ROW execute procedure connect.trg_survey_design_property(); 
CREATE TRIGGER trg_survey_design_sampling_unit AFTER INSERT OR UPDATE OR DELETE ON smart.survey_design_sampling_unit FOR EACH ROW execute procedure connect.trg_survey_design_sampling_unit(); 

-- ADVANCED INTELLIGENCE --

CREATE OR REPLACE FUNCTION connect.trg_i_attribute_list_item() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		FROM smart.i_attribute i
 		WHERE i.uuid = ROW.attribute_uuid;
 RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_entity_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_uuid', ROW.entity_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.i_entity i where i.uuid = ROW.entity_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION connect.trg_i_entity_attachment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_uuid', ROW.entity_uuid, 'attachment_uuid', ROW.attachment_uuid, null, i.CA_UUID 
 		from smart.i_entity i where i.uuid = ROW.entity_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';
 
CREATE OR REPLACE FUNCTION connect.trg_i_entity_location() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_uuid', ROW.entity_uuid, 'location_uuid', ROW.location_uuid, null, i.CA_UUID 
 		from smart.i_entity i where i.uuid = ROW.entity_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_entity_record() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_uuid', ROW.entity_uuid, 'record_uuid', ROW.record_uuid, null, i.CA_UUID 
 		from smart.i_entity i where i.uuid = ROW.entity_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION connect.trg_i_entity_relationship() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.i_relationship_type i where i.uuid = ROW.relationship_type_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_entity_relationship_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_relationship_uuid', ROW.entity_relationship_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.i_attribute i where i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_entity_type_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'entity_type_uuid', ROW.entity_type_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.i_entity_type i where i.uuid = ROW.entity_type_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_entity_type_attribute_group() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.i_entity_type i where i.uuid = ROW.entity_type_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_observation() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.i_location i where i.uuid = ROW.location_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_observation_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'observation_uuid', ROW.observation_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.dm_attribute i where i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_record_attachment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'record_uuid', ROW.record_uuid, 'attachment_uuid', ROW.attachment_uuid, null, i.CA_UUID 
 		from smart.i_record i where i.uuid = ROW.record_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_relationship_type_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'relationship_type_uuid', ROW.relationship_type_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.i_attribute i where i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_working_set_entity() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'working_set_uuid', ROW.working_set_uuid, 'entity_uuid', ROW.entity_uuid, null, i.CA_UUID 
 		from smart.i_working_set i where i.uuid = ROW.working_set_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_working_set_query() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'working_set_uuid', ROW.working_set_uuid, 'query_uuid', ROW.query_uuid, null, i.CA_UUID 
 		from smart.i_working_set i where i.uuid = ROW.working_set_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_working_set_record() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'working_set_uuid', ROW.working_set_uuid, 'record_uuid', ROW.record_uuid, null, i.CA_UUID 
 		from smart.i_working_set i where i.uuid = ROW.working_set_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_record_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'record_uuid', ROW.record_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.i_record i where i.uuid = ROW.record_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_record_attribute_value_list() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'value_uuid', ROW.value_uuid, 'element_uuid', ROW.element_uuid, null, i.CA_UUID 
 		from smart.i_record_attribute_value v, smart.i_record i where v.uuid = ROW.value_uuid and i.uuid = v.record_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_i_recordsource_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.i_recordsource i WHERE i.uuid = ROW.source_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';


CREATE TRIGGER trg_i_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.i_attachment FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.i_attribute FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_entity AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_entity_search AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_search FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_entity_type AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_type FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_location AFTER INSERT OR UPDATE OR DELETE ON smart.i_location FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_record AFTER INSERT OR UPDATE OR DELETE ON smart.i_record FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_record_obs_query AFTER INSERT OR UPDATE OR DELETE ON smart.i_record_obs_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_entity_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_entity_record_query AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_record_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_relationship_group AFTER INSERT OR UPDATE OR DELETE ON smart.i_relationship_group FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_relationship_type AFTER INSERT OR UPDATE OR DELETE ON smart.i_relationship_type FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_working_set AFTER INSERT OR UPDATE OR DELETE ON smart.i_working_set FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_recordsource AFTER INSERT OR UPDATE OR DELETE ON smart.i_recordsource FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_i_attribute_list_item AFTER INSERT OR UPDATE OR DELETE ON smart.i_attribute_list_item FOR EACH ROW execute procedure connect.trg_i_attribute_list_item();
CREATE TRIGGER trg_i_entity_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_attachment FOR EACH ROW execute procedure connect.trg_i_entity_attachment();
CREATE TRIGGER trg_i_entity_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_attribute_value FOR EACH ROW execute procedure connect.trg_i_entity_attribute_value();
CREATE TRIGGER trg_i_entity_location AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_location FOR EACH ROW execute procedure connect.trg_i_entity_location();
CREATE TRIGGER trg_i_entity_record AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_record FOR EACH ROW execute procedure connect.trg_i_entity_record();
CREATE TRIGGER trg_i_entity_relationship AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_relationship FOR EACH ROW execute procedure connect.trg_i_entity_relationship();
CREATE TRIGGER trg_i_entity_relationship_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_relationship_attribute_value FOR EACH ROW execute procedure connect.trg_i_entity_relationship_attribute_value();
CREATE TRIGGER trg_i_entity_type_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_type_attribute FOR EACH ROW execute procedure connect.trg_i_entity_type_attribute();
CREATE TRIGGER trg_i_entity_type_attribute_group AFTER INSERT OR UPDATE OR DELETE ON smart.i_entity_type_attribute_group FOR EACH ROW execute procedure connect.trg_i_entity_type_attribute_group();
CREATE TRIGGER trg_i_observation AFTER INSERT OR UPDATE OR DELETE ON smart.i_observation FOR EACH ROW execute procedure connect.trg_i_observation();
CREATE TRIGGER trg_i_observation_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.i_observation_attribute FOR EACH ROW execute procedure connect.trg_i_observation_attribute();
CREATE TRIGGER trg_i_record_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.i_record_attachment FOR EACH ROW execute procedure connect.trg_i_record_attachment();
CREATE TRIGGER trg_i_relationship_type_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.i_relationship_type_attribute FOR EACH ROW execute procedure connect.trg_i_relationship_type_attribute();
CREATE TRIGGER trg_i_working_set_entity AFTER INSERT OR UPDATE OR DELETE ON smart.i_working_set_entity FOR EACH ROW execute procedure connect.trg_i_working_set_entity();
CREATE TRIGGER trg_i_working_set_query AFTER INSERT OR UPDATE OR DELETE ON smart.i_working_set_query FOR EACH ROW execute procedure connect.trg_i_working_set_query();
CREATE TRIGGER trg_i_working_set_record AFTER INSERT OR UPDATE OR DELETE ON smart.i_working_set_record FOR EACH ROW execute procedure connect.trg_i_working_set_record();
CREATE TRIGGER trg_i_record_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.i_record_attribute_value FOR EACH ROW execute procedure connect.trg_i_record_attribute_value();
CREATE TRIGGER trg_i_record_attribute_value_list AFTER INSERT OR UPDATE OR DELETE ON smart.i_record_attribute_value_list FOR EACH ROW execute procedure connect.trg_i_record_attribute_value_list();
CREATE TRIGGER trg_i_recordsource_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.i_recordsource_attribute FOR EACH ROW execute procedure connect.trg_i_recordsource_attribute();
CREATE TRIGGER trg_i_config_option AFTER INSERT OR UPDATE OR DELETE ON smart.i_config_option FOR EACH ROW execute procedure connect.trg_changelog_common();


-- INTELLIGENCE QUERIES --
CREATE TRIGGER trg_intel_record_query AFTER INSERT OR UPDATE OR DELETE ON smart.intel_record_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_intel_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.intel_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();



--INTELLIGENCE

CREATE OR REPLACE FUNCTION connect.trg_patrol_intelligence() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'patrol_uuid', ROW.patrol_uuid, 'intelligence_uuid', ROW.intelligence_uuid, null, p.CA_UUID 
 		from smart.patrol p where p.uuid = ROW.patrol_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_intelligence_attachment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.intelligence i where i.uuid = ROW.intelligence_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_intelligence_point() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.intelligence i where i.uuid = ROW.intelligence_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_informant AFTER INSERT OR UPDATE OR DELETE ON smart.informant FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_intelligence AFTER INSERT OR UPDATE OR DELETE ON smart.intelligence FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_intelligence_source AFTER INSERT OR UPDATE OR DELETE ON smart.intelligence_source FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_patrol_intelligence AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_intelligence FOR EACH ROW execute procedure connect.trg_patrol_intelligence();
CREATE TRIGGER trg_intelligence_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.intelligence_attachment FOR EACH ROW execute procedure connect.trg_intelligence_attachment();
CREATE TRIGGER trg_intelligence_point AFTER INSERT OR UPDATE OR DELETE ON smart.intelligence_point FOR EACH ROW execute procedure connect.trg_intelligence_point();



--PLANNING

CREATE OR REPLACE FUNCTION connect.trg_plan_target() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, p.CA_UUID 
 		from smart.plan p where p.uuid = ROW.plan_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_plan_target_point() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, p.CA_UUID 
 		FROM smart.plan_target pt, smart.plan p WHERE p.uuid = pt.plan_uuid and pt.uuid = ROW.plan_target_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_patrol_plan() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'patrol_uuid', ROW.patrol_uuid, 'plan_uuid', ROW.plan_uuid, null, p.CA_UUID 
 		FROM smart.patrol p where p.uuid = ROW.patrol_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';


CREATE TRIGGER trg_plan AFTER INSERT OR UPDATE OR DELETE ON smart.plan FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_plan_target AFTER INSERT OR UPDATE OR DELETE ON smart.plan_target FOR EACH ROW execute procedure connect.trg_plan_target();
CREATE TRIGGER trg_plan_target_point AFTER INSERT OR UPDATE OR DELETE ON smart.plan_target_point FOR EACH ROW execute procedure connect.trg_plan_target_point();
CREATE TRIGGER trg_patrol_plan AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_plan FOR EACH ROW execute procedure connect.trg_patrol_plan();

-- CYBERTRACKER --

CREATE OR REPLACE FUNCTION connect.trg_connect_ct_properties() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm WHERE cm.uuid = ROW.cm_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_connect_alert() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm WHERE cm.uuid = ROW.cm_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_connect_ct_properties AFTER INSERT OR UPDATE OR DELETE ON smart.connect_ct_properties FOR EACH ROW execute procedure connect.trg_connect_ct_properties();
CREATE TRIGGER trg_connect_alert AFTER INSERT OR UPDATE OR DELETE ON smart.connect_alert FOR EACH ROW execute procedure connect.trg_connect_alert();


CREATE OR REPLACE FUNCTION connect.trg_ct_mission_link() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'ct_uuid', ROW.ct_uuid, null, null, null, sd.CA_UUID 
 		FROM smart.mission mm, smart.survey s, smart.survey_design sd WHERE mm.survey_uuid = s.uuid and s.survey_design_uuid = sd.uuid and mm.uuid = ROW.mission_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_ct_mission_link AFTER INSERT OR UPDATE OR DELETE ON smart.ct_mission_link FOR EACH ROW execute procedure connect.trg_ct_mission_link();


CREATE OR REPLACE FUNCTION connect.trg_ct_patrol_link() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'ct_uuid', ROW.ct_uuid, null, null, null, pp.CA_UUID 
 		FROM smart.patrol pp, smart.patrol_leg pl WHERE pl.patrol_uuid = pp.uuid and pl.uuid = ROW.patrol_leg_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_ct_patrol_link AFTER INSERT OR UPDATE OR DELETE ON smart.ct_patrol_link FOR EACH ROW execute procedure connect.trg_ct_patrol_link();


--SMART CORE
CREATE OR REPLACE FUNCTION connect.trg_patrol_type() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		VALUES (uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'ca_uuid', ROW.ca_uuid, 'patrol_type', null, ROW.patrol_type,  ROW.CA_UUID);
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_dm_attribute_list() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, da.CA_UUID 
 		FROM smart.dm_attribute da WHERE da.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_dm_attribute_tree() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, da.CA_UUID 
 		FROM smart.dm_attribute da WHERE da.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_dm_att_agg_map() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'attribute_uuid', ROW.attribute_uuid, 'agg_name', null, ROW.agg_name, a.CA_UUID 
 		FROM smart.dm_attribute a WHERE a.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_dm_cat_att_map() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'attribute_uuid', ROW.attribute_uuid, 'category_uuid', ROW.category_uuid, null, a.CA_UUID 
 		FROM smart.dm_attribute a WHERE a.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_i18n_label() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'element_uuid', ROW.element_uuid, 'language_uuid', ROW.language_uuid, null, l.CA_UUID 
 		FROM smart.language l WHERE l.uuid = ROW.language_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_observation_attachment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, wp.CA_UUID 
 		FROM smart.wp_observation ob, smart.waypoint wp where ob.wp_uuid = wp.uuid and ob.uuid = ROW.obs_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_patrol_leg() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, p.CA_UUID 
 		FROM smart.patrol p WHERE p.uuid = ROW.patrol_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_patrol_leg_day() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, p.CA_UUID 
 		FROM smart.patrol p, smart.patrol_leg pl where pl.patrol_uuid = p.uuid and pl.uuid = ROW.patrol_leg_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_patrol_leg_members() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'patrol_leg_uuid', ROW.patrol_leg_uuid, 'employee_uuid', ROW.employee_uuid, null, e.CA_UUID 
 		FROM smart.employee e WHERE e.uuid = ROW.employee_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_patrol_waypoint() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'leg_day_uuid', ROW.leg_day_uuid, 'wp_uuid', ROW.wp_uuid, null, wp.CA_UUID 
 		FROM smart.waypoint wp WHERE wp.uuid = ROW.wp_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_rank() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, a.CA_UUID 
 		FROM smart.agency a WHERE a.uuid = ROW.agency_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_report_query() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'report_uuid', ROW.report_uuid, 'query_uuid', ROW.query_uuid, null, r.CA_UUID 
 		from smart.report r where r.uuid = ROW.report_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_track() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, p.CA_UUID 
 		FROM smart.patrol p, smart.patrol_leg pl, smart.patrol_leg_day pld WHERE p.uuid = pl.patrol_uuid and pl.uuid = pld.patrol_leg_uuid and pld.uuid = ROW.patrol_leg_day_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_wp_attachments() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, wp.CA_UUID 
 		FROM smart.waypoint wp WHERE wp.uuid = ROW.wp_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_wp_observation() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, wp.CA_UUID 
 		FROM smart.waypoint wp WHERE wp.uuid = ROW.wp_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_wp_observation_attributes() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'attribute_uuid', ROW.attribute_uuid, null, null, null, a.CA_UUID 
 		FROM smart.dm_attribute a WHERE a.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_cm_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, a.CA_UUID 
 		FROM smart.dm_attribute a WHERE a.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_cm_attribute_list() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm, smart.cm_attribute_config cf where cm.uuid = cf.cm_uuid and cf.uuid = ROW.config_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_cm_attribute_option() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, dm.CA_UUID 
 		FROM smart.cm_attribute cm, smart.dm_attribute dm where cm.attribute_uuid = dm.uuid and cm.uuid = ROW.cm_attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_cm_attribute_tree_node() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm, smart.cm_attribute_config cf where cm.uuid = cf.cm_uuid and cf.uuid = ROW.config_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_cm_node() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm where cm.uuid = ROW.cm_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_screen_option_uuid() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, op.CA_UUID 
 		FROM smart.screen_option op where op.uuid = ROW.option_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 


CREATE OR REPLACE FUNCTION connect.trg_cm_attribute_config() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cm.CA_UUID 
 		FROM smart.configurable_model cm where cm.uuid = ROW.cm_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 

CREATE OR REPLACE FUNCTION connect.trg_compound_query_layer() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, cq.CA_UUID 
 		FROM smart.compound_query cq where cq.uuid = ROW.compound_query_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql'; 


CREATE OR REPLACE FUNCTION connect.trg_conservation_area() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		VALUES (uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, ROW.UUID); 
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_observation_options() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		VALUES (uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'ca_uuid', ROW.ca_uuid, null, null, null, ROW.ca_UUID); 
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_conservation_area AFTER INSERT OR UPDATE OR DELETE ON smart.conservation_area FOR EACH ROW execute procedure connect.trg_conservation_area();

CREATE TRIGGER trg_query_folder AFTER INSERT OR UPDATE OR DELETE ON smart.query_folder FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_report AFTER INSERT OR UPDATE OR DELETE ON smart.report FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_report_folder AFTER INSERT OR UPDATE OR DELETE ON smart.report_folder FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_saved_maps AFTER INSERT OR UPDATE OR DELETE ON smart.saved_maps FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_station AFTER INSERT OR UPDATE OR DELETE ON smart.station FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_team AFTER INSERT OR UPDATE OR DELETE ON smart.team FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_waypoint AFTER INSERT OR UPDATE OR DELETE ON smart.waypoint FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_waypoint_query AFTER INSERT OR UPDATE OR DELETE ON smart.waypoint_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_configurable_model AFTER INSERT OR UPDATE OR DELETE ON smart.configurable_model FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_screen_option AFTER INSERT OR UPDATE OR DELETE ON smart.screen_option FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_compound_query AFTER INSERT OR UPDATE OR DELETE ON smart.compound_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_agency AFTER INSERT OR UPDATE OR DELETE ON smart.agency FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_area_geometries AFTER INSERT OR UPDATE OR DELETE ON smart.area_geometries FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_ca_projection AFTER INSERT OR UPDATE OR DELETE ON smart.ca_projection FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_dm_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.dm_attribute FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_dm_category AFTER INSERT OR UPDATE OR DELETE ON smart.dm_category FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_employee AFTER INSERT OR UPDATE OR DELETE ON smart.employee FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_gridded_query AFTER INSERT OR UPDATE OR DELETE ON smart.gridded_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_language AFTER INSERT OR UPDATE OR DELETE ON smart.language FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_map_styles AFTER INSERT OR UPDATE OR DELETE ON smart.map_styles FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_observation_options AFTER INSERT OR UPDATE OR DELETE ON smart.observation_options FOR EACH ROW execute procedure connect.trg_observation_options();
CREATE TRIGGER trg_observation_query AFTER INSERT OR UPDATE OR DELETE ON smart.observation_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_obs_gridded_query AFTER INSERT OR UPDATE OR DELETE ON smart.obs_gridded_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_obs_observation_query AFTER INSERT OR UPDATE OR DELETE ON smart.obs_observation_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_obs_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.obs_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_obs_waypoint_query AFTER INSERT OR UPDATE OR DELETE ON smart.obs_waypoint_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_patrol AFTER INSERT OR UPDATE OR DELETE ON smart.patrol FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_patrol_mandate AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_mandate FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_patrol_query AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_patrol_transport AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_transport FOR EACH ROW execute procedure connect.trg_changelog_common();  


CREATE TRIGGER trg_patrol_type AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_type FOR EACH ROW execute procedure connect.trg_patrol_type();
CREATE TRIGGER trg_dm_attribute_list AFTER INSERT OR UPDATE OR DELETE ON smart.dm_attribute_list FOR EACH ROW execute procedure connect.trg_dm_attribute_list();
CREATE TRIGGER trg_dm_attribute_tree AFTER INSERT OR UPDATE OR DELETE ON smart.dm_attribute_tree FOR EACH ROW execute procedure connect.trg_dm_attribute_tree();
CREATE TRIGGER trg_dm_att_agg_map AFTER INSERT OR UPDATE OR DELETE ON smart.dm_att_agg_map FOR EACH ROW execute procedure connect.trg_dm_att_agg_map();
CREATE TRIGGER trg_dm_cat_att_map AFTER INSERT OR UPDATE OR DELETE ON smart.dm_cat_att_map FOR EACH ROW execute procedure connect.trg_dm_cat_att_map();
CREATE TRIGGER trg_i18n_label AFTER INSERT OR UPDATE OR DELETE ON smart.i18n_label FOR EACH ROW execute procedure connect.trg_i18n_label();
CREATE TRIGGER trg_patrol_leg AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_leg FOR EACH ROW execute procedure connect.trg_patrol_leg();
CREATE TRIGGER trg_patrol_leg_day AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_leg_day FOR EACH ROW execute procedure connect.trg_patrol_leg_day();
CREATE TRIGGER trg_patrol_leg_members AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_leg_members FOR EACH ROW execute procedure connect.trg_patrol_leg_members();
CREATE TRIGGER trg_patrol_waypoint AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_waypoint FOR EACH ROW execute procedure connect.trg_patrol_waypoint();
CREATE TRIGGER trg_rank AFTER INSERT OR UPDATE OR DELETE ON smart.rank FOR EACH ROW execute procedure connect.trg_rank();
CREATE TRIGGER trg_report_query AFTER INSERT OR UPDATE OR DELETE ON smart.report_query FOR EACH ROW execute procedure connect.trg_report_query();
CREATE TRIGGER trg_track AFTER INSERT OR UPDATE OR DELETE ON smart.track FOR EACH ROW execute procedure connect.trg_track();
CREATE TRIGGER trg_wp_attachments AFTER INSERT OR UPDATE OR DELETE ON smart.wp_attachments FOR EACH ROW execute procedure connect.trg_wp_attachments();
CREATE TRIGGER trg_wp_observation AFTER INSERT OR UPDATE OR DELETE ON smart.wp_observation FOR EACH ROW execute procedure connect.trg_wp_observation();
CREATE TRIGGER trg_wp_observation_attributes AFTER INSERT OR UPDATE OR DELETE ON smart.wp_observation_attributes FOR EACH ROW execute procedure connect.trg_wp_observation_attributes();
CREATE TRIGGER trg_observation_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.observation_attachment FOR EACH ROW execute procedure connect.trg_observation_attachment();
CREATE TRIGGER trg_cm_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.cm_attribute FOR EACH ROW execute procedure connect.trg_cm_attribute();
CREATE TRIGGER trg_cm_attribute_list AFTER INSERT OR UPDATE OR DELETE ON smart.cm_attribute_list FOR EACH ROW execute procedure connect.trg_cm_attribute_list();
CREATE TRIGGER trg_cm_attribute_option AFTER INSERT OR UPDATE OR DELETE ON smart.cm_attribute_option FOR EACH ROW execute procedure connect.trg_cm_attribute_option();
CREATE TRIGGER trg_cm_attribute_tree_node AFTER INSERT OR UPDATE OR DELETE ON smart.cm_attribute_tree_node FOR EACH ROW execute procedure connect.trg_cm_attribute_tree_node();
CREATE TRIGGER trg_cm_node AFTER INSERT OR UPDATE OR DELETE ON smart.cm_node FOR EACH ROW execute procedure connect.trg_cm_node();
CREATE TRIGGER trg_screen_option_uuid AFTER INSERT OR UPDATE OR DELETE ON smart.screen_option_uuid FOR EACH ROW execute procedure connect.trg_screen_option_uuid();
CREATE TRIGGER trg_cm_attribute_config AFTER INSERT OR UPDATE OR DELETE ON smart.cm_attribute_config FOR EACH ROW execute procedure connect.trg_cm_attribute_config();
CREATE TRIGGER trg_compound_query_layer AFTER INSERT OR UPDATE OR DELETE ON smart.compound_query_layer FOR EACH ROW execute procedure connect.trg_compound_query_layer();



CREATE TRIGGER trg_i_diagram_style AFTER INSERT OR UPDATE OR DELETE ON smart.i_diagram_style FOR EACH ROW execute procedure connect.trg_changelog_common();

CREATE OR REPLACE FUNCTION connect.trg_i_diagram_entity_type_style() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, a.CA_UUID 
 		FROM smart.i_diagram_style a
 		WHERE a.uuid = ROW.style_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_i_diagram_entity_type_style AFTER INSERT OR UPDATE OR DELETE ON smart.i_diagram_entity_type_style FOR EACH ROW execute procedure connect.trg_i_diagram_entity_type_style();

CREATE OR REPLACE FUNCTION connect.trg_i_diagram_relationship_type_style() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, a.CA_UUID 
 		FROM smart.i_diagram_style a
 		WHERE a.uuid = ROW.style_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_i_diagram_relationship_type_style AFTER INSERT OR UPDATE OR DELETE ON smart.i_diagram_relationship_type_style FOR EACH ROW execute procedure connect.trg_i_diagram_relationship_type_style();


-- EVENTS TRIGGERS
CREATE TRIGGER trg_e_event_filter AFTER INSERT OR UPDATE OR DELETE ON smart.e_event_filter FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_e_action AFTER INSERT OR UPDATE OR DELETE ON smart.e_action FOR EACH ROW execute procedure connect.trg_changelog_common();


CREATE OR REPLACE FUNCTION connect.trg_e_action_parameter_value() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'action_uuid', ROW.action_uuid, 'parameter_key', null, ROW.parameter_key, a.CA_UUID 
 		FROM smart.e_action a
 		WHERE a.uuid = ROW.action_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_e_action_parameter_value AFTER INSERT OR UPDATE OR DELETE ON smart.e_action_parameter_value FOR EACH ROW execute procedure connect.trg_e_action_parameter_value();


CREATE OR REPLACE FUNCTION connect.trg_e_event_action() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, a.CA_UUID 
 		FROM smart.e_action a
 		WHERE a.uuid = ROW.action_uuid;
 	RETURN ROW;
END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_e_event_action AFTER INSERT OR UPDATE OR DELETE ON smart.e_event_action FOR EACH ROW execute procedure connect.trg_e_event_action();

-- Lock the change log table so cannot apply chnages at the same time as sync or packaging conservation area
DROP TRIGGER IF EXISTS trg_connect_account_before ON connect.change_log;
DROP TRIGGER IF EXISTS trg_connect_account_after ON connect.change_log; 
DROP FUNCTION IF EXISTS connect.trg_changelog_before();
DROP FUNCTION IF EXISTS connect.trg_changelog_after();


--If we upgrade to Postgresql 9.6 this function can be removed
--and changed to current_setting('ca.trigger.t' || NEW.ca_uuid, true)
CREATE OR REPLACE FUNCTION connect.dolog(cauuid UUID) RETURNS boolean AS $$
DECLARE
	canrun boolean;
BEGIN
	--check if we should log this ca
	select current_setting('ca.trigger.t' || cauuid) into canrun;
	return canrun;
	EXCEPTION WHEN others THEN
		RETURN TRUE;
END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_changelog_before() RETURNS trigger AS $$
DECLARE
  canlock boolean;
BEGIN
	--check if we should log this ca
	IF (NOT connect.dolog(NEW.ca_uuid)) THEN RETURN NULL; END IF;
	SELECT pg_try_advisory_lock(a.lock_key) into canlock FROM connect.ca_info a WHERE a.ca_uuid = NEW.ca_uuid;
	IF (canlock) THEN return NEW; ELSE RAISE EXCEPTION 'Database Locked to Editing'; END IF;
END$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION connect.trg_changelog_after() RETURNS trigger AS $$
DECLARE
BEGIN
	PERFORM pg_advisory_unlock(a.lock_key) FROM connect.ca_info a WHERE a.ca_uuid = NEW.ca_uuid;
RETURN NEW; END$$ LANGUAGE 'plpgsql';

CREATE  TRIGGER trg_connect_account_before BEFORE INSERT ON connect.change_log  FOR EACH ROW execute procedure connect.trg_changelog_before();
CREATE  TRIGGER trg_connect_account_after AFTER INSERT ON connect.change_log  FOR EACH ROW execute procedure connect.trg_changelog_after();




ALTER TABLE smart.connect_data_queue DROP CONSTRAINT type_chk;
-- ALTER TABLE connect.data_queue drop constraint type_chk;
update connect.connect_plugin_version set version = '3.0' where plugin_id = 'org.wcs.smart.connect.dataqueue';
update connect.ca_plugin_version set version = '3.0' where plugin_id = 'org.wcs.smart.connect.dataqueue';


ALTER TABLE smart.i_entity_attribute_value add column employee_uuid uuid;
ALTER TABLE smart.i_entity_relationship_attribute_value add column employee_uuid uuid;
			
ALTER TABLE smart.i_entity_attribute_value ADD  FOREIGN KEY (employee_uuid) REFERENCES smart.employee(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.i_entity_relationship_attribute_value ADD FOREIGN KEY (employee_uuid) REFERENCES smart.employee(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
			
UPDATE smart.employee SET smartuserlevel =  replace(smartuserlevel, 'INTEL_DATA_ENTRY', 'INTEL_RECORD_CREATE,INTEL_RECORD_VIEW,INTEL_RECORD_EDIT,INTEL_ENTITY_VIEW,INTEL_QUERY_ALL') where smartuserlevel is not null and smartuserlevel like '%INTEL_DATA_ENTRY%';
UPDATE connect.connect_plugin_version SET version = '3.0' WHERE plugin_id = 'org.wcs.smart.i2';
UPDATE connect.ca_plugin_version SET version = '3.0' WHERE plugin_id = 'org.wcs.smart.i2';


-- ASSET PLUGIN --qqq
insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.asset', '1.0');
insert into connect.ca_plugin_version (ca_uuid, plugin_id, version) select ca_uuid, 'org.wcs.smart.asset', '1.0' from connect.ca_info;

CREATE TABLE smart.asset( 
 uuid uuid NOT NULL, 
 asset_type_uuid uuid NOT NULL, 
 ca_uuid uuid NOT NULL, 
 id varchar(128) NOT NULL, 
 is_retired boolean DEFAULT false NOT NULL, PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset add constraint id_ca_uuid_unq UNIQUE(id, ca_uuid);

CREATE TABLE smart.asset_attribute ( 
 uuid uuid NOT NULL, 
 keyId varchar(128) NOT NULL, 
 type char(8) NOT NULL, 
 ca_uuid uuid NOT NULL, PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset_attribute add constraint keyid_ca_uuid_unq UNIQUE(keyId, ca_uuid);
 
 CREATE TABLE smart.asset_attribute_list_item ( 
 uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 keyid varchar(128) NOT NULL, 
 PRIMARY KEY (uuid) 
);
ALTER TABLE smart.asset_attribute_list_item add constraint asset_li_keyid_attribute_uuid_unq UNIQUE(keyId, attribute_uuid);


CREATE TABLE smart.asset_attribute_value ( 
 asset_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 string_value varchar(1024), 
 list_item_uuid uuid, 
 double_value1 double precision, 
 double_value2 double precision, 
 PRIMARY KEY (asset_uuid, attribute_uuid)
);

CREATE TABLE smart.asset_deployment ( 
 uuid uuid NOT NULL, 
 asset_uuid uuid NOT NULL, 
 station_location_uuid uuid NOT NULL, 
 start_date timestamp NOT NULL, 
 end_date timestamp, 
 track bytea, 
 PRIMARY KEY (uuid)
);

CREATE TABLE smart.asset_deployment_attribute_value ( 
 asset_deployment_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 string_value varchar(1024), 
 list_item_uuid uuid, 
 double_value1 double precision,
 double_value2 double precision, 
 PRIMARY KEY (asset_deployment_uuid, attribute_uuid) 
);
  
CREATE TABLE smart.asset_history_record ( 
 uuid uuid NOT NULL, 
 asset_uuid uuid NOT NULL, 
 date timestamp NOT NULL, 
 comment VARCHAR(32672), 
 PRIMARY KEY (uuid)
);

CREATE TABLE smart.asset_module_settings ( 
 uuid uuid NOT NULL, 
 ca_uuid uuid NOT NULL, 
 keyid varchar(128), 
 value varchar(32000), 
 PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset_module_settings add constraint asset_module_key_ca_unq UNIQUE(keyid, ca_uuid);


CREATE TABLE smart.asset_station (
 uuid uuid NOT NULL,
 ca_uuid uuid NOT NULL,
 id varchar(128) NOT NULL, 
 x double precision NOT NULL, 
 y double precision NOT NULL, 
 PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset_station add constraint asset_sn_id_ca_unq UNIQUE(id, ca_uuid);

CREATE TABLE smart.asset_station_attribute ( 
 attribute_uuid uuid NOT NULL, 
 seq_order integer NOT NULL, 
 PRIMARY KEY (attribute_uuid)
);

CREATE TABLE smart.asset_station_attribute_value ( 
 station_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 string_value varchar(1024), 
 list_item_uuid uuid, 
 double_value1 double precision, 
 double_value2 double precision, 
 PRIMARY KEY (station_uuid, attribute_uuid)
);

CREATE TABLE smart.asset_type ( 
 uuid uuid NOT NULL, 
 ca_uuid uuid NOT NULL, 
 keyid varchar(128), 
 icon bytea, 
 incident_cutoff integer, 
 PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset_type add constraint asset_type_ca_keyid_unq unique(keyid, ca_uuid);


CREATE TABLE smart.asset_type_attribute ( 
 asset_type_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 seq_order integer NOT NULL, 
 PRIMARY KEY (asset_type_uuid, attribute_uuid)
);

CREATE TABLE smart.asset_type_deployment_attribute ( 
 asset_type_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 seq_order integer NOT NULL, 
 PRIMARY KEY (asset_type_uuid, attribute_uuid)
);

CREATE TABLE smart.asset_waypoint ( 
 uuid uuid not null, 
 wp_uuid uuid NOT NULL, 
 asset_deployment_uuid uuid NOT NULL, 
 state smallint not null, 
 incident_length integer not null,
 PRIMARY KEY (uuid), 
 UNIQUE(wp_uuid, asset_deployment_uuid)
);

CREATE TABLE smart.asset_waypoint_attachment ( 
 wp_attachment_uuid uuid NOT NULL, 
 asset_waypoint_uuid uuid NOT NULL, 
 PRIMARY KEY (wp_attachment_uuid, asset_waypoint_uuid)
);

CREATE TABLE smart.asset_metadata_mapping (
 uuid uuid not null, 
 ca_uuid uuid not null,
 metadata_type varchar(16) not null, 
 metadata_key varchar(32672) not null, 
 search_order integer not null, 
 asset_field varchar(32), 
 category_uuid uuid,
 attribute_uuid uuid, 
 attribute_list_item_uuid uuid, 
 attribute_tree_node_uuid uuid,  
 PRIMARY KEY (uuid)
);

CREATE TABLE smart.asset_station_location_history (
 uuid uuid NOT NULL, 
 station_location_uuid uuid NOT NULL, 
 date timestamp NOT NULL, 
 comment VARCHAR(32672),
 PRIMARY KEY (uuid)
);

CREATE TABLE smart.asset_station_location ( 
 uuid uuid NOT NULL, 
 station_uuid uuid NOT NULL, 
 id varchar(128) NOT NULL, 
 x double precision NOT NULL, 
 y double precision NOT NULL, 
 PRIMARY KEY (uuid)
);
ALTER TABLE smart.asset_station_location add constraint asset_snlc_id_ca_unq UNIQUE(id, station_uuid);

CREATE TABLE smart.asset_station_location_attribute ( 
 attribute_uuid uuid NOT NULL, 
 seq_order integer NOT NULL, 
 PRIMARY KEY (attribute_uuid)
);

CREATE TABLE smart.asset_station_location_attribute_value ( 
 station_location_uuid uuid NOT NULL, 
 attribute_uuid uuid NOT NULL, 
 string_value varchar(1024), 
 list_item_uuid uuid, 
 double_value1 double precision, 
 double_value2 double precision, 
 PRIMARY KEY (station_location_uuid, attribute_uuid)
);

CREATE TABLE smart.asset_map_style ( 
 uuid uuid NOT NULL, 
 ca_uuid uuid NOT NULL, 
 name varchar(1024), 
 style_string varchar(32672), 
 PRIMARY KEY (uuid)
);

ALTER TABLE smart.asset_station ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_location_history ADD FOREIGN KEY (station_location_uuid) REFERENCES smart.asset_station_location(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_location ADD FOREIGN KEY (station_uuid) REFERENCES smart.asset_station(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;			
ALTER TABLE smart.asset_station_location_attribute_value ADD FOREIGN KEY (station_location_uuid) REFERENCES smart.asset_station_location(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_location_attribute_value ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute_value ADD FOREIGN KEY (asset_uuid) REFERENCES smart.asset (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute_value ADD FOREIGN KEY (asset_uuid) REFERENCES smart.asset (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment ADD FOREIGN KEY (asset_uuid) REFERENCES smart.asset (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_history_record ADD FOREIGN KEY (asset_uuid) REFERENCES smart.asset (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute_list_item ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute_value ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment_attribute_value ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_attribute ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_location_attribute ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_attribute_value ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_type_attribute ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_type_deployment_attribute ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.asset_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute_value ADD FOREIGN KEY (list_item_uuid) REFERENCES smart.asset_attribute_list_item (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment_attribute_value ADD FOREIGN KEY (list_item_uuid) REFERENCES smart.asset_attribute_list_item (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_attribute_value ADD FOREIGN KEY (list_item_uuid) REFERENCES smart.asset_attribute_list_item (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment_attribute_value ADD FOREIGN KEY (asset_deployment_uuid) REFERENCES smart.asset_deployment (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_waypoint ADD FOREIGN KEY (asset_deployment_uuid) REFERENCES smart.asset_deployment (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment ADD FOREIGN KEY (station_location_uuid) REFERENCES smart.asset_station_location (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_station_attribute_value ADD FOREIGN KEY (station_uuid) REFERENCES smart.asset_station (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset ADD FOREIGN KEY (asset_type_uuid) REFERENCES smart.asset_type (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_type_attribute ADD FOREIGN KEY (asset_type_uuid) REFERENCES smart.asset_type (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_type_deployment_attribute ADD FOREIGN KEY  (asset_type_uuid) REFERENCES smart.asset_type (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_attribute ADD FOREIGN KEY  (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_module_settings ADD FOREIGN KEY(ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_type ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_waypoint ADD FOREIGN KEY (wp_uuid) REFERENCES smart.waypoint (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_deployment ADD FOREIGN KEY (asset_uuid) REFERENCES smart.asset (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_metadata_mapping ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_metadata_mapping ADD FOREIGN KEY (category_uuid) REFERENCES smart.dm_category (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_metadata_mapping ADD FOREIGN KEY (attribute_uuid) REFERENCES smart.dm_attribute (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_metadata_mapping ADD FOREIGN KEY (attribute_list_item_uuid) REFERENCES smart.dm_attribute_list (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_metadata_mapping ADD FOREIGN KEY (attribute_tree_node_uuid) REFERENCES smart.dm_attribute_tree (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_waypoint_attachment ADD FOREIGN KEY (asset_waypoint_uuid) REFERENCES smart.asset_waypoint (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_waypoint_attachment ADD FOREIGN KEY (wp_attachment_uuid) REFERENCES smart.wp_attachments (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.asset_map_style ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area (uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_asset AFTER INSERT OR UPDATE OR DELETE ON smart.asset FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.asset_attribute FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_module_settings AFTER INSERT OR UPDATE OR DELETE ON smart.asset_module_settings FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_station AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_type AFTER INSERT OR UPDATE OR DELETE ON smart.asset_type FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_metadata_mapping AFTER INSERT OR UPDATE OR DELETE ON smart.asset_metadata_mapping FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_map_style AFTER INSERT OR UPDATE OR DELETE ON smart.asset_map_style FOR EACH ROW execute procedure connect.trg_changelog_common();


CREATE OR REPLACE FUNCTION connect.trg_asset_attribute_list_item() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_attribute_list_item AFTER INSERT OR UPDATE OR DELETE ON smart.asset_attribute_list_item FOR EACH ROW execute procedure connect.trg_asset_attribute_list_item();


CREATE OR REPLACE FUNCTION connect.trg_asset_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'asset_uuid', ROW.asset_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.asset_attribute_value FOR EACH ROW execute procedure connect.trg_asset_attribute_value();


CREATE OR REPLACE FUNCTION connect.trg_asset_deployment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.asset  i WHERE i.uuid = ROW.asset_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_deployment AFTER INSERT OR UPDATE OR DELETE ON smart.asset_deployment FOR EACH ROW execute procedure connect.trg_asset_deployment();


CREATE OR REPLACE FUNCTION connect.trg_asset_deployment_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'asset_deployment_uuid', ROW.asset_deployment_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_deployment_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.asset_deployment_attribute_value FOR EACH ROW execute procedure connect.trg_asset_deployment_attribute_value();




CREATE OR REPLACE FUNCTION connect.trg_asset_history_record() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.asset i WHERE i.uuid = ROW.asset_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_history_record AFTER INSERT OR UPDATE OR DELETE ON smart.asset_history_record FOR EACH ROW execute procedure connect.trg_asset_history_record();



CREATE OR REPLACE FUNCTION connect.trg_asset_station_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'attribute_uuid', ROW.attribute_uuid, null, null, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_attribute FOR EACH ROW execute procedure connect.trg_asset_station_attribute();


CREATE OR REPLACE FUNCTION connect.trg_asset_station_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'station_uuid', ROW.station_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_attribute_value FOR EACH ROW execute procedure connect.trg_asset_station_attribute_value();


CREATE OR REPLACE FUNCTION connect.trg_asset_type_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'asset_type_uuid', ROW.asset_type_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_type_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.asset_type_attribute FOR EACH ROW execute procedure connect.trg_asset_type_attribute();
CREATE TRIGGER trg_asset_type_deployment_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.asset_type_deployment_attribute FOR EACH ROW execute procedure connect.trg_asset_type_attribute();


CREATE OR REPLACE FUNCTION connect.trg_asset_waypoint() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.waypoint i WHERE i.uuid = ROW.wp_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_waypoint AFTER INSERT OR UPDATE OR DELETE ON smart.asset_waypoint FOR EACH ROW execute procedure connect.trg_asset_waypoint();


CREATE OR REPLACE FUNCTION connect.trg_asset_waypoint_attachment() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'wp_attachment_uuid', ROW.wp_attachment_uuid, 'asset_waypoint_uuid', ROW.asset_waypoint_uuid, null, i.CA_UUID 
 		from smart.asset_waypoint wp, smart.waypoint i WHERE i.uuid = wp.wp_uuid and wp.uuid = ROW.asset_waypoint_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_waypoint_attachment AFTER INSERT OR UPDATE OR DELETE ON smart.asset_waypoint_attachment FOR EACH ROW execute procedure connect.trg_asset_waypoint_attachment();

CREATE OR REPLACE FUNCTION connect.trg_asset_station_location_history() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.asset_station_location loc, smart.asset_station i WHERE i.uuid = loc.station_uuid and loc.uuid = ROW.station_location_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_location_history AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_location_history FOR EACH ROW execute procedure connect.trg_asset_station_location_history();



CREATE OR REPLACE FUNCTION connect.trg_asset_station_location() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.uuid, null, null, null, i.CA_UUID 
 		from smart.asset_station i WHERE i.uuid = ROW.station_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_location AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_location FOR EACH ROW execute procedure connect.trg_asset_station_location();


CREATE OR REPLACE FUNCTION connect.trg_asset_station_location_attribute() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'attribute_uuid', ROW.attribute_uuid, null, null, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_location_attribute AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_location_attribute FOR EACH ROW execute procedure connect.trg_asset_station_location_attribute();



CREATE OR REPLACE FUNCTION connect.trg_asset_station_location_attribute_value() RETURNS trigger AS $$ DECLARE ROW RECORD; BEGIN IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN ROW = NEW; ELSIF (TG_OP = 'DELETE') THEN ROW = OLD; END IF;
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'station_location_uuid', ROW.station_location_uuid, 'attribute_uuid', ROW.attribute_uuid, null, i.CA_UUID 
 		from smart.asset_attribute i WHERE i.uuid = ROW.attribute_uuid;
RETURN ROW; END$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trg_asset_station_location_attribute_value AFTER INSERT OR UPDATE OR DELETE ON smart.asset_station_location_attribute_value FOR EACH ROW execute procedure connect.trg_asset_station_location_attribute_value();


-- Asset Queries 

insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.asset.query', '1.0');
insert into connect.ca_plugin_version (ca_uuid, plugin_id, version) select ca_uuid, 'org.wcs.smart.asset.query', '1.0' from connect.ca_info;

CREATE TABLE SMART.ASSET_OBSERVATION_QUERY(
 UUID UUID NOT NULL,
 ID VARCHAR(6) NOT NULL,
 CREATOR_UUID UUID NOT NULL,
 QUERY_FILTER VARCHAR(32672),
 CA_FILTER VARCHAR(32672),
 CA_UUID UUID NOT NULL,
 FOLDER_UUID UUID,
 COLUMN_FILTER VARCHAR(32672),
 STYLE VARCHAR,
 SHARED BOOLEAN NOT NULL,
 SHOW_DATA_COLUMNS_ONLY BOOLEAN,
 PRIMARY KEY (UUID)
);
 
CREATE TABLE SMART.ASSET_WAYPOINT_QUERY(
 UUID UUID NOT NULL,
 ID VARCHAR(6) NOT NULL,
 CREATOR_UUID UUID NOT NULL,
 QUERY_FILTER VARCHAR(32672),
 CA_FILTER VARCHAR(32672),
 CA_UUID UUID NOT NULL,
 FOLDER_UUID UUID,
 COLUMN_FILTER VARCHAR(32672),
 SURVEYDESIGN_KEY VARCHAR(128),
 SHARED BOOLEAN NOT NULL,
 STYLE  VARCHAR,
 PRIMARY KEY (UUID)
);


CREATE TABLE SMART.ASSET_SUMMARY_QUERY(
 UUID UUID NOT NULL,
 ID VARCHAR(6) NOT NULL, 
 CREATOR_UUID UUID NOT NULL,
 QUERY_DEF VARCHAR(32672),
 CA_FILTER VARCHAR(32672),
 CA_UUID UUID NOT NULL,
 FOLDER_UUID UUID, 
 SHARED BOOLEAN NOT NULL, 
 STYLE  VARCHAR,
 PRIMARY KEY (UUID)
);


ALTER TABLE SMART.ASSET_OBSERVATION_QUERY ADD FOREIGN KEY (CREATOR_UUID) REFERENCES SMART.EMPLOYEE(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE SMART.ASSET_OBSERVATION_QUERY ADD FOREIGN KEY (CA_UUID) REFERENCES SMART.CONSERVATION_AREA(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE SMART.ASSET_OBSERVATION_QUERY ADD FOREIGN KEY (FOLDER_UUID) REFERENCES SMART.QUERY_FOLDER(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE SMART.ASSET_WAYPOINT_QUERY ADD FOREIGN KEY (CREATOR_UUID) REFERENCES SMART.EMPLOYEE(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE SMART.ASSET_WAYPOINT_QUERY ADD FOREIGN KEY (CA_UUID) REFERENCES SMART.CONSERVATION_AREA(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE SMART.ASSET_WAYPOINT_QUERY ADD FOREIGN KEY (FOLDER_UUID) REFERENCES SMART.QUERY_FOLDER(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE SMART.ASSET_SUMMARY_QUERY ADD FOREIGN KEY (CREATOR_UUID) REFERENCES SMART.EMPLOYEE(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;  				
ALTER TABLE SMART.ASSET_SUMMARY_QUERY ADD FOREIGN KEY (CA_UUID) REFERENCES SMART.CONSERVATION_AREA(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;   				
ALTER TABLE SMART.ASSET_SUMMARY_QUERY ADD FOREIGN KEY (FOLDER_UUID) REFERENCES SMART.QUERY_FOLDER(UUID)  ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;				

CREATE TRIGGER trg_asset_observation_query AFTER INSERT OR UPDATE OR DELETE ON smart.asset_observation_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_waypoint_query AFTER INSERT OR UPDATE OR DELETE ON smart.asset_waypoint_query FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_asset_summary_query AFTER INSERT OR UPDATE OR DELETE ON smart.asset_summary_query FOR EACH ROW execute procedure connect.trg_changelog_common();

-- updates for patrol plug in
CREATE TABLE smart.patrol_folder (
	uuid uuid not null, 
	ca_uuid uuid not null, 
	parent_uuid uuid, 
	folder_order smallint, 
	primary key (uuid)
);
ALTER TABLE smart.patrol_folder ADD FOREIGN KEY (CA_UUID) REFERENCES SMART.CONSERVATION_AREA(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.patrol_folder ADD FOREIGN KEY (PARENT_UUID) REFERENCES SMART.PATROL_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.patrol ADD COLUMN folder_uuid UUID;
ALTER TABLE smart.patrol ADD FOREIGN KEY (FOLDER_UUID) REFERENCES SMART.PATROL_FOLDER(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_patrol_folder AFTER INSERT OR UPDATE OR DELETE ON smart.patrol_folder FOR EACH ROW execute procedure connect.trg_changelog_common();

--UPDATE FUNCTION TO Work with linestring or multilinestring Tracks
--linestring might be a linestring or multi line string
CREATE OR REPLACE FUNCTION smart.computeHoursPoly(polygon bytea, linestring bytea) RETURNS double precision AS $$
DECLARE
  ls geometry;
  p geometry;
  value double precision;
  ctime double precision;
  clength double precision;
  i integer;
  pnttemp geometry;
  pnttemp2 geometry;
  lstemp geometry;
BEGIN
	ls := st_geomfromwkb(linestring);
	p := st_geomfromwkb(polygon);
	
	IF (UPPER(st_geometrytype(ls)) = 'ST_MULTILINESTRING' ) THEN
		ctime = 0;
		FOR i in 1..ST_NumGeometries(ls) LOOP
			ctime := ctime + smart.computeHoursPoly(polygon, st_geometryn(ls, i));
		END LOOP;
		RETURN ctime;
	END IF;
	
	--wholly contained use entire time
	IF not st_isvalid(ls) and st_length(ls) = 0 THEN
		pnttemp = st_pointn(ls, 1);
		IF (smart.pointinpolygon(st_x(pnttemp),st_y(pnttemp), p)) THEN
			RETURN (st_z(st_endpoint(ls)) - st_z(st_startpoint(ls))) / 3600000.0;
		END IF;
		RETURN 0;
	END IF;
	
	IF (st_contains(p, ls)) THEN
		return (st_z(st_endpoint(ls)) - st_z(st_startpoint(ls))) / 3600000.0;
	END IF;
	
	value := 0;
	FOR i in 1..ST_NumPoints(ls)-1 LOOP
		pnttemp := st_pointn(ls, i);
		pnttemp2 := st_pointn(ls, i+1);
		lstemp := st_makeline(pnttemp, pnttemp2);	
		IF (NOT st_intersects(st_envelope(ls), st_envelope(lstemp))) THEN
			--do nothing; outside envelope
		ELSE
			IF (ST_COVERS(p, lstemp)) THEN
				value := value + st_z(pnttemp2) - st_z(pnttemp);
			ELSIF (ST_INTERSECTS(p, lstemp)) THEN
				ctime := st_z(pnttemp2) - st_z(pnttemp);
				clength := st_distance(pnttemp, pnttemp2);
				IF (clength = 0) THEN
					--points are the same and intersect so include the entire time
					value := value + ctime;
				ELSE
					--part in part out so linearly interpolate
					value := value + (ctime * (st_length(st_intersection(p, lstemp)) / clength));
				END IF;
			END IF;
		END IF;
	END LOOP;
	RETURN value / 3600000.0;
END;
$$LANGUAGE plpgsql;

-- also update to support track multilinestrings
CREATE OR REPLACE FUNCTION smart.trackIntersects(geom1 bytea, geom2 bytea) RETURNS BOOLEAN AS $$
DECLARE
  ls geometry;
  pnt geometry;
BEGIN
	ls := st_geomfromwkb(geom1);
	
	IF (UPPER(st_geometrytype(ls)) = 'ST_MULTILINESTRING' ) THEN
		FOR i in 1..ST_NumGeometries(ls) LOOP
			IF (smart.trackIntersects(st_geometryn(ls, i), geom2)) THEN
				RETURN true;
			END IF;
		END LOOP;
	END IF;
	if not st_isvalid(ls) and st_length(ls) = 0 then
		pnt = st_pointn(ls, 1);
		return smart.pointinpolygon(st_x(pnt),st_y(pnt),geom2);
	else
		RETURN ST_INTERSECTS(ls, st_geomfromwkb(geom2));
	end if;

END;
$$LANGUAGE plpgsql;


--GFW
CREATE TABLE connect.gfw(
	uuid uuid not null,
	alert_uuid uuid not null,
	last_data timestamp,
	creator_uuid uuid not null,
	level smallint not null,
	primary key (uuid)
);
ALTER TABLE connect.gfw ADD FOREIGN KEY (alert_uuid) REFERENCES connect.alert_types(uuid);
ALTER TABLE connect.gfw ADD FOREIGN KEY (creator_uuid) REFERENCES connect.users(uuid); 

-- DROP not null constraint from Conervation Area of alerts for global forest watch alerts
--which will not have a conservation area
alter table connect.alerts alter column ca_uuid drop not null;
--add not null constraint to alerts
-- at a minimum this should be set to [[x,y]]
alter table connect.alerts alter column track set not null;


ALTER TABLE connect.ca_info DROP CONSTRAINT status_chk;

-- UPDATE VERSION
ALTER TABLE connect.connect_version ADD COLUMN filestore_version varchar(5) default '-1';

UPDATE connect.connect_plugin_version SET version = '6.0.0' WHERE plugin_id = 'org.wcs.smart';
UPDATE connect.ca_plugin_version SET version = '6.0.0' WHERE plugin_id = 'org.wcs.smart';

update connect.ca_plugin_version set plugin_id = 'org.wcs.smart.cybertracker.survey' where plugin_id = 'org.wcs.smart.connect.dataqueue.cybertracker.survey';
update connect.ca_plugin_version set plugin_id = 'org.wcs.smart.cybertracker.patrol' where plugin_id = 'org.wcs.smart.connect.dataqueue.cybertracker.patrol';
update connect.connect_plugin_version set plugin_id = 'org.wcs.smart.cybertracker.survey' where plugin_id = 'org.wcs.smart.connect.dataqueue.cybertracker.survey';
update connect.connect_plugin_version set plugin_id = 'org.wcs.smart.cybertracker.patrol' where plugin_id = 'org.wcs.smart.connect.dataqueue.cybertracker.patrol';

--database version
update connect.connect_version set version = '6.0.0';
--flag the filestore as not upgraded; this will require administrator to upgrade before you can login
update connect.connect_version set filestore_version = '5.0.0';
CREATE TABLE smart.r_script(
   uuid UUID NOT NULL, 
   ca_uuid UUID NOT NULL,
   filename varchar(2048) NOT NULL, 
   creator_uuid UUID NOT NULL, 
   default_parameters varchar(32672), 
   PRIMARY KEY (uuid)
);
   
CREATE TABLE smart.r_query(
  uuid UUID NOT NULL, 
  script_uuid UUID NOT NULL, 
  ca_uuid UUID not null, 
  config varchar(32672), 
  PRIMARY KEY (uuid)
);

ALTER TABLE smart.r_script ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
ALTER TABLE smart.r_script ADD FOREIGN KEY (creator_uuid) REFERENCES smart.employee(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
ALTER TABLE smart.r_query ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
ALTER TABLE smart.r_query ADD FOREIGN KEY (script_uuid) REFERENCES smart.r_script(uuid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

CREATE TRIGGER trg_qa_routine AFTER INSERT OR UPDATE OR DELETE ON smart.r_script FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_qa_routine AFTER INSERT OR UPDATE OR DELETE ON smart.r_query FOR EACH ROW execute procedure connect.trg_changelog_common();


alter table connect.shared_links add column permissionuser_uuid uuid ;
ALTER TABLE connect.shared_links ADD FOREIGN KEY (permissionuser_uuid) REFERENCES connect.users(uuid) ON DELETE CASCADE ;

insert into connect.connect_plugin_version (plugin_id, version) values ('org.wcs.smart.r', '1.0');
 
update connect.connect_plugin_version set version = '6.0.1' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '6.0.1' where plugin_id = 'org.wcs.smart';

update connect.connect_version set version = '6.0.1';				
-- last modified date and last modified by for waypoint
ALTER TABLE smart.waypoint ADD COLUMN last_modified timestamp;
UPDATE smart.waypoint SET last_modified = datetime;
ALTER TABLE smart.waypoint ALTER COLUMN last_modified SET NOT NULL;
ALTER TABLE smart.waypoint ADD COLUMN last_modified_by uuid;
 
-- incident to group id link for cybertracker
CREATE TABLE smart.ct_incident_link (
  uuid uuid  not null, 
  ct_group_id uuid not null, 
  wp_uuid uuid not null, 
  last_cnt integer not null, 
  primary key (uuid)
);		

ALTER TABLE smart.ct_incident_link ADD FOREIGN KEY (wp_uuid) REFERENCES smart.waypoint(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;
				 
CREATE OR REPLACE FUNCTION connect.trg_ct_incident_link() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, wp.CA_UUID 
 		FROM smart.waypoint wp WHERE wp.uuid = ROW.wp_uuid;
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';
CREATE TRIGGER trg_ct_incident_link AFTER INSERT OR UPDATE OR DELETE ON smart.ct_incident_link FOR EACH ROW execute procedure connect.trg_ct_incident_link();


--support for svg images
ALTER TABLE smart.cm_node add column imagetype varchar(32);
ALTER TABLE smart.cm_attribute_list add column imagetype varchar(32);
ALTER TABLE smart.cm_attribute_tree_node add column imagetype varchar(32);

--smart source for records
alter table smart.i_record ADD COLUMN smart_source varchar(2048);

update connect.connect_plugin_version set version = '4.0' where plugin_id = 'org.wcs.smart.i2';
update connect.ca_plugin_version set version = '4.0' where plugin_id = 'org.wcs.smart.i2';

update connect.connect_plugin_version set version = '5.0' where plugin_id = 'org.wcs.smart.cybertracker';
update connect.ca_plugin_version set version = '5.0' where plugin_id = 'org.wcs.smart.cybertracker';

update connect.connect_plugin_version set version = '6.1.0' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '6.1.0' where plugin_id = 'org.wcs.smart';

update connect.connect_version set version = '6.1.0';	
			--ICON SUPORT
CREATE TABLE smart.iconset (
  uuid UUID not null, 
  keyid varchar(64) not null, 
  ca_uuid UUID not null, 
  is_default boolean default false not null, 
  primary key(uuid)
);

CREATE TABLE smart.icon (
  uuid UUID not null,
  keyid varchar(64) not null,
  ca_uuid UUID not null,
  primary key(uuid)
);

CREATE TABLE smart.iconfile (
  uuid UUID not null, 
  icon_uuid UUID not null, 
  iconset_uuid UUID not null, 
  filename varchar(2064) not null, 
  primary key(uuid)
);
				
ALTER TABLE smart.dm_category add column icon_uuid UUID;
ALTER TABLE smart.dm_attribute add column icon_uuid UUID;
ALTER TABLE smart.dm_attribute_list add column icon_uuid UUID;
ALTER TABLE smart.dm_attribute_tree add column icon_uuid UUID;

ALTER TABLE smart.ct_incident_link ADD FOREIGN KEY (wp_uuid) REFERENCES smart.waypoint(UUID) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

ALTER TABLE smart.dm_category ADD FOREIGN KEY (icon_uuid) REFERENCES smart.icon(uuid) ON DELETE SET NULL ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.dm_attribute ADD FOREIGN KEY (icon_uuid) REFERENCES smart.icon(uuid) ON DELETE SET NULL ON UPDATE RESTRICT  DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.dm_attribute_list ADD FOREIGN KEY (icon_uuid) REFERENCES smart.icon(uuid) ON DELETE SET NULL ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.dm_attribute_tree ADD FOREIGN KEY (icon_uuid) REFERENCES smart.icon(uuid) ON DELETE SET NULL ON UPDATE RESTRICT  DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE smart.configurable_model add column iconset_uuid UUID;
ALTER TABLE smart.configurable_model ADD FOREIGN KEY (iconset_uuid) REFERENCES smart.iconset(uuid) ON DELETE SET NULL ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE smart.iconset ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.icon ADD FOREIGN KEY (ca_uuid) REFERENCES smart.conservation_area(uuid) ON DELETE CASCADE ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.iconfile ADD FOREIGN KEY (icon_uuid) REFERENCES smart.icon(uuid) ON DELETE CASCADE ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE smart.iconfile ADD FOREIGN KEY (iconset_uuid) REFERENCES smart.iconset(uuid) ON DELETE CASCADE ON UPDATE RESTRICT DEFERRABLE INITIALLY DEFERRED;


CREATE TRIGGER trg_iconset AFTER INSERT OR UPDATE OR DELETE ON smart.iconset FOR EACH ROW execute procedure connect.trg_changelog_common();
CREATE TRIGGER trg_icon AFTER INSERT OR UPDATE OR DELETE ON smart.icon FOR EACH ROW execute procedure connect.trg_changelog_common();


CREATE OR REPLACE FUNCTION connect.trg_iconfile() RETURNS trigger AS $$
	DECLARE
	ROW RECORD;
BEGIN
	IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN	
 	ROW = NEW;
 	ELSIF (TG_OP = 'DELETE') THEN
 		ROW = OLD;
 	END IF;
 
 	INSERT INTO connect.change_log 
 		(uuid, action, tablename, key1_fieldname, key1, key2_fieldname, key2_uuid, key2_str, ca_uuid) 
 		SELECT uuid_generate_v4(), TG_OP, TG_TABLE_SCHEMA::TEXT || '.' || TG_TABLE_NAME::TEXT, 'uuid', ROW.UUID, null, null, null, iset.CA_UUID 
 		FROM smart.iconset iset WHERE iset.uuid = ROW.iconset_uuid;
 RETURN ROW;
END$$ LANGUAGE 'plpgsql';
CREATE TRIGGER trg_iconfile AFTER INSERT OR UPDATE OR DELETE ON smart.iconfile FOR EACH ROW execute procedure connect.trg_iconfile();




update connect.connect_plugin_version set version = '6.2.0' where plugin_id = 'org.wcs.smart';
update connect.ca_plugin_version set version = '6.2.0' where plugin_id = 'org.wcs.smart';

update connect.connect_version set version = '6.2.0', last_updated = now();		
update connect.connect_version set filestore_version = '6.2.0';