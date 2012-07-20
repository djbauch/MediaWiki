--
-- patch-logging-times-index.sql
--
-- Add a very humble index on logging times
--

ALTER TABLE /*$wgDBprefix*/logging2
   ADD INDEX times (log_timestamp);
