-- Adding ipb_deleted field for hiding usernames
ALTER TABLE /*$wgDBprefix*/ipblocks
  ADD ipb_deleted BIT NOT NULL default 0;
