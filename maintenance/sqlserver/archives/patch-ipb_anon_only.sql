-- Add extra option fields to the ipblocks table, add some extra indexes,
-- convert infinity values in ipb_expiry to something that sorts better,
-- extend ipb_address and range fields, add a unique index for block conflict
-- detection.

-- Conflicts in the new unique index can be handled by creating a new
-- table and inserting into it instead of doing an ALTER TABLE.


DROP TABLE IF EXISTS /*$wgDBprefix*/ipblocks_newunique;

CREATE TABLE /*$wgDBprefix*/ipblocks_newunique (
  ipb_id int NOT NULL IDENTITY,
  ipb_address VARCHAR(255) NOT NULL,
  ipb_user int NOT NULL default 0,
  ipb_by int NOT NULL default 0,
  ipb_reason VARCHAR(255) NOT NULL,
  ipb_timestamp DATETIME NOT NULL default CURRENT_TIMESTAMP,
  ipb_auto BIT NOT NULL default 0,
  ipb_anon_only BIT NOT NULL default 0,
  ipb_create_account BIT NOT NULL default 1,
  ipb_expiry DATETIME NOT NULL default CURRENT_TIMESTAMP,
  ipb_range_start VARCHAR(255) NOT NULL,
  ipb_range_end VARCHAR(255) NOT NULL,

  CONSTRAINT /*$wgDBprefix*/ipb_id PRIMARY KEY ipb_id (ipb_id)
) /*$wgDBTableOptions*/;
CREATE UNIQUE INDEX /*$wgDBprefix*/ipbnu_address   ON /*$wgDBprefix*/ipblocks_newunique(ipb_address, ipb_user, ipb_auto);
CREATE        INDEX /*$wgDBprefix*/ipbnu_user      ON /*$wgDBprefix*/ipblocks_newunique(ipb_user);
CREATE        INDEX /*$wgDBprefix*/ipbnu_range     ON /*$wgDBprefix*/ipblocks_newunique(ipb_range_start, ipb_range_end);
CREATE        INDEX /*$wgDBprefix*/ipbnu_timestamp ON /*$wgDBprefix*/ipblocks_newunique(ipb_timestamp);
CREATE        INDEX /*$wgDBprefix*/ipbnu_expiry    ON /*$wgDBprefix*/ipblocks_newunique(ipb_expiry);
;
--MySQL says INSERT IGNORE INTO..., see what that is.
INSERT INTO /*$wgDBprefix*/ipblocks_newunique
        (ipb_id, ipb_address, ipb_user, ipb_by, ipb_reason, ipb_timestamp, ipb_auto, ipb_expiry, ipb_range_start, ipb_range_end, ipb_anon_only, ipb_create_account)
  SELECT ipb_id, ipb_address, ipb_user, ipb_by, ipb_reason, ipb_timestamp, ipb_auto, ipb_expiry, ipb_range_start, ipb_range_end, 0            , ipb_user=0
  FROM /*$wgDBprefix*/ipblocks;

DROP TABLE IF EXISTS /*$wgDBprefix*/ipblocks_old;
RENAME TABLE /*$wgDBprefix*/ipblocks TO /*$wgDBprefix*/ipblocks_old;
RENAME TABLE /*$wgDBprefix*/ipblocks_newunique TO /*$wgDBprefix*/ipblocks;

--UPDATE /*$wgDBprefix*/ipblocks SET ipb_expiry='infinity' WHERE ipb_expiry='';
