--
-- Track links that do exist
-- l_from and l_to key to cur_id
--
DROP TABLE IF EXISTS /*$wgDBprefix*/links;
CREATE TABLE /*$wgDBprefix*/links (
  -- Key to the page_id of the page containing the link.
  l_from int NOT NULL default 0,

  -- Key to the page_id of the link target.
  -- An unfortunate consequence of this is that rename
  -- operations require changing the links entries for
  -- all links to the moved page.
  l_to int NOT NULL default 0,

  CONSTRAINT /*$wgDBprefix*/l_from PRIMARY KEY (l_from,l_to)
) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/links_to_index ON /*$wgDBprefix*/links(l_to);
;
--
-- Track links to pages that don't yet exist.
-- bl_from keys to cur_id
-- bl_to is a text link (namespace:title)
--
DROP TABLE IF EXISTS /*$wgDBprefix*/brokenlinks;
CREATE TABLE /*$wgDBprefix*/brokenlinks (
  -- Key to the page_id of the page containing the link.
  bl_from int NOT NULL default '0',

  -- Text of the target page title ("namesapce:title").
  -- Unfortunately this doesn't split the namespace index
  -- key and therefore can't easily be joined to anything.
  bl_to varchar(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',
  CONSTRAINT /*$wgDBprefix*/bl_from PRIMARY KEY (bl_from,bl_to),
  KEY (bl_to)

) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/brokenlinks_to_index ON /*$wgDBprefix*/brokenlinks(bl_to);
;

--
-- Track links to images *used inline*
-- il_from keys to cur_id, il_to keys to image_name.
-- We don't distinguish live from broken links.
--
DROP TABLE IF EXISTS /*$wgDBprefix*/imagelinks;
CREATE TABLE /*$wgDBprefix*/imagelinks (
  -- Key to page_id of the page containing the image / media link.
  il_from int NOT NULL default '0',

  -- Filename of target image.
  -- This is also the page_title of the file's description page;
  -- all such pages are in namespace 6 (NS_FILE).
  il_to varchar(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*$wgDBprefix*/il_from PRIMARY KEY(il_from,il_to)
) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/imagelinks_to_index ON /*$wgDBprefix*/imagelinks(il_to);
;

--
-- Stores (possibly gzipped) serialized objects with
-- cache arrays to reduce database load slurping up
-- from links and brokenlinks.
--
DROP TABLE IF EXISTS /*$wgDBprefix*/linkscc;
CREATE TABLE /*$wgDBprefix*/linkscc (
  lcc_pageid INT NOT NULL UNIQUE KEY,
  lcc_cacheobj VARCHAR(3766) NOT NULL

) /*$wgDBTableOptions*/;
