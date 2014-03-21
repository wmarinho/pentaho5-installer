--Begin--
-- note: this script assumes pg_hba.conf is configured correctly
--

-- \connect postgres postgres

ALTER DATABASE quartz  OWNER TO awsbiuser;

drop database if exists quartz;
--drop user if exists pentaho_user;
drop role if exists pentaho_user;

--CREATE USER pentaho_user PASSWORD '@@pentaho_user@@';
create role pentaho_user with password '@@pentaho_user@@' login;

CREATE DATABASE quartz   ENCODING = 'UTF8' TABLESPACE = pg_default;

--ALTER DATABASE quartz OWNER TO pentaho_user;
--GRANT ALL ON DATABASE quartz to pentaho_user;

--End--
--Begin Connect--
--\connect quartz pentaho_user
\connect quartz

begin;

drop table if exists "QRTZ";
drop table if exists qrtz5_job_listeners;
drop table if exists qrtz5_trigger_listeners;
drop table if exists qrtz5_fired_triggers;
drop table if exists qrtz5_paused_trigger_grps;
drop table if exists qrtz5_scheduler_state;
drop table if exists qrtz5_locks;
drop table if exists qrtz5_simple_triggers;
drop table if exists qrtz5_cron_triggers;
drop table if exists qrtz5_blob_triggers;
drop table if exists qrtz5_triggers;
drop table if exists qrtz5_job_details;
drop table if exists qrtz5_calendars;

CREATE TABLE "QRTZ" ( NAME VARCHAR(200) NOT NULL, PRIMARY KEY (NAME) );
CREATE TABLE qrtz5_job_details
  (
    JOB_NAME  VARCHAR(200) NOT NULL,
    JOB_GROUP VARCHAR(200) NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    JOB_CLASS_NAME   VARCHAR(250) NOT NULL, 
    IS_DURABLE BOOL NOT NULL,
    IS_VOLATILE BOOL NOT NULL,
    IS_STATEFUL BOOL NOT NULL,
    REQUESTS_RECOVERY BOOL NOT NULL,
    JOB_DATA BYTEA NULL,
    PRIMARY KEY (JOB_NAME,JOB_GROUP)
);

CREATE TABLE qrtz5_job_listeners
  (
    JOB_NAME  VARCHAR(200) NOT NULL, 
    JOB_GROUP VARCHAR(200) NOT NULL,
    JOB_LISTENER VARCHAR(200) NOT NULL,
    PRIMARY KEY (JOB_NAME,JOB_GROUP,JOB_LISTENER),
    FOREIGN KEY (JOB_NAME,JOB_GROUP) 
	REFERENCES qrtz5_JOB_DETAILS(JOB_NAME,JOB_GROUP) 
);

CREATE TABLE qrtz5_triggers
  (
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    JOB_NAME  VARCHAR(200) NOT NULL, 
    JOB_GROUP VARCHAR(200) NOT NULL,
    IS_VOLATILE BOOL NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    NEXT_FIRE_TIME BIGINT NULL,
    PREV_FIRE_TIME BIGINT NULL,
    PRIORITY INTEGER NULL,
    TRIGGER_STATE VARCHAR(16) NOT NULL,
    TRIGGER_TYPE VARCHAR(8) NOT NULL,
    START_TIME BIGINT NOT NULL,
    END_TIME BIGINT NULL,
    CALENDAR_NAME VARCHAR(200) NULL,
    MISFIRE_INSTR SMALLINT NULL,
    JOB_DATA BYTEA NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (JOB_NAME,JOB_GROUP) 
	REFERENCES qrtz5_JOB_DETAILS(JOB_NAME,JOB_GROUP) 
);

CREATE TABLE qrtz5_simple_triggers
  (
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    REPEAT_COUNT BIGINT NOT NULL,
    REPEAT_INTERVAL BIGINT NOT NULL,
    TIMES_TRIGGERED BIGINT NOT NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) 
	REFERENCES qrtz5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE qrtz5_cron_triggers
  (
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    CRON_EXPRESSION VARCHAR(120) NOT NULL,
    TIME_ZONE_ID VARCHAR(80),
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) 
	REFERENCES qrtz5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE qrtz5_blob_triggers
  (
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    BLOB_DATA BYTEA NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) 
        REFERENCES qrtz5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE qrtz5_trigger_listeners
  (
    TRIGGER_NAME  VARCHAR(200) NOT NULL, 
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    TRIGGER_LISTENER VARCHAR(200) NOT NULL,
    PRIMARY KEY (TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_LISTENER),
    FOREIGN KEY (TRIGGER_NAME,TRIGGER_GROUP) 
	REFERENCES qrtz5_TRIGGERS(TRIGGER_NAME,TRIGGER_GROUP)
);


CREATE TABLE qrtz5_calendars
  (
    CALENDAR_NAME  VARCHAR(200) NOT NULL, 
    CALENDAR BYTEA NOT NULL,
    PRIMARY KEY (CALENDAR_NAME)
);


CREATE TABLE qrtz5_paused_trigger_grps
  (
    TRIGGER_GROUP  VARCHAR(200) NOT NULL, 
    PRIMARY KEY (TRIGGER_GROUP)
);

CREATE TABLE qrtz5_fired_triggers 
  (
    ENTRY_ID VARCHAR(95) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    IS_VOLATILE BOOL NOT NULL,
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    FIRED_TIME BIGINT NOT NULL,
    PRIORITY INTEGER NOT NULL,
    STATE VARCHAR(16) NOT NULL,
    JOB_NAME VARCHAR(200) NULL,
    JOB_GROUP VARCHAR(200) NULL,
    IS_STATEFUL BOOL NULL,
    REQUESTS_RECOVERY BOOL NULL,
    PRIMARY KEY (ENTRY_ID)
);

CREATE TABLE qrtz5_scheduler_state 
  (
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    LAST_CHECKIN_TIME BIGINT NOT NULL,
    CHECKIN_INTERVAL BIGINT NOT NULL,
    PRIMARY KEY (INSTANCE_NAME)
);

CREATE TABLE qrtz5_locks
  (
    LOCK_NAME  VARCHAR(40) NOT NULL, 
    PRIMARY KEY (LOCK_NAME)
);

INSERT INTO qrtz5_locks values('TRIGGER_ACCESS');
INSERT INTO qrtz5_locks values('JOB_ACCESS');
INSERT INTO qrtz5_locks values('CALENDAR_ACCESS');
INSERT INTO qrtz5_locks values('STATE_ACCESS');
INSERT INTO qrtz5_locks values('MISFIRE_ACCESS');

ALTER TABLE "QRTZ" OWNER TO pentaho_user;
ALTER TABLE qrtz5_job_listeners OWNER TO pentaho_user;
ALTER TABLE qrtz5_trigger_listeners OWNER TO pentaho_user;
ALTER TABLE qrtz5_fired_triggers OWNER TO pentaho_user;
ALTER TABLE qrtz5_paused_trigger_grps OWNER TO pentaho_user;
ALTER TABLE qrtz5_scheduler_state OWNER TO pentaho_user;
ALTER TABLE qrtz5_locks OWNER TO pentaho_user;
ALTER TABLE qrtz5_simple_triggers OWNER TO pentaho_user;
ALTER TABLE qrtz5_cron_triggers OWNER TO pentaho_user;
ALTER TABLE qrtz5_blob_triggers OWNER TO pentaho_user;
ALTER TABLE qrtz5_triggers OWNER TO pentaho_user;
ALTER TABLE qrtz5_job_details OWNER TO pentaho_user;
ALTER TABLE qrtz5_calendars OWNER TO pentaho_user;

ALTER DATABASE quartz OWNER TO pentaho_user;
GRANT ALL ON DATABASE quartz to pentaho_user;
commit;
--End Connect--
