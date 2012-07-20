-- Adding ar_deleted field for revisiondelete
ALTER TABLE /*$wgDBprefix*/archive
  ADD ar_parent_id int default NULL;
