--- this is deprecated and will go away soon, don't use it going forward!
drop table if exists tk_users;
create table tk_users (
    id integer primary key autoincrement,
    callsign text not null,
    password text default null,
    privileges text default '' not null,
    disabled integer default 0
);

insert into tk_users (callsign, password, privileges) values ('GUEST', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'guest listen');
