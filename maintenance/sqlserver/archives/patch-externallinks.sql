--
-- Track links to external URLs
--
CREATE TABLE /*$wgDBprefix*/externallinks (
  el_from int NOT NULL default 0,
  el_to VARCHAR(896) NOT NULL,
  el_index VARCHAR(896) NOT NULL,
) /*$wgDBTableOptions*/;
-- Maximum key length ON SQL Server is 900 bytes
CREATE INDEX /*$wgDBprefix*/externallinks_to_from ON /*$wgDBprefix*/externallinks(el_to,el_from);
CREATE INDEX /*$wgDBprefix*/externallinks_from_to ON /*$wgDBprefix*/externallinks(el_from,el_to);
CREATE INDEX /*$wgDBprefix*/externallinks_index   ON /*$wgDBprefix*/externallinks(el_index);
;
