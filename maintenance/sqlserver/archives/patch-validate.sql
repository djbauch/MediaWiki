-- For article validation

DROP TABLE IF EXISTS /*$wgDBprefix*/validate;
CREATE TABLE /*$wgDBprefix*/validate (
  [val_user] int NOT NULL default 0,
  [val_page] int NOT NULL default 0,
  [val_revision] int  NOT NULL default 0,
  [val_type] int  NOT NULL default 0,
  [val_value] int default 0,
  [val_comment] varchar(255) NOT NULL default '',
  [val_ip] varchar(20) NOT NULL default '',
  CONSTRAINT [val_user] PRIMARY KEY ([val_user],[val_revision])
) /*$wgDBTableOptions*/;
