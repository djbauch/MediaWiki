ALTER TABLE /*$wgDBprefix*/interwiki
	ADD COLUMN iw_trans BIT NOT NULL DEFAULT 0;
