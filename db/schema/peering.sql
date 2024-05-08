--- Key pairs do not have to contain a private key for both sides
--- but a private key MUST exist on the A side for peering to work!
create table peerings (
   id INTEGER NOT NULL,
   ---
   --- Information about side A
   ---
   a_callsign TEXT NOT NULL,
   a_wg_pubkey TEXT,
   a_wg_privkey TEXT,
   a_iax_passphrase TEXT,
   ---
   --- Information about side B
   ---
   b_callsign TEXT NOT NULL,
   b_wg_pubkey TEXT,
   b_wg_privkey TEXT,
   b_iax_passphrase TEXT,
   ---
   constraint peerings_pkc primary key ( id )
);
