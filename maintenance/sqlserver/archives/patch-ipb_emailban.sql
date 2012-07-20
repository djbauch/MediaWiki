-- Add row for email blocks --

ALTER TABLE /*$wgDBprefix*/ipblocks
	ADD ipb_block_email BIT NOT NULL default 0;
