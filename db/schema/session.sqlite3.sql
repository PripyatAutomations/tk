--- this is deprecated and will go away soon, don't use it going forward!
drop table if exists tk_sessions;
create table tk_sessions (
    id integer primary key autoincrement,
    callsign text not null,
    token text not null,
    server text not null default 'localhost',
    created integer,
    last_active integer,
    sip_user text not null,
    sip_pass text not null
);
