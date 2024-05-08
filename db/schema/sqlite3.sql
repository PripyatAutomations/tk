---
--- License Classes
---
create table license_class (
    class_id INTEGER,
    --- country code
    class_cc TEXT,
    class_name TEXT,
    class_descr TEXT
);

create table rig_bands (
   --- entry ID
   rb_id INTEGER,
   --- rig id
   rb_rig INTEGER,
   --- License class
   rb_class INTEGER,
   --- Band start (Hz)
   rb_band_start INTEGER,
   --- Band end (Hz)
   rb_band_end INTEGER
);

---
--- Remote Users
---
create table remote_users (
    local_user_id INTEGER,
    local_user_hash TEXT,
    remote_user_id INTEGER,
    remote_user_name TEXT,
    --- Pubkey presented by remote node
    remote_pubkey TEXT
);

---
--- Local User
---
create table users (
    user_id INTEGER,
    user_name TEXT,
    --- hashed node:call:password (sha256)
    user_pass TEXT,
    --- time_t of last login
    user_last_login INTEGER DEFAULT -1
);

---
--- User privileges
---
create table user_privs (
     uid INTEGER,
     --- Host id limits privileges to a single host, 0 is NOT valid
     host INTEGER,
     --- Privilege name
     priv TEXT,
     level INTEGER
);

---- Transmission log
create table tx_log (
    --- user-id of transmitting user
    tx_user INTEGER,
    --- Callsign of user transmitting
    tx_call TEXT,
    --- seconds of transmission
    tx_length INTEGER,
    --- frequency and width (hz)
    tx_freq INTEGER,
    tx_width INTEGER,
    --- TX modes: 0=NONE, 1=LSB, 2=USB, 3=AM, 4=FM, 5=C4FM, 6=DATA, 7=PKT, 8=FT8, 9=CW
    tx_mode INTEGER,
    --- SWR measurements
    tx_swr_avg FLOAT,
    tx_swr_max FLOAT,
    --- Recordings
    tx_recording TEXT DEFAULT NULL
);

create table settings_kv (
    k TEXT,
    v TEXT
);

create table hosts (
    host_id INTEGER,
    --- ip address (overlay)
    host_ip TEXT,
    --- hostname (overlay)
    host_hostname TEXT,
    --- host public key
    host_pubkey TEXT
);

create table rigs (
    --- radio host ID
    rig_host_id INTEGER,
    --- rig ID
    rig_id INTEGER
);

create table rig_access (
    --- entry id
    ra_id INTEGER,
    --- rig ID
    ra_rig INTEGER,
    --- user id
    ra_user INTEGER,

    --- Permissions
    ----- Can TX?
    ra_can_tx INTEGER,
    ----- Can change freq?
    ra_can_freq INTEGER,
    ----- Can change mode?
    ra_can_mode INTEGER,
    ----- Can tune antenna?
    ra_can_tune INTEGER
);
