-- Timestamp of the last time when a new password was
-- sent, for throttling purposes
ALTER TABLE /*$wgDBprefix*/user2 ADD user_newpass_time DATETIME NULL;
