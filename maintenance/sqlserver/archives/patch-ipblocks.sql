-- For auto-expiring blocks --

ALTER TABLE /*$wgDBprefix*/ipblocks2
	ADD ipb_auto BIT NOT NULL default 0,
	ADD ipb_id int NOT NULL IDENTITY,
	ADD PRIMARY KEY (ipb_id);
