-- Name/value pairs indexed by page_id
CREATE TABLE /*$wgDBprefix*/page_props (
  pp_page int NOT NULL,
  pp_propname VARCHAR(60) NOT NULL,
  pp_value VARCHAR(8000) NOT NULL,

  CONSTRAINT /*$wgDBprefix*/pk_page_props PRIMARY KEY (pp_page,pp_propname)
) /*$wgDBTableOptions*/;
