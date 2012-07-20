CREATE TABLE /*$wgDBprefix*/category (
  cat_id INT NOT NULL IDENTITY,

  cat_title COLLATE SQL_Latin1_General_CP1_CS_AS NVARCHAR(255) NOT NULL,

  cat_pages INT  NOT NULL default 0,
  cat_subcats INT  NOT NULL default 0,
  cat_files INT  NOT NULL default 0,

  cat_hidden BIT NOT NULL default 0,

  PRIMARY KEY (cat_id),
  UNIQUE KEY (cat_title),

  KEY (cat_pages)
) /*$wgDBTableOptions*/;
