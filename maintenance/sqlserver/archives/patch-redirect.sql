--
-- Create the new redirect table.
-- For each redirect, this table contains exactly one row defining its target
--
CREATE TABLE /*$wgDBprefix*/redirect (
  -- Key to the page_id of the redirect page
  rd_from int NOT NULL default 0 PRIMARY KEY,

  -- Key to page_namespace/page_title of the target page.
  -- The target page may or may not exist, and due to renames
  -- and deletions may refer to different page records as time
  -- goes by.
  rd_namespace int NOT NULL default 0,
  rd_title varchar(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',
) /*$wgDBTableOptions*/;
CREATE UNIQUE INDEX /*$wgDBprefix*/rd_ns_title ON /*$wgDBprefix*/redirect(rd_namespace,rd_title,rd_from);

-- Import existing redirects
-- Using ignore because some of the redirect pages contain more than one link
INSERT IGNORE
  INTO /*$wgDBprefix*/redirect (rd_from,rd_namespace,rd_title)
  SELECT pl_from,pl_namespace,pl_title
    FROM /*$wgDBprefix*/pagelinks, /*$wgDBprefix*/page
    WHERE pl_from=page_id AND page_is_redirect=1;
