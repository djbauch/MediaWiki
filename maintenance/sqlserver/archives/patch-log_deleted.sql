-- Adding ar_deleted field for revisiondelete
ALTER TABLE /*$wgDBprefix*/logging
  ADD log_deleted BIT NOT NULL default '0';
