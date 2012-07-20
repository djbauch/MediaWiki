-- Adding ipb_allow_usertalk for blocks
ALTER TABLE /*$wgDBprefix*/ipblocks2
  ADD ipb_allow_usertalk BIT NOT NULL default 1;
