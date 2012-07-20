CREATE TABLE /*$wgDBprefix*/langlinks (
  -- page_id of the referring page
  ll_from int NOT NULL default '0',

  -- Language code of the target
  ll_lang VARCHAR(20) NOT NULL default '',

  -- Title of the target, including namespace
  ll_title varchar(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*$wgDBprefix*/langlinks_pk PRIMARY KEY (ll_from, ll_lang)
) /*$wgDBTableOptions*/;
CREATE UNIQUE INDEX /*$wgDBprefix*/langlinks_reverse_key ON /*$wgDBprefix*/langlinks(ll_lang,ll_title);
;
