ALTER TABLE /*$wgDBprefix*/logging2
	ADD log_user_text varchar(255) NOT NULL default '',
	ADD log_target_id int NULL,
	CHANGE log_type log_type varbinary(32) NOT NULL,
	CHANGE log_action log_action varbinary(32) NOT NULL;

CREATE INDEX /*i*/user_type_time ON /*_*/logging2 (log_user, log_type, log_timestamp);
