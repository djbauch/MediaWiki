-- For a few generic cache operations if not using Memcached
CREATE TABLE /*$wgDBprefix*/objectcache (
  keyname varchar(255) NOT NULL default '',
  [value] NVARCHAR(3766),
  exptime VARCHAR(14)
) /*$wgDBTableOptions*/;
CREATE CLUSTERED INDEX /*$wgDBprefix*/objectcache_time ON /*$wgDBprefix*/objectcache(exptime);
CREATE UNIQUE INDEX /*$wgDBprefix*/objectcache_PK ON /*wgDBprefix*/objectcache(keyname);
