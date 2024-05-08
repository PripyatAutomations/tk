--- this is deprecated and will go away soon, don't use it going forward!
drop table if exists tk_rigs;
create table tk_rigs (
   id integer primary key autoincrement,
   name text unique not null,
   rigctl_model text not null,
   rigctl_port int not null,
   view text not null default "rig-generic",
   disabled integer default 0
);
insert into tk_rigs ( name, rigctl_model, rigctl_port ) values ( "ft891", 1036, 4532 );
