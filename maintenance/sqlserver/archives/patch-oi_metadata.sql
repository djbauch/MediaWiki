--
-- patch-oi_metadata.sql
--
-- Add data to allow for direct reference to old images
-- Some re-indexing here.
-- Old images can be included into pages effeciently now.
--

ALTER TABLE /*$wgDBprefix*/oldimage
   DROP INDEX oi_name,
   ADD INDEX oi_name_timestamp (oi_name,oi_timestamp),
   ADD INDEX oi_name_archive_name (oi_name,oi_archive_name),
   ADD oi_metadata IMAGE NOT NULL,
   ADD oi_media_type VARCHAR(11) default NULL,
   ADD oi_major_mime VARCHAR(11) NOT NULL default 'UNKNOWN',
   ADD oi_minor_mime varchar(32) NOT NULL default 'UNKNOWN',
   ADD oi_deleted BIT  NOT NULL default 0;
