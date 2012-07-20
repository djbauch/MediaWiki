--
-- Record of deleted file data
--
CREATE TABLE /*$wgDBprefix*/filearchive (
  -- Unique row id
  fa_id int not null IDENTITY,

  -- Original base filename; key to image.img_name, page.page_title, etc
  fa_name varchar(255) NOT NULL default '',

  -- Filename of archived file, if an old revision
  fa_archive_name varchar(255) default '',

  -- Which storage bin (directory tree or object store) the file data
  -- is stored in. Should be 'deleted' for files that have been deleted;
  -- any other bin is not yet in use.
  fa_storage_group varchar(16),

  -- SHA-1 of the file contents plus extension, used as a key for storage.
  -- eg 8f8a562add37052a1848ff7771a2c515db94baa9.jpg
  --
  -- If NULL, the file was missing at deletion time or has been purged
  -- from the archival storage.
  fa_storage_key varbinary(64) default '',

  -- Deletion information, if this file is deleted.
  fa_deleted_user int,
  fa_deleted_timestamp VARCHAR(14) default '',
  fa_deleted_reason VARCHAR(255),

  -- Duped fields from image
  fa_size int default 0,
  fa_width int  default 0,
  fa_height int  default 0,
  fa_metadata TEXT,
  fa_bits int  default 0,
  fa_media_type VARCHAR(11) default NULL,
  fa_major_mime VARCHAR(11) default 'unknown',
  fa_minor_mime VARCHAR(32) default 'unknown',
  fa_description VARCHAR(255),
  fa_user int default 0,
  fa_user_text varchar(255) default '',
  fa_timestamp VARCHAR(14) DEFAULT CONVERT(VARCHAR(8), CURRENT_TIMESTAMP, 112)
      + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
      + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
      + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2),

  CONSTRAINT /*$wgDBprefix*/fa_id PRIMARY KEY (fa_id),
) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/filearchive_name ON /*$wgDBprefix*/filearchive(fa_name,fa_timestamp);
-- Pick by dupe files
CREATE INDEX /*$wgDBprefix*/filearchive_dupe ON /*$wgDBprefix*/filearchive(fa_storage_group,fa_storage_key);
-- Pick by deletion time
CREATE INDEX /*$wgDBprefix*/filearchive_time ON /*$wgDBprefix*/filearchive(fa_deleted_timestamp);
-- Pick by deleter
CREATE INDEX /*$wgDBprefix*/filearchive_user ON /*$wgDBprefix*/filearchive(fa_deleted_user);
--CREATE INDEX /*$wgDBprefix*/filearchive_user_timestamp ON /*$wgDBprefix*/filearchive(fa_user_text,fa_timestamp);
;
