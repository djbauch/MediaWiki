-- Adding ar_deleted field for revisiondelete
ALTER TABLE /*$wgDBprefix*/archive
  ADD ar_deleted BIT NOT NULL default '0';
