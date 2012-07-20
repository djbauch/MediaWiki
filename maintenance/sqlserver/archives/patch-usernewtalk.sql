--- This table stores all the IDs of users whose talk
--- page has been changed (the respective row is deleted
--- when the user looks at the page).
--- The respective column in the user table is no longer
--- required and therefore dropped.

CREATE TABLE /*$wgDBprefix*/user_newtalk (
  user_id int NOT NULL default 0,
  user_ip varchar(40) NOT NULL default '',
  CONSTRAINT user_id PRIMARY KEY (user_id)
) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/user_ip       ON /*$wgDBprefix*/user_newtalk(user_ip);

INSERT INTO
  /*$wgDBprefix*/user_newtalk (user_id, user_ip)
  SELECT user_id, ''
    FROM user2
    WHERE user_newtalk != 0;

ALTER TABLE /*$wgDBprefix*/user2 DROP COLUMN user_newtalk;
