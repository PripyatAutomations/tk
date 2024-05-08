create table peers (
   peer_id integer primary key autoincrement,
   --- Callsign of node
   peer_callsign TEXT,
   --- SSID of node
   peer_ssid INTEGER,
   --- Port IAX connections will be sent to
   peer_iax_port integer,
   --- Port to connect wireguard FROM or 0
   peer_wg_port_out integer default 0,
   --- Port to connect wireguard TO or 0 if NAT peer
   peer_wg_port_in integer default 0,
);
