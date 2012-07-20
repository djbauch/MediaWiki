-- SQL to create the initial tables for the MediaWiki database.
-- This is read and executed by the install script; you should
-- not have to run it by itself unless doing a manual install.

--
-- General notes:
--
-- The MySQL table backend for MediaWiki currently uses
-- 14-character CHAR or VARCHAR fields to store timestamps.
-- The format is YYYYMMDDHHMMSS, which is derived from the
-- TEXT format of MySQL's TIMESTAMP fields.
--
-- Historically TIMESTAMP fields were used, but abandoned
-- in early 2002 after a lot of trouble with the fields
-- auto-updating.
--
-- The SQL Server backend uses DATETIME fields for timestamps,
-- and we will migrate the MySQL definitions at some point as
-- well.
--
--
-- The /*_*/ comments in this and other files are
-- replaced with the defined table prefix by the installer
-- and updater scripts. If you are installing or running
-- updates manually, you will need to manually insert the
-- table prefix if any when running these scripts.
--


--
-- The user table contains basic account information,
-- authentication keys, etc.
--
-- Some multi-wiki sites may share a single central user table
-- between separate wikis using the $wgSharedDB setting.
--
-- Note that when a external authentication plugin is used,
-- user table entries still need to be created to store
-- preferences and to key tracking information in the other
-- tables.
-- The SQL Server version is called  rather than user, which is a view
CREATE TABLE /*_*/user2 (
  user_id           INT           NOT NULL IDENTITY(1, 1) PRIMARY KEY,

  -- Usernames must be unique, must not be in the form of
  -- an IP address. _Shouldn't_ allow slashes or case
  -- conflicts. Spaces are allowed, and are _not_ converted
  -- to underscores like titles. See the User::newFromName() for
  -- the specific tests that usernames have to pass.
  user_name         NVARCHAR(255)  NOT NULL UNIQUE DEFAULT '',

  -- Optional 'real name' to be displayed in credit listings
  user_real_name    NVARCHAR(255)  NOT NULL DEFAULT '',

  -- Password hashes, normally hashed like so:
  -- MD5(CONCAT(user_id,'-',MD5(plaintext_password))), see
  -- wfEncryptPassword() in GlobalFunctions.php
  user_password     NVARCHAR(255)  NOT NULL DEFAULT '',

  -- When using 'mail me a new password', a random
  -- password is generated and the hash stored here.
  -- The previous password is left in place until
  -- someone actually logs in with the new password,
  -- at which point the hash is moved to user_password
  -- and the old password is invalidated.
  user_newpassword  NVARCHAR(255)  NOT NULL DEFAULT '',

  -- Timestamp of the last time when a new password was
  -- sent, for throttling purposes
  user_newpass_time DATETIME NULL,

  -- Note: email should be restricted, not public info.
  -- Same with passwords.
  user_email        NVARCHAR(255)  NOT NULL DEFAULT '',

  -- This is a timestamp which is updated when a user
  -- logs in, logs out, changes preferences, or performs
  -- some other action requiring HTML cache invalidation
  -- to ensure that the UI is
  user_touched      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- A pseudorandomly generated value that is stored in
  -- a cookie when the "remember password" feature is
  -- used (previously, a hash of the password was used, but
  -- this was vulnerable to cookie-stealing attacks)
  user_token        CHAR(32)      NOT NULL DEFAULT '',

  -- Initially NULL; when a user's e-mail address has been
  -- validated by returning with a mailed token, this is
  -- set to the current timestamp.
  user_email_authenticated DATETIME DEFAULT NULL,

  -- Randomly generated token created when the e-mail address
  -- is set and a confirmation test mail sent.
  user_email_token  CHAR(32) DEFAULT '',

  -- Expiration date for the user_email_token
  user_email_token_expires DATETIME DEFAULT NULL,

  -- Timestamp of account registration.
  -- Accounts predating this schema addition may contain NULL.
  user_registration DATETIME DEFAULT NULL,

  -- Count of edits and edit-like actions.
  --
  -- *NOT* INTended to be an accurate copy of COUNT(*) WHERE rev_user=user_id
  -- May contain NULL for old accounts if batch-update scripts haven't been
  -- run, as well as listing deleted edits and other myriad ways it could be
  -- out of sync.
  --
  -- Meant primarily for heuristic checks to give an impression of whether
  -- the account has been used much.
  --
  user_editcount    INT NULL
)
;
CREATE        INDEX /*i*/user_email_token ON /*_*/user2(user_email_token);
CREATE UNIQUE INDEX /*i*/user_name        ON /*_*/user2(user_name);
;

-- This is the easiest way to work around the CHAR(15) timestamp hack without modifying PHP code
CREATE VIEW /*_*/user AS
SELECT
  CONVERT(INT, user_id) AS user_id, -- this removes the IDENTITY characteristic
  user_name, user_real_name, user_password, user_newpassword,
  CONVERT(VARCHAR(8), user_newpass_time, 112)
    + SUBSTRING(CONVERT(VARCHAR, user_newpass_time, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_newpass_time, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_newpass_time, 114), 7, 2) AS user_newpass_time,
  user_email,
  CONVERT(VARCHAR(8), user_touched, 112)
    + SUBSTRING(CONVERT(VARCHAR, user_touched, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_touched, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_touched, 114), 7, 2) AS user_touched,
    user_token,
  CONVERT(VARCHAR(8), user_email_authenticated, 112)
    + SUBSTRING(CONVERT(VARCHAR, user_email_authenticated, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_email_authenticated, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_email_authenticated, 114), 7, 2) AS user_email_authenticated,
  user_email_token,
  CONVERT(VARCHAR(8), user_email_token_expires, 112)
    + SUBSTRING(CONVERT(VARCHAR, user_email_token_expires, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_email_token_expires, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_email_token_expires, 114), 7, 2) AS user_email_token_expires,
  CONVERT(VARCHAR(8), user_registration, 112)
    + SUBSTRING(CONVERT(VARCHAR, user_registration, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_registration, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, user_registration, 114), 7, 2) AS user_registration,
  user_editcount
FROM /*_*/user2
;

CREATE TRIGGER /*_*/user_INSERT ON /*_*/user
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO user2
  SELECT
    ISNULL(user_name, ''),
    ISNULL(user_real_name, ''),
    ISNULL(user_password, ''),
    ISNULL(user_newpassword, ''),
    ISNULL(CONVERT(DATETIME, SUBSTRING(user_newpass_time, 1, 8)
      + ' ' + SUBSTRING(user_newpass_time, 9, 2)
      + ':' + SUBSTRING(user_newpass_time, 11, 2)
      + ':' + SUBSTRING(user_newpass_time, 13, 2)), getdate()),
    ISNULL(user_email, ''),
    ISNULL(CONVERT(DATETIME, SUBSTRING(user_touched, 1, 8)
      + ' ' + SUBSTRING(user_touched, 9, 2)
      + ':' + SUBSTRING(user_touched, 11, 2)
      + ':' + SUBSTRING(user_touched, 13, 2)), getdate()),
    ISNULL(user_token, ''),
    CONVERT(DATETIME, SUBSTRING(user_email_authenticated, 1, 8)
      + ' ' + SUBSTRING(user_email_authenticated, 9, 2)
      + ':' + SUBSTRING(user_email_authenticated, 11, 2)
      + ':' + SUBSTRING(user_email_authenticated, 13, 2)),
    ISNULL(user_email_token, ''),
    CONVERT(DATETIME, SUBSTRING(user_email_token_expires, 1, 8)
      + ' ' + SUBSTRING(user_email_token_expires, 9, 2)
      + ':' + SUBSTRING(user_email_token_expires, 11, 2)
      + ':' + SUBSTRING(user_email_token_expires, 13, 2)),
    CONVERT(DATETIME, SUBSTRING(user_registration, 1, 8)
      + ' ' + SUBSTRING(user_registration, 9, 2)
      + ':' + SUBSTRING(user_registration, 11, 2)
      + ':' + SUBSTRING(user_registration, 13, 2)),
    user_editcount
  FROM INSERTED
END
;

CREATE TRIGGER /*_*/user_UPDATE ON /*_*/user
INSTEAD OF UPDATE
AS
BEGIN
  --DECLARE @new_id INT
  DECLARE @old_id INT  -- This is the PRIMARY KEY
  DECLARE @new_name NVARCHAR(255)
  DECLARE @new_real_name NVARCHAR(255)
  DECLARE @new_password NVARCHAR(255)
  DECLARE @new_newpassword NVARCHAR(255)
  DECLARE @new_newpass_time DATETIME
  DECLARE @new_email NVARCHAR(255)
  DECLARE @new_touched DATETIME
  DECLARE @new_token CHAR(32)
  DECLARE @new_email_authenticated DATETIME
  DECLARE @new_email_token CHAR(32)
  DECLARE @new_email_token_expires DATETIME
  DECLARE @new_registration DATETIME
  DECLARE @new_editcount INT
  SELECT @old_id = user_id FROM DELETED
  -- Only need the new values for everything but the PRIMARY KEY
  SELECT @new_name = user_name FROM INSERTED
  SELECT @new_real_name = user_real_name FROM INSERTED
  SELECT @new_password = user_password FROM INSERTED
  SELECT @new_newpassword = user_newpassword FROM INSERTED
  SELECT @new_newpass_time =
    CONVERT(DATETIME, SUBSTRING(user_newpass_time, 1, 8)
      + ' ' + SUBSTRING(user_newpass_time, 9, 2)
      + ':' + SUBSTRING(user_newpass_time, 11, 2)
      + ':' + SUBSTRING(user_newpass_time, 13, 2)) FROM INSERTED
  SELECT @new_email = user_email FROM INSERTED
  SELECT @new_touched =
    CONVERT(DATETIME, SUBSTRING(user_touched, 1, 8)
      + ' ' + SUBSTRING(user_touched, 9, 2)
      + ':' + SUBSTRING(user_touched, 11, 2)
      + ':' + SUBSTRING(user_touched, 13, 2)) FROM INSERTED
  SELECT @new_token = user_token FROM INSERTED
  SELECT @new_email_authenticated =
    CONVERT(DATETIME, SUBSTRING(user_email_authenticated, 1, 8)
      + ' ' + SUBSTRING(user_email_authenticated, 9, 2)
      + ':' + SUBSTRING(user_email_authenticated, 11, 2)
      + ':' + SUBSTRING(user_email_authenticated, 13, 2)) FROM INSERTED
  SELECT @new_email_token = user_email_token FROM INSERTED
  SELECT @new_email_token_expires =
    CONVERT(DATETIME, SUBSTRING(user_email_token_expires, 1, 8)
      + ' ' + SUBSTRING(user_email_token_expires, 9, 2)
      + ':' + SUBSTRING(user_email_token_expires, 11, 2)
      + ':' + SUBSTRING(user_email_token_expires, 13, 2)) FROM INSERTED
  SELECT @new_registration =
    CONVERT(DATETIME, SUBSTRING(user_registration, 1, 8)
      + ' ' + SUBSTRING(user_registration, 9, 2)
      + ':' + SUBSTRING(user_registration, 11, 2)
      + ':' + SUBSTRING(user_registration, 13, 2)) FROM INSERTED
  SELECT @new_editcount = user_editcount FROM INSERTED
  UPDATE /*_*/user2
  SET
    -- user_id can't change because it is an identity column
    user_name = @new_name,
    user_real_name = @new_real_name,
    user_password = @new_password,
    user_newpassword = @new_newpassword,
    user_newpass_time = @new_newpass_time,
    user_email = @new_email,
    user_touched = @new_touched,
    user_token = @new_token,
    user_email_authenticated = @new_email_authenticated,
    user_email_token = @new_email_token,
    user_email_token_expires = @new_email_token_expires,
    user_registration = @new_registration,
    user_editcount = @new_editcount
  WHERE
    user_id = @old_id
END
;

--
-- User permissions have been broken out to a separate table;
-- this allows sites with a shared user table to have different
-- permissions assigned to a user in each project.
--
-- This table replaces the old user_rights field which used a
-- comma-separated blob.
--
CREATE TABLE /*_*/user_groups (
  -- Key to user_id
  ug_user  INT     NOT NULL DEFAULT 0, -- REFERENCES /*_*/user2(user_id) ON DELETE CASCADE,

  -- Group names are short symbolic string keys.
  -- The set of group names is open-ended, though in practice
  -- only some predefined ones are likely to be used.
  --
  -- At runtime $wgGroupPermissions will associate group keys
  -- with particular permissions. A user will have the combined
  -- permissions of any group they're explicitly in, plus
  -- the implicit '*' and 'user' groups.
  ug_group VARCHAR(32) NOT NULL DEFAULT '',

  CONSTRAINT /*i*/user_groups_pk PRIMARY KEY (ug_user,ug_group)
)
;
CREATE INDEX /*i*/ug_group ON /*_*/user_groups(ug_group)
;

-- Stores the groups the user has once belonged to.
-- The user may still belong these groups. Check user_groups.
CREATE TABLE /*_*/user_former_groups (
  -- Key to user_id
  ufg_user INT  NOT NULL default 0,
  ufg_group VARCHAR(32) NOT NULL default '',
  CONSTRAINT /*i*/user_former_groups_pk PRIMARY KEY (ufg_user,ufg_group)
) /*$wgDBTableOptions*/
;

--
-- Stores notifications of user talk page changes, for the display
-- of the "you have new messages" box
-- Changed user_id column to mwuser_id to avoid clashing with user_id function
CREATE TABLE /*_*/user_newtalk (
  -- Key to user.user_id
  user_id INT         NOT NULL DEFAULT 0 REFERENCES /*_*/user2(user_id) ON DELETE CASCADE,
  -- If the user is an anonymous user hir IP address is stored here
  -- since the user_id of 0 is ambiguous
  user_ip VARCHAR(40) NOT NULL DEFAULT '',
  -- The highest timestamp of revisions of the talk page viewed by this user
  user_last_timestamp VARCHAR(14),
  CONSTRAINT /*_*/pk_user_newtalk PRIMARY KEY (user_id, user_last_timestamp)
)
;
CREATE INDEX /*i*/user_ip       ON /*_*/user_newtalk(user_ip);

--
-- User preferences and perhaps other fun stuff. :)
-- Replaces the old user.user_options blob, with a couple nice properties:
--
-- 1) We only store non-DEFAULT settings, so changes to the defauls
--    are now reflected for everybody, not just new accounts.
-- 2) We can more easily do bulk lookups, statistics, or modifications of
--    saved options since it's a sane table structure.
--
CREATE TABLE /*_*/user_properties (
  -- Foreign key to user.user_id
  up_user int NOT NULL,
  
  -- Name of the option being saved. This is indexed for bulk lookup.
  up_property NVARCHAR(255) NOT NULL,
  
  -- Property value as a string.
  up_value NVARCHAR(MAX),
  
  CONSTRAINT /*_*/pk_user_properties PRIMARY KEY (up_user,up_property)
) /*$wgDBTableOptions*/
;
CREATE INDEX /*i*/user_properties_property ON /*_*/user_properties (up_property);

--
-- Core of the wiki: each page has an entry here which identifies
-- it by title and contains some essential metadata.
--
CREATE TABLE /*_*/page2 (
  -- Unique identifier number. The page_id will be preserved across
  -- edits and rename operations, but not deletions and recreations.
  page_id        INT          NOT NULL IDENTITY(1, 1) PRIMARY KEY,

  -- A page name is broken into a namespace and a title.
  -- The namespace keys are UI-language-independent constants,
  -- defined in includes/Defines.php
  page_namespace INT          NOT NULL,

  -- The rest of the title, as text.
  -- Spaces are transformed INTo underscores in title storage.
  page_title     NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL,

  -- Comma-separated set of permission keys indicating who
  -- can move or edit the page.
  page_restrictions VARCHAR(255) NULL,

  -- Number of times this page has been viewed.
  page_counter BIGINT            NOT NULL DEFAULT 0,

  -- 1 indicates the article is a redirect.
  page_is_redirect BIT           NOT NULL DEFAULT 0,

  -- 1 indicates this is a new entry, with only one edit.
  -- Not all pages with one edit are new pages.
  page_is_new BIT                NOT NULL DEFAULT 0,

  -- Random value between 0 and 1, used for Special:Randompage
  page_random REAL               NOT NULL,

  -- This timestamp is updated whenever the page changes in
  -- a way requiring it to be re-rendered, invalidating caches.
  -- Aside from editing this includes permission changes,
  -- creation or deletion of linked pages, and alteration
  -- of contained templates.
  page_touched DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Handy key to revision.rev_id of the current revision.
  -- This may be 0 during page creation, but that shouldn't
  -- happen outside of a transaction... hopefully.
  page_latest INT NOT NULL,

  -- Uncompressed length in bytes of the page's current source text.
  page_len INT NOT NULL,
)
;
CREATE UNIQUE INDEX /*i*/page_unique_name ON /*_*/page2(page_namespace, page_title);
CREATE        INDEX /*i*/page_random_idx  ON /*_*/page2(page_random);
CREATE        INDEX /*i*/page_len_idx     ON /*_*/page2(page_len);
CREATE INDEX /*i*/page_redirect_namespace_len ON /*_*/page2 (page_is_redirect, page_namespace, page_len);
;

-- This is the easiest way to work around the CHAR(15) timestamp hack without modifying PHP code
CREATE VIEW /*_*/page AS
SELECT
   CONVERT(int, page_id) as page_id, -- This will allow page_id to be NULL
   page_namespace, page_title, page_restrictions, page_counter, page_is_redirect,
   page_is_new, page_random,
   CONVERT(VARCHAR(8), page_touched, 112)
     + SUBSTRING(CONVERT(VARCHAR, page_touched, 114), 1, 2)
     + SUBSTRING(CONVERT(VARCHAR, page_touched, 114), 4, 2)
     + SUBSTRING(CONVERT(VARCHAR, page_touched, 114), 7, 2) AS page_touched,
   page_latest, page_len
FROM /*_*/page2
;

CREATE TRIGGER /*_*/page_INSERT ON /*_*/page
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO /*_*/page2
  SELECT page_namespace, page_title, page_restrictions,
    ISNULL(page_counter, 0),
    ISNULL(page_is_redirect, 0),
    ISNULL(page_is_new, 0),
    page_random,
    ISNULL(CONVERT(DATETIME, SUBSTRING(page_touched, 1, 8)
      + ' ' + SUBSTRING(page_touched, 9, 2)
      + ':' + SUBSTRING(page_touched, 11, 2)
      + ':' + SUBSTRING(page_touched, 13, 2)), getdate()),
    page_latest, page_len
  FROM INSERTED
END
;

CREATE TRIGGER /*_*/page_UPDATE ON /*_*/page
INSTEAD OF UPDATE
AS
BEGIN
  DECLARE @old_id INT
  DECLARE @new_namespace INT
  DECLARE @new_title NVARCHAR(255)
  DECLARE @new_restrictions VARCHAR(255)
  DECLARE @new_counter BIGINT
  DECLARE @new_is_redirect BIT
  DECLARE @new_is_new BIT
  DECLARE @new_random REAL
  DECLARE @new_touched DATETIME
  DECLARE @new_latest INT
  DECLARE @old_latest INT
  DECLARE @new_len INT
  SELECT @old_id = page_id FROM DELETED
  SELECT @new_namespace = page_namespace FROM INSERTED
  SELECT @new_title = page_title FROM INSERTED
  SELECT @new_restrictions = page_restrictions FROM INSERTED
  SELECT @new_counter = page_counter FROM INSERTED
  SELECT @new_is_redirect = page_is_redirect FROM INSERTED
  SELECT @new_is_new = page_is_new FROM INSERTED
  SELECT @new_random = page_random FROM INSERTED
  SELECT @new_touched =
  CONVERT(DATETIME, SUBSTRING(page_touched, 1, 8)
    + ' ' + SUBSTRING(page_touched, 9, 2)
    + ':' + SUBSTRING(page_touched, 11, 2)
    + ':' + SUBSTRING(page_touched, 13, 2)) FROM INSERTED
  SELECT @new_latest = page_latest FROM INSERTED
  SELECT @old_latest = page_latest FROM DELETED
  SELECT @new_latest = ISNULL(@new_latest, @old_latest)
  SELECT @new_len = page_len FROM INSERTED
  UPDATE /*_*/page2 SET
    page_namespace = @new_namespace,
    page_title = @new_title,
    page_restrictions = @new_restrictions,
    page_counter = @new_counter,
    page_is_redirect = @new_is_redirect,
    page_is_new = @new_is_new,
    page_random = @new_random,
    page_touched = @new_touched,
    page_latest = @new_latest,
    page_len = @new_len
  WHERE page_id = @old_id
END
;

--
-- Every edit of a page creates also a revision row.
-- This stores metadata about the revision, and a reference
-- to the TEXT storage backend.
--
CREATE TABLE /*_*/revision2 (
  -- Unique ID to identify each revision
  rev_id INT NOT NULL IDENTITY ,

  -- Key to page_id. This should _never_ be invalid.
  rev_page INT NOT NULL,

  -- Key to text.old_id, where the actual bulk TEXT is stored.
  -- It's possible for multiple revisions to use the same TEXT,
  -- for instance revisions where only metadata is altered
  -- or a rollback to a previous version.
  rev_text_id INT  NOT NULL,

  -- TEXT comment summarizing the change.
  -- This TEXT is shown in the history and other changes lists,
  -- rendered in a subset of wiki markup by Linker::formatComment()
  rev_comment NVARCHAR(256) NOT NULL,

  -- Key to user.user_id of the user who made this edit.
  -- Stores 0 for anonymous edits and for some mass imports.
  rev_user INT  NOT NULL DEFAULT 0,

  -- TEXT username or IP address of the editor.
  rev_user_text NVARCHAR(255) NOT NULL DEFAULT '',

  -- Timestamp of when revision was created
  rev_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Records whether the user marked the 'minor edit' checkbox.
  -- Many automated edits are marked as minor.
  rev_minor_edit BIT NOT NULL DEFAULT 0,

  -- Restrictions on who can access this revision
  rev_deleted BIT  NOT NULL DEFAULT 0,

  -- Length of this revision in bytes
  rev_len INT,

  --Key to revision.rev_id
  --This field is used to add support for a tree structure (The Adjacency List Model)
  rev_parent_id INT DEFAULT NULL,
  
  -- SHA-1 text content hash in base-36
  rev_sha1 VARCHAR(32) NOT NULL default '',
  
  CONSTRAINT /*i*/rev_page_id PRIMARY KEY(rev_page, rev_id)
)
;
CREATE UNIQUE INDEX /*i*/rev_id             ON /*_*/revision2(rev_id);
CREATE        INDEX /*i*/rev_timestamp      ON /*_*/revision2(rev_timestamp);
CREATE        INDEX /*i*/page_timestamp     ON /*_*/revision2(rev_page, rev_timestamp);
CREATE        INDEX /*i*/user_timestamp     ON /*_*/revision2(rev_user, rev_timestamp);
CREATE        INDEX /*i*/usertext_timestamp ON /*_*/revision2(rev_user_text, rev_timestamp);
;

-- This is the easiest way to work around the CHAR(15) timestamp hack without modifying PHP code
CREATE VIEW /*_*/revision AS
SELECT
  CONVERT(INT, rev_id) as rev_id,
  rev_page, rev_text_id, rev_comment, rev_user, rev_user_text,
  CONVERT(VARCHAR(8), rev_timestamp, 112)
    + SUBSTRING(CONVERT(VARCHAR, rev_timestamp, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, rev_timestamp, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, rev_timestamp, 114), 7, 2) AS rev_timestamp,
  rev_minor_edit, rev_deleted, rev_len, rev_parent_id, rev_sha1
FROM /*_*/revision2
;

CREATE TRIGGER /*_*/revision_INSERT ON /*_*/revision
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO /*_*/revision2
    SELECT rev_page,
      ISNULL(rev_text_id, 0),
      ISNULL(SUBSTRING(rev_comment, 1, 255), ''),
      ISNULL(rev_user, 0),
      ISNULL(rev_user_text, ''),
      ISNULL(CONVERT(DATETIME, SUBSTRING(rev_timestamp, 1, 8)
        + ' ' + SUBSTRING(rev_timestamp, 9, 2)
        + ':' + SUBSTRING(rev_timestamp, 11, 2)
        + ':' + SUBSTRING(rev_timestamp, 13, 2)), getdate()),
      ISNULL(rev_minor_edit, 0),
      ISNULL(rev_deleted, 0),
      rev_len, rev_parent_id,
      ISNULL(rev_sha1, '')
    FROM INSERTED
END
;

CREATE TRIGGER /*_*/revision_UPDATE ON /*_*/revision
INSTEAD OF UPDATE
AS
BEGIN
  DECLARE @old_id INT
  DECLARE @new_page INT
  DECLARE @new_text_id INT
  DECLARE @new_comment NVARCHAR(256)
  DECLARE @new_user INT
  DECLARE @new_user_text NVARCHAR(255)
  DECLARE @new_timestamp DATETIME
  DECLARE @new_minor_edit BIT
  DECLARE @new_deleted BIT
  DECLARE @new_len INT
  DECLARE @new_parent_id INT
  DECLARE @new_rev_sha1 VARCHAR(32)
  SELECT @old_id = rev_id FROM DELETED
  SELECT @new_page = rev_page FROM INSERTED
  SELECT @new_text_id = rev_text_id FROM INSERTED
  SELECT @new_comment = SUBSTRING(rev_comment, 1, 256) FROM INSERTED
  SELECT @new_user = rev_user FROM INSERTED
  SELECT @new_user_text = rev_user_text FROM INSERTED
  SELECT @new_timestamp =
    CONVERT(DATETIME, SUBSTRING(rev_timestamp, 1, 8)
      + ' ' + SUBSTRING(rev_timestamp, 9, 2)
      + ':' + SUBSTRING(rev_timestamp, 11, 2)
      + ':' + SUBSTRING(rev_timestamp, 13, 2)) FROM INSERTED
  SELECT @new_minor_edit = rev_minor_edit FROM INSERTED
  SELECT @new_deleted = rev_deleted FROM INSERTED
  SELECT @new_len = rev_len FROM INSERTED
  SELECT @new_parent_id = rev_parent_id FROM INSERTED
  SELECT @new_rev_sha1 = rev_sha1 FROM INSERTED
  UPDATE /*_*/revision2 SET
    rev_page = @new_page,
    rev_text_id = @new_text_id,
    rev_comment = @new_comment,
    rev_user = @new_user,
    rev_user_text = @new_user_text,
    rev_timestamp = @new_timestamp,
    rev_minor_edit = @new_minor_edit,
    rev_deleted = @new_deleted,
    rev_len = @new_len,
    rev_parent_id = @new_parent_id,
    rev_sha1 = @new_rev_sha1
  WHERE rev_id = @old_id
END
;

--
-- Holds TEXT of individual page revisions.
--
-- Field names are a holdover from the 'old' revisions table in
-- MediaWiki 1.4 and earlier: an upgrade will transform that
-- table into the 'text' table to minimize unnecessary churning
-- and downtime. If upgrading, the other fields will be left unused.
CREATE TABLE /*_*/text2 (
  -- Unique TEXT storage key number.
  -- Note that the 'oldid' parameter used in URLs does *not*
  -- refer to this number anymore, but to rev_id.
  --
  -- revision.rev_text_id is a key to this column
  old_id INT NOT NULL IDENTITY PRIMARY KEY,

  -- Depending ON the contents of the old_flags field, the text
  -- may be convenient plain TEXT, or it may be funkily encoded.
  old_text NVARCHAR(MAX) NULL,

  -- Comma-separated list of flags:
  -- gzip: TEXT is compressed with PHP's gzdeflate() function.
  -- utf8: TEXT was stored as UTF-8.
  --       If $wgLegacyEncoding option is on, rows *without* this flag
  --       will be converted to UTF-8 transparently at load time.
  -- object: TEXT field contained a serialized PHP object.
  --         The object either contains multiple versions compressed
  --         together to achieve a better compression ratio, or it refers
  --         to another row where the TEXT can be found.
  old_flags VARCHAR(255) NULL,
)
;

CREATE VIEW /*_*/text AS
SELECT
  CONVERT(INT, old_id) AS old_id,
  old_text,
  old_flags
FROM /*_*/text2
;

CREATE TRIGGER /*_*/text_insert ON /*_*/text
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO /*_*/text2
    SELECT
      old_text,
      old_flags
   FROM INSERTED
END
;

--
-- Holding area for deleted articles, which may be viewed
-- or restored by admins through the Special:Undelete interface.
-- The fields generally correspond to the page, revision, and text
-- fields, with several caveats.
-- Cannot reasonably create views on this table, due to the presence of TEXT
-- columns. Instead, the "timestamp" field is VARCHAR(14) and DEFAULTs to
-- a string value derived from CURRENT_TIMESTAMP
CREATE TABLE /*_*/archive (
  ar_namespace INT NOT NULL DEFAULT 0,
  ar_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- Newly deleted pages will not store TEXT in this table,
  -- but will reference the separately existing TEXT rows.
  -- This field is retained for backwards compatibility,
  -- so old archived pages will remain accessible after
  -- upgrading from 1.4 to 1.5.
  -- TEXT may be gzipped or otherwise funky.
  ar_text NVARCHAR(MAX) NOT NULL,

  -- Basic revision stuff...
  ar_comment NVARCHAR(255) NOT NULL,
  ar_user INT NULL REFERENCES /*_*/user2(user_id) ON DELETE SET NULL,
  ar_user_text NVARCHAR(255) NOT NULL,
  ar_timestamp VARCHAR(14) NOT NULL DEFAULT  CONVERT(VARCHAR(14), CURRENT_TIMESTAMP, 114),
    --+ SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
    --+ SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
    --+ SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2),
  ar_minor_edit BIT NOT NULL DEFAULT 0,

  -- See ar_text note.
  ar_flags VARCHAR(255) NOT NULL,

  -- When revisions are deleted, their unique rev_id is stored
  -- here so it can be retained after undeletion. This is necessary
  -- to retain permalinks to given revisions after accidental delete
  -- cycles or messy operations like history merges.
  --
  -- Old entries from 1.4 will be NULL here, and a new rev_id will
  -- be created ON undeletion for those revisions.
  ar_rev_id INT,

  -- For newly deleted revisions, this is the text.old_id key to the
  -- actual stored text. To avoid breaking the block-compression scheme
  -- and otherwise making storage changes harder, the actual TEXT is
  -- *not* deleted from the TEXT table, merely hidden by removal of the
  -- page and revision entries.
  --
  -- Old entries deleted under 1.2-1.4 will have NULL here, and their
  -- ar_text and ar_flags fields will be used to create a new text
  -- row upon undeletion.
  ar_text_id INT,

  -- rev_deleted for archives
  ar_deleted BIT NOT NULL DEFAULT 0,
  ar_len INT DEFAULT NULL,
  ar_page_id INT NULL,
  -- Original pervious revision
  ar_parent_id INT DEFAULT NULL,
  -- SHA-1 text content hash in base-36
  ar_sha1 VARCHAR(32) NOT NULL default '',
   
  CONSTRAINT /*i*/pk_archive PRIMARY KEY (ar_namespace,ar_timestamp),
)
;
CREATE INDEX /*i*/name_title_timestamp ON /*_*/archive(ar_namespace,ar_title,ar_timestamp);
CREATE INDEX /*i*/ar_usertext_timestamp ON /*_*/archive (ar_user_text,ar_timestamp);
CREATE INDEX /*i*/ar_revid ON /*_*/archive (ar_rev_id);

--
-- Track page-to-page hyperlinks within the wiki.
--
CREATE TABLE /*_*/pagelinks (
  -- Key to the page_id of the page containing the link.
  pl_from INT NOT NULL DEFAULT 0 REFERENCES page2(page_id) ON DELETE CASCADE,

  -- Key to page_namespace/page_title of the target page.
  -- The target page may or may not exist, and due to renames
  -- and deletions may refer to different page records as time
  -- goes by.
  pl_namespace INT NOT NULL DEFAULT 0,
  pl_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*i*/pl_from PRIMARY KEY (pl_from,pl_namespace,pl_title),
)
;
CREATE UNIQUE INDEX /*i*/pl_namespace ON /*_*/pagelinks(pl_namespace,pl_title,pl_from);

--
-- Track template inclusions.
--
CREATE TABLE /*_*/templatelinks (
  -- Key to the page_id of the page containing the link.
  tl_from INT NOT NULL DEFAULT 0 REFERENCES /*_*/page2(page_id) ON DELETE CASCADE,

  -- Key to page_namespace/page_title of the target page.
  -- The target page may or may not exist, and due to renames
  -- and deletions may refer to different page records as time
  -- goes by.
  tl_namespace INT NOT NULL DEFAULT 0,
  tl_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*_*/tl_from PRIMARY KEY (tl_from,tl_namespace,tl_title),
)
;
CREATE UNIQUE INDEX /*i*/tl_namespace ON /*_*/templatelinks(tl_namespace,tl_title,tl_from);
;
--
-- Track links to images *used inline*
-- We don't distinguish live from broken links here, so
-- they do not need to be changed ON upload/removal.
--
CREATE TABLE /*_*/imagelinks (
  -- Key to page_id of the page containing the image / media link.
  il_from INT NOT NULL DEFAULT 0 REFERENCES /*_*/page2(page_id) ON DELETE CASCADE,

  -- Filename of target image.
  -- This is also the page_title of the file's description page;
  -- all such pages are in namespace 6 (NS_IMAGE).
  il_to NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*_*/il_from PRIMARY KEY(il_from,il_to),
)
;
CREATE UNIQUE INDEX /*i*/il_to ON /*_*/imagelinks (il_to,il_from);

--
-- Track category inclusions *used inline*
-- This tracks a single level of category membership
-- (folksonomic tagging, really).
--
CREATE TABLE /*_*/categorylinks (
  -- Key to page_id of the page defined as a category member.
  cl_from INT NOT NULL DEFAULT 0,

  -- Name of the category.
  -- This is also the page_title of the category's description page;
  -- all such pages are in namespace 14 (NS_CATEGORY).
  cl_to NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- The title of the linking page, or an optional override
  -- to determine sort order. Sorting is by BINARY order, which
  -- isn't always ideal, but collations seem to be an exciting
  -- and dangerous new world in MySQL...
  --
  cl_sortkey NVARCHAR(255) NOT NULL DEFAULT '',
  
  -- A prefix for the raw sortkey manually specified by the user, either via
  -- [[Category:Foo|prefix]] or {{defaultsort:prefix}}.  If nonempty, it's
  -- concatenated with a line break followed by the page title before the sortkey
  -- conversion algorithm is run.  We store this so that we can update
  -- collations without reparsing all pages.
  -- Note: If you change the length of this field, you also need to change
  -- code in LinksUpdate.php. See bug 25254.
  cl_sortkey_prefix NVARCHAR(255) NOT NULL default '',
  
  -- This isn't really used at present. Provided for an optional
  -- sorting method by approximate addition time.
  cl_timestamp VARCHAR(14) NOT NULL,

  CONSTRAINT /*_*/cl_from PRIMARY KEY(cl_from, cl_to),
  cl_collation VARCHAR(32) NOT NULL default '',

  -- Stores whether cl_from is a category, file, or other page, so we can
  -- paginate the three categories separately.  This never has to be updated
  -- after the page is created, since none of these page types can be moved to
  -- any other.
  cl_type VARCHAR(6) NOT NULL default 'page'
  --cl_type ENUM('page', 'subcat', 'file') 
)
;
-- We always sort within a given category...
CREATE INDEX /*i*/cl_sortkey   ON /*_*/categorylinks(cl_to,cl_type,cl_sortkey,cl_from);
-- Not really used?
CREATE INDEX /*i*/cl_timestamp ON /*_*/categorylinks(cl_to,cl_timestamp);
CREATE INDEX /*i*/cl_collation ON /*_*/categorylinks (cl_collation);

CREATE TABLE /*_*/category  (
  -- Primary key
  cat_id INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,

  -- Name of the category, in the same form as page_title (with underscores).
  -- If there is a category page corresponding to this category, by definition,
  -- it has this name (in the Category namespace).
  cat_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL,

  -- The numbers of member pages (including categories and media), subcatego-
  -- ries, and Image: namespace members, respectively.  These are signed to
  -- make underflow more obvious.  We make the first number include the second
  -- two for better sorting: subtracting for display is easy, adding for order-
  -- ing is not.
  cat_pages int NOT NULL DEFAULT 0,
  cat_subcats int NOT NULL DEFAULT 0,
  cat_files int NOT NULL DEFAULT 0,

  -- Reserved for future use
  cat_hidden BIT NOT NULL DEFAULT 0,
) /*$wgDBTableOptions*/;
CREATE UNIQUE INDEX /*i*/idx_cat_title ON /*_*/category(cat_title);
CREATE UNIQUE INDEX /*i*/idx_cat_id ON /*_*/category(cat_id)
CREATE INDEX /*i*/cat_pages_index ON /*_*/category(cat_pages);
;
--
-- Track links to external URLs
-- IE >= 4 supports no more than 2083 characters in a URL
CREATE TABLE /*_*/externallinks (
  -- page_id of the referring page
  el_from INT NOT NULL DEFAULT 0,

  -- The URL
  -- Size reduced from 2083 to 896 because maximum index size is 900
  el_to VARCHAR(896) NOT NULL,

  -- In the case of HTTP URLs, this is the URL with any username or password
  -- removed, and with the labels in the hostname reversed and converted to
  -- lower case. An extra dot is added to allow for matching of either
  -- example.com or *.example.com in a single scan.
  -- Example:
  --      http://user:password@sub.example.com/page.html
  --   becomes
  --      http://com.example.sub./page.html
  -- which allows for fast searching for all pages under example.com with the
  -- clause:
  --      WHERE el_index LIKE 'http://com.example.%'
  -- Size reduced from 2083 to 896 because maximum index size is 900
  el_index VARCHAR(896) NOT NULL,

  CONSTRAINT /*i*/pk_externallinks PRIMARY KEY (el_from,el_to),
)
;
-- Maximum key length ON SQL Server is 900 bytes
CREATE INDEX /*i*/externallinks_from_to ON /*_*/externallinks(el_from,el_to);
CREATE INDEX /*i*/externallinks_index   ON /*_*/externallinks(el_index);
;

--
-- Track external user accounts, if ExternalAuth is used
--
CREATE TABLE /*_*/external_user (
  -- Foreign key to user_id
  eu_local_id int NOT NULL PRIMARY KEY,

  -- Some opaque identifier provided by the external database
  eu_external_id VARCHAR(255) NOT NULL
) /*$wgDBTableOptions*/
;
CREATE UNIQUE INDEX /*i*/eu_external_id ON /*_*/external_user (eu_external_id);

--
-- Track INTerlanguage links
--
CREATE TABLE /*_*/langlinks (
  -- page_id of the referring page
  ll_from  INT   NOT NULL DEFAULT 0,

  -- Language code of the target
  ll_lang  VARCHAR(20)  NOT NULL DEFAULT '',

  -- Title of the target, including namespace
  ll_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*_*/langlinks_pk PRIMARY KEY(ll_from, ll_lang),
)
;
CREATE UNIQUE INDEX /*i*/langlinks_reverse_key ON /*_*/langlinks(ll_lang,ll_title);
;

-- Track inline interwiki links
--
CREATE TABLE /*_*/iwlinks (
  -- page_id of the referring page
  iwl_from int NOT NULL default 0,

  -- Interwiki prefix code of the target
  iwl_prefix VARCHAR(20) NOT NULL default '', -- Changed from NVARCHAR 2 NOV 2011

  -- Title of the target, including namespace
  iwl_title NVARCHAR(255) NOT NULL default ''
) /*$wgDBTableOptions*/
;
CREATE UNIQUE INDEX /*i*/iwl_from ON /*_*/iwlinks (iwl_from, iwl_prefix, iwl_title);
CREATE UNIQUE INDEX /*i*/iwl_prefix_title_from ON /*_*/iwlinks (iwl_prefix, iwl_title, iwl_from);

--
-- Contains a single row with some aggregate info
-- ON the state of the site.
--
CREATE TABLE /*_*/site_stats (
  -- The single row should contain 1 here.
  ss_row_id        INT  NOT NULL DEFAULT 1 PRIMARY KEY,

  -- Total number of page views, if hit counters are enabled.
  ss_total_views   BIGINT DEFAULT 0,

  -- Total number of edits performed.
  ss_total_edits   BIGINT DEFAULT 0,

  -- An approximate count of pages matching the following criteria:
  -- * in namespace 0
  -- * not a redirect
  -- * contains the TEXT '[['
  -- See Article::isCountable() in includes/Article.php
  ss_good_articles BIGINT DEFAULT 0,

  -- Total pages, theoretically equal to SELECT COUNT(*) FROM page; except faster
  ss_total_pages   BIGINT DEFAULT -1,

  -- Number of users, theoretically equal to SELECT COUNT(*) FROM user;
  ss_users         BIGINT DEFAULT -1,

  -- Added for version 1.14
  ss_active_users BIGINT DEFAULT -1,

  -- Deprecated, no longer updated as of 1.5
  ss_admins        INT    DEFAULT -1,

  -- Number of images, equivalent to SELECT COUNT(*) FROM image
  ss_images INT DEFAULT 0,
);
;

--
-- Stores an ID for every time any article is visited;
-- depending ON $wgHitcounterUpdateFreq, it is
-- periodically cleared and the page_counter column
-- in the page table updated for the all articles
-- that have been visited.)
--
CREATE TABLE /*_*/hitcounter (
   hc_id BIGINT NOT NULL PRIMARY KEY
)
;
--
-- The Internet is full of jerks, alas. Sometimes it's handy
-- to block a vandal or troll account.
--
CREATE TABLE /*_*/ipblocks2 (
  -- Primary key, introduced for privacy.
  ipb_id      INT NOT NULL IDENTITY PRIMARY KEY,

  -- Blocked IP address in dotted-quad form or user name.
  ipb_address VARCHAR(255) NOT NULL,

  -- Blocked user ID or 0 for IP blocks.
  ipb_user    INT NOT NULL DEFAULT 0,

  -- User ID who made the block.
  ipb_by      INT NOT NULL DEFAULT 0,

  ipb_by_text NVARCHAR(255) NOT NULL DEFAULT '',

  -- TEXT comment made by blocker.
  ipb_reason  NVARCHAR(255) NOT NULL,

  -- Creation (or refresh) date in standard YMDHMS form.
  -- IP blocks expire automatically.
  ipb_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Indicates that the IP address was banned because a banned
  -- user accessed a page through it. If this is 1, ipb_address
  -- will be hidden, and the block identified by block ID number.
  ipb_auto BIT NOT NULL DEFAULT 0,

  -- If set to 1, block applies only to logged-out users
  ipb_anon_only BIT NOT NULL DEFAULT 0,

  -- Block prevents account creation from matching IP addresses
  ipb_create_account BIT NOT NULL DEFAULT 1,

  -- Block triggers autoblocks
  ipb_enable_autoblock BIT NOT NULL DEFAULT 1,

  -- Time at which the block will expire.
  ipb_expiry DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Start and end of an address range, in hexadecimal
  -- Size chosen to allow IPv6
  ipb_range_start VARCHAR(32) NOT NULL DEFAULT '',
  ipb_range_end VARCHAR(32) NOT NULL DEFAULT '',
  -- Flag for entries hidden from users and Sysops
  ipb_deleted BIT NOT NULL DEFAULT 0,
  ipb_block_email BIT NOT NULL DEFAULT 0,
  ipb_allow_usertalk BIT NOT NULL DEFAULT 1
)
;
-- Unique index to support "user already blocked" messages
-- Any new options which prevent collisions should be included
--UNIQUE INDEX ipb_address (ipb_address(255), ipb_user, ipb_auto, ipb_anon_only),
CREATE UNIQUE INDEX /*i*/ipb_address   ON /*_*/ipblocks2(ipb_address, ipb_user, ipb_auto, ipb_anon_only);
CREATE        INDEX /*i*/ipb_user      ON /*_*/ipblocks2(ipb_user);
CREATE        INDEX /*i*/ipb_range     ON /*_*/ipblocks2(ipb_range_start, ipb_range_end);
CREATE        INDEX /*i*/ipb_timestamp ON /*_*/ipblocks2(ipb_timestamp);
CREATE        INDEX /*i*/ipb_expiry    ON /*_*/ipblocks2(ipb_expiry);
;

-- This is the easiest way to work around the CHAR(15) timestamp hack without modifying PHP code
CREATE VIEW /*_*/ipblocks AS
SELECT
  CONVERT(INT, ipb_id) AS ipb_id,
  ipb_address, ipb_user, ipb_by, ipb_by_text, ipb_reason,
  CONVERT(VARCHAR(8), ipb_timestamp, 112)
    + SUBSTRING(CONVERT(VARCHAR, ipb_timestamp, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, ipb_timestamp, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, ipb_timestamp, 114), 7, 2) AS ipb_timestamp,
  ipb_auto, ipb_anon_only, ipb_create_account, ipb_enable_autoblock,
  CONVERT(VARCHAR(8), ipb_expiry, 112)
    + SUBSTRING(CONVERT(VARCHAR, ipb_expiry, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, ipb_expiry, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, ipb_expiry, 114), 7, 2) AS ipb_expiry,
  ipb_range_start, ipb_range_end, ipb_deleted, ipb_block_email, ipb_allow_usertalk
FROM /*_*/ipblocks2
;

CREATE TRIGGER /*_*/ipblocks_INSERT ON /*_*/ipblocks
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO /*_*/ipblocks2
  SELECT
    ipb_address,
    ISNULL(ipb_user, 0),
    ISNULL(ipb_by, 0),
    ISNULL(ipb_by_text, ''),
    ipb_reason,
    ISNULL(CONVERT(DATETIME, SUBSTRING(ipb_timestamp, 1, 8)
      + ' ' + SUBSTRING(ipb_timestamp, 9, 2)
      + ':' + SUBSTRING(ipb_timestamp, 11, 2)
      + ':' + SUBSTRING(ipb_timestamp, 13, 2)), getdate()),
    ISNULL(ipb_auto, 0),
    ISNULL(ipb_anon_only, 0),
    ISNULL(ipb_create_account, 1),
    ISNULL(ipb_enable_autoblock, 1),
    ISNULL(CONVERT(DATETIME, SUBSTRING(ipb_expiry, 1, 8)
      + ' ' + SUBSTRING(ipb_expiry, 9, 2)
      + ':' + SUBSTRING(ipb_expiry, 11, 2)
      + ':' + SUBSTRING(ipb_expiry, 13, 2)), getdate()),
    ISNULL(ipb_range_start, ''),
    ISNULL(ipb_range_end, ''),
    ISNULL(ipb_deleted, 0),
    ISNULL(ipb_block_email, 0),
    ISNULL(ipb_allow_usertalk, 0)
  FROM INSERTED
END
;

-- TODO: Update query for IPBLOCKS

--
-- Uploaded images and other files.
CREATE TABLE /*_*/image (
  -- Filename.
  -- This is also the title of the associated description page,
  -- which will be in namespace 6 (NS_IMAGE).
  img_name NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- File size in bytes.
  img_size INT  NOT NULL DEFAULT 0,

  -- For images, size in pixels.
  img_width INT NOT NULL DEFAULT 0,
  img_height INT NOT NULL DEFAULT 0,

  -- Extracted EXIF metadata stored as a serialized PHP array.
  img_metadata TEXT NOT NULL,
  
  -- For images, BITs per pixel if known.
  img_bits INT NOT NULL DEFAULT 0,

  -- Media type as defined by the MEDIATYPE_xxx constants
  img_media_type VARCHAR(11) DEFAULT 'UNKNOWN',

  -- major part of a MIME media type as defined by IANA
  -- see http://www.iana.org/assignments/media-types/
  img_major_mime VARCHAR(11) DEFAULT 'UNKNOWN',

  -- minor part of a MIME media type as defined by IANA
  -- the minor parts are not required to adher to any standard
  -- but should be consistent throughout the database
  -- see http://www.iana.org/assignments/media-types/
  img_minor_mime VARCHAR(100) NOT NULL DEFAULT 'unknown',

  -- Description field as entered by the uploader.
  -- This is displayed in image upload history and logs.
  img_description NVARCHAR(4000) NOT NULL,

  -- user_id and user_name of uploader.
  img_user INT NOT NULL DEFAULT 0,
  img_user_text NVARCHAR(255) NOT NULL DEFAULT '',

  -- Time of the upload.
  img_timestamp VARCHAR(14) NOT NULL DEFAULT CONVERT(VARCHAR(8), CURRENT_TIMESTAMP, 112)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2),

  img_sha1 VARCHAR(32) NULL,
  CONSTRAINT /*_*/img_name PRIMARY KEY (img_name)
)
;
CREATE INDEX /*i*/img_usertext_timestamp ON /*_*/image (img_user_text,img_timestamp);
-- Used by Special:ListFiles for sort-by-size
CREATE INDEX /*i*/img_size ON /*_*/image (img_size);
-- Used by Special:Newimages and Special:ListFiles
CREATE INDEX /*i*/img_timestamp ON /*_*/image (img_timestamp);
-- Used in API and duplicate search
CREATE INDEX /*i*/img_sha1 ON /*_*/image (img_sha1);
;
--ENUM("UNKNOWN", "BITMAP", "DRAWING", "AUDIO", "VIDEO", "MULTIMEDIA", "OFFICE", "TEXT", "EXECUTABLE", "ARCHIVE") DEFAULT NULL,
--ENUM("unknown", "application", "audio", "image", "text", "video", "message", "model", "multipart") NOT NULL DEFAULT "unknown",

--
-- Previous revisions of uploaded files.
-- Awkwardly, image rows have to be moved into
-- this table at re-upload time.
--
CREATE TABLE /*_*/oldimage (
  -- Base filename: key to image.img_name
  oi_name NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- Filename of the archived file.
  -- This is generally a timestamp and '!' prepended to the base name.
  oi_archive_name NVARCHAR(255) NOT NULL DEFAULT '',

  -- Other fields as in image...
  oi_size INT NOT NULL DEFAULT 0,
  oi_width INT NOT NULL DEFAULT 0,
  oi_height INT NOT NULL DEFAULT 0,
  oi_bits INT NOT NULL DEFAULT 0,
  oi_description NVARCHAR(255) NOT NULL,
  oi_user INT NOT NULL DEFAULT 0,
  oi_user_text NVARCHAR(255) NOT NULL DEFAULT '',
  oi_timestamp VARCHAR(14) NOT NULL DEFAULT CONVERT(VARCHAR(8), CURRENT_TIMESTAMP, 112)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2),
  oi_metadata TEXT,
  oi_media_type VARCHAR(11) DEFAULT 'UNKNOWN',
  oi_major_mime VARCHAR(11) NOT NULL DEFAULT 'UNKNOWN',
  oi_minor_mime VARCHAR(100) NOT NULL DEFAULT 'unknown',
  oi_deleted BIT NOT NULL DEFAULT 0,
  oi_sha1 VARCHAR(32) NULL,

  CONSTRAINT /*_*/pk_oi PRIMARY KEY (oi_name, oi_timestamp),
)
;
CREATE INDEX /*i*/oi_usertext_timestamp ON /*_*/oldimage(oi_user_text,oi_timestamp);
CREATE INDEX /*i*/oi_name_timestamp ON /*_*/oldimage(oi_name, oi_timestamp);
CREATE INDEX /*i*/oi_name_archive_name ON /*_*/oldimage(oi_name,oi_archive_name);
CREATE INDEX /*i*/oi_sha1 ON /*_*/oldimage(oi_sha1);
;
--
-- Record of deleted file data
--
CREATE TABLE /*_*/filearchive (
  -- Unique row id
  fa_id INT NOT NULL IDENTITY,

  -- Original base filename; key to image.img_name, page.page_title, etc
  fa_name NVARCHAR(255)  NOT NULL DEFAULT '',

  -- Filename of archived file, if an old revision
  fa_archive_name NVARCHAR(255)  DEFAULT '',

  -- Which storage bin (directory tree or object store) the file data
  -- is stored in. Should be 'deleted' for files that have been deleted;
  -- any other bin is not yet in use.
  fa_storage_group NVARCHAR(16),

  -- SHA-1 of the file contents plus extension, used as a key for storage.
  -- eg 8f8a562add37052a1848ff7771a2c515db94baa9.jpg
  --
  -- If NULL, the file was missing at deletion time or has been purged
  -- from the archival storage.
  fa_storage_key NVARCHAR(64)  DEFAULT '',

  -- Deletion information, if this file is deleted.
  fa_deleted_user INT,
  fa_deleted_timestamp VARCHAR(14) DEFAULT NULL,
  fa_deleted_reason NVARCHAR(255),

  -- Duped fields from image
  fa_size INT  DEFAULT 0,
  fa_width INT DEFAULT 0,
  fa_height INT DEFAULT 0,
  fa_metadata NVARCHAR(MAX),
  fa_bits INT DEFAULT 0,
  fa_media_type VARCHAR(11) DEFAULT NULL,
  fa_major_mime VARCHAR(11) DEFAULT 'unknown',
  fa_minor_mime VARCHAR(100) DEFAULT 'unknown',
  fa_description NVARCHAR(255),
  fa_user INT DEFAULT 0,
  fa_user_text NVARCHAR(255) DEFAULT '',
  fa_timestamp VARCHAR(14) DEFAULT CONVERT(VARCHAR(8), CURRENT_TIMESTAMP, 112)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2),
  -- Visibility of deleted revisions, bitfield
  fa_deleted BIT NOT NULL DEFAULT 0,

  CONSTRAINT /*_*/fa_id PRIMARY KEY (fa_id),
)
;
-- ENUM("UNKNOWN", "BITMAP", "DRAWING", "AUDIO", "VIDEO", "MULTIMEDIA", "OFFICE", "TEXT", "EXECUTABLE", "ARCHIVE")
-- ENUM("unknown", "application", "audio", "image", "text", "video", "message", "model", "multipart")
-- Pick by image name
CREATE INDEX /*i*/fa_name ON /*_*/filearchive (fa_name, fa_timestamp);
-- pick out dupe files
CREATE INDEX /*i*/fa_storage_group ON /*_*/filearchive (fa_storage_group, fa_storage_key);
-- sort by deletion time
CREATE INDEX /*i*/fa_deleted_timestamp ON /*_*/filearchive (fa_deleted_timestamp);
-- sort by uploader
CREATE INDEX /*i*/fa_user_timestamp ON /*_*/filearchive (fa_user_text,fa_timestamp);

--
-- Store information about newly uploaded files before they're
-- moved into the actual filestore
--
CREATE TABLE /*_*/uploadstash2 (
  us_id INT  NOT NULL PRIMARY KEY IDENTITY,
  -- the user who uploaded the file.
  us_user INT  NOT NULL,

  -- file key. this is how applications actually search for the file.
  -- this might go away, or become the primary key.
  us_key NVARCHAR(255) NOT NULL,

  -- the original path
  us_orig_path NVARCHAR(255) NOT NULL,

  -- the temporary path at which the file is actually stored
  us_path NVARCHAR(255) NOT NULL,

  -- which type of upload the file came from (sometimes)
  us_source_type NVARCHAR(50),

  -- the date/time on which the file was added
  us_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  us_status VARCHAR(50) NOT NULL,
  
  -- chunk counter starts at 0, current offset is stored in us_size
  us_chunk_inx INT NULL,

  -- file properties from File::getPropsFromPath.  these may prove unnecessary.
  --
  us_size int  NOT NULL,
  -- this hash comes from File::sha1Base36(), and is 31 characters
  us_sha1 VARCHAR(31) NOT NULL,
  us_mime VARCHAR(255),
  -- Media type as defined by the MEDIATYPE_xxx constants, should duplicate definition in the image table
  us_media_type VARCHAR(10) DEFAULT NULL,
  --us_media_type ENUM("UNKNOWN", "BITMAP", "DRAWING", "AUDIO", "VIDEO", "MULTIMEDIA", "OFFICE", "TEXT", "EXECUTABLE", "ARCHIVE") default NULL,
  -- image-specific properties
  us_image_width INT,
  us_image_height INT,
  us_image_bits SMALLINT 
) /*$wgDBTableOptions*/
;

-- sometimes there's a delete for all of a user's stuff.
CREATE INDEX /*i*/us_user ON /*_*/uploadstash2 (us_user);
-- pick out files by key, enforce key uniqueness
CREATE UNIQUE INDEX /*i*/us_key ON /*_*/uploadstash2 (us_key);
-- the abandoned upload cleanup script needs this
CREATE INDEX /*i*/us_timestamp ON /*_*/uploadstash2 (us_timestamp);

CREATE VIEW /*_*/uploadstash AS
SELECT
  CONVERT(INT, us_id) AS us_id,
  us_user,
  us_key,
  us_orig_path,
  us_path,
  us_source_type,
  CONVERT(VARCHAR(8), us_timestamp, 112)
    + SUBSTRING(CONVERT(VARCHAR, us_timestamp, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, us_timestamp, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, us_timestamp, 114), 7, 2) AS us_timestamp,
  us_status,
  us_chunk_inx,
  us_size,
  us_sha1,
  us_mime,
  us_media_type,
  us_image_width,
  us_image_height,
  us_image_bits
FROM /*_*/uploadstash2
;

CREATE TRIGGER /*_*/uploadstash_insert ON uploadstash
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO uploadstash2
  SELECT
    ISNULL(us_user, ''),
    ISNULL(us_key, ''),
    ISNULL(us_orig_path, ''),
    ISNULL(us_path, ''),
    ISNULL(us_source_type, ''),
    CONVERT(DATETIME, SUBSTRING(us_timestamp, 1, 8)
      + ' ' + SUBSTRING(us_timestamp, 9, 2)
      + ':' + SUBSTRING(us_timestamp, 11, 2)
      + ':' + SUBSTRING(us_timestamp, 13, 2)),
    ISNULL(us_status, ''),
    ISNULL(us_chunk_inx, 0),
    ISNULL(us_size, ''),
    ISNULL(us_sha1, ''),
    ISNULL(us_mime, ''),
    ISNULL(us_media_type, ''),
    ISNULL(us_image_width, ''),
    ISNULL(us_image_height, ''),
    ISNULL(us_image_bits, '')
  FROM INSERTED
END
;

--
-- Primarily a summary table for Special:Recentchanges,
-- this table contains some additional info on edits from
-- the last few days, see Article::editUpdates()
--
CREATE TABLE /*_*/recentchanges2 (
  rc_id INT NOT NULL IDENTITY PRIMARY KEY,
  rc_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  rc_cur_time DATETIME DEFAULT CURRENT_TIMESTAMP,

  -- As in revision
  rc_user INT DEFAULT 0,
  rc_user_text NVARCHAR(255) DEFAULT '',

  -- When pages are renamed, their RC entries do _not_ change.
  rc_namespace INT DEFAULT 0,
  rc_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS DEFAULT '',

  -- as in revision...
  rc_comment NVARCHAR(255) DEFAULT '',
  rc_minor BIT DEFAULT 0,

  -- Edits by user accounts with the 'bot' rights key are
  -- marked with a 1 here, and will be hidden from the
  -- DEFAULT view.
  rc_bot BIT DEFAULT 0,

  rc_new BIT DEFAULT 0,

  -- Key to page_id (was cur_id prior to 1.5).
  -- This will keep links working after moves while
  -- retaining the at-the-time name in the changes list.
  rc_cur_id INT DEFAULT 0,

  -- rev_id of the given revision
  rc_this_oldid INT DEFAULT 0,

  -- rev_id of the prior revision, for generating diff links.
  rc_last_oldid INT DEFAULT 0,

  -- These may no longer be used, with the new move log.
  rc_type tinyint DEFAULT 0,
  rc_moved_to_ns BIT DEFAULT 0,
  rc_moved_to_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS DEFAULT '',

  -- If the Recent Changes Patrol option is enabled,
  -- users may mark edits as having been reviewed to
  -- remove a warning flag ON the RC list.
  -- A value of 1 indicates the page has been reviewed.
  rc_patrolled BIT DEFAULT 0,

  -- Recorded IP address the edit was made from, if the
  -- $wgPutIPinRC option is enabled.
  rc_ip VARCHAR(40) DEFAULT '',

  -- TEXT length in characters before
  -- and after the edit
  rc_old_len INT DEFAULT 0,
  rc_new_len INT DEFAULT 0,
  -- Visibility of deleted revisions, BITfield
  rc_deleted BIT DEFAULT 0,

  -- Value corresonding to log_id, specific log entries
  rc_logid INT DEFAULT 0,
  -- Store log type info here, or null
  rc_log_type VARCHAR(255) NULL DEFAULT NULL,
  -- Store log action or null
  rc_log_action VARCHAR(255) NULL DEFAULT NULL,
  -- Log params
  rc_params VARCHAR(8000) DEFAULT '',
);
CREATE INDEX /*i*/rc_timestamp       ON /*_*/recentchanges2(rc_timestamp);
CREATE INDEX /*i*/rc_namespace_title ON /*_*/recentchanges2(rc_namespace, rc_title);
CREATE INDEX /*i*/rc_cur_id          ON /*_*/recentchanges2(rc_cur_id);
CREATE INDEX /*i*/new_name_timestamp ON /*_*/recentchanges2(rc_new,rc_namespace,rc_timestamp);
CREATE INDEX /*i*/rc_ip              ON /*_*/recentchanges2(rc_ip);
CREATE INDEX /*i*/rc_ns_usertext     ON /*_*/recentchanges2(rc_namespace, rc_user_text);
CREATE INDEX /*i*/rc_user_text       ON /*_*/recentchanges2(rc_user_text, rc_timestamp);
;

-- This is the easiest way to work around the CHAR(15) timestamp hack without modifying PHP code
CREATE VIEW /*_*/recentchanges AS
SELECT
  CONVERT(INT, rc_id) AS rc_id,
  CONVERT(VARCHAR(8), rc_timestamp, 112)
    + SUBSTRING(CONVERT(VARCHAR, rc_timestamp, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, rc_timestamp, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, rc_timestamp, 114), 7, 2) AS rc_timestamp,
  CONVERT(VARCHAR(14), rc_cur_time, 112)
    + SUBSTRING(CONVERT(VARCHAR, rc_cur_time, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, rc_cur_time, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, rc_cur_time, 114), 7, 2) AS rc_cur_time,
  rc_user, rc_user_text, rc_namespace, rc_title, rc_comment, rc_minor,
  rc_bot, rc_new, rc_cur_id, rc_this_oldid, rc_last_oldid, rc_type, rc_moved_to_ns,
  rc_moved_to_title, rc_patrolled, rc_ip, rc_old_len, rc_new_len, rc_deleted,
  rc_logid, rc_log_type, rc_log_action, rc_params
FROM /*_*/recentchanges2
;

CREATE TRIGGER /*_*/recentchanges_INSERT ON /*_*/recentchanges
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO /*_*/recentchanges2
  SELECT
    ISNULL(CONVERT(DATETIME, SUBSTRING(rc_timestamp, 1, 8)
      + ' ' + SUBSTRING(rc_timestamp, 9, 2)
      + ':' + SUBSTRING(rc_timestamp, 11, 2)
      + ':' + SUBSTRING(rc_timestamp, 13, 2)), getdate()),
    ISNULL(CONVERT(DATETIME, SUBSTRING(rc_cur_time, 1, 8)
      + ' ' + SUBSTRING(rc_cur_time, 9, 2)
      + ':' + SUBSTRING(rc_cur_time, 11, 2)
      + ':' + SUBSTRING(rc_cur_time, 13, 2)), getdate()),
    ISNULL(rc_user, 0),
    ISNULL(rc_user_text, ''),
    ISNULL(rc_namespace, 1),
    ISNULL(rc_title, ''),
    ISNULL(rc_comment, ''),
    ISNULL(rc_minor, ''),
    ISNULL(rc_bot, 0),
    ISNULL(rc_new, 0),
    ISNULL(rc_cur_id, 0),
    ISNULL(rc_this_oldid, 0),
    ISNULL(rc_last_oldid, 0),
    ISNULL(rc_type, 0),
    ISNULL(rc_moved_to_ns, 0),
    ISNULL(rc_moved_to_title, ''),
    ISNULL(rc_patrolled, 0),
    ISNULL(rc_ip, ''),
    ISNULL(rc_old_len, 0),
    ISNULL(rc_new_len, 0),
    ISNULL(rc_deleted, 0),
    ISNULL(rc_logid, 0),
    rc_log_type, rc_log_action,
    ISNULL(rc_params, '')
  FROM INSERTED
END
;

CREATE TRIGGER /*_*/recentchanges_UPDATE on /*_*/recentchanges
INSTEAD OF UPDATE
AS
BEGIN
  DECLARE @old_id INT
  DECLARE @new_timestamp DATETIME
  DECLARE @new_cur_time DATETIME
  DECLARE @new_user INT
  DECLARE @new_user_text NVARCHAR(255)
  DECLARE @new_namespace INT
  DECLARE @new_title NVARCHAR(255)
  DECLARE @new_comment NVARCHAR(255)
  DECLARE @new_minor BIT
  DECLARE @new_bot BIT
  DECLARE @new_new BIT
  DECLARE @new_cur_id INT
  DECLARE @new_this_oldid INT
  DECLARE @new_last_oldid INT
  DECLARE @new_type TINYINT
  DECLARE @new_moved_to_ns BIT
  DECLARE @new_moved_to_title NVARCHAR(255)
  DECLARE @new_patrolled BIT
  DECLARE @new_ip CHAR(15)
  DECLARE @new_old_len INT
  DECLARE @new_new_len INT
  DECLARE @new_deleted BIT
  DECLARE @new_logid INT
  DECLARE @new_log_type VARCHAR(255)
  DECLARE @new_log_action VARCHAR(255)
  DECLARE @new_params VARCHAR(8000)
  SELECT @old_id = rc_id FROM DELETED
  SELECT @new_timestamp =
    CONVERT(DATETIME, SUBSTRING(rc_timestamp, 1, 8)
      + ' ' + SUBSTRING(rc_timestamp, 9, 2)
      + ':' + SUBSTRING(rc_timestamp, 11, 2)
      + ':' + SUBSTRING(rc_timestamp, 13, 2)) FROM INSERTED
  SELECT @new_cur_time =
    CONVERT(DATETIME, SUBSTRING(rc_cur_time, 1, 8)
      + ' ' + SUBSTRING(rc_cur_time, 9, 2)
      + ':' + SUBSTRING(rc_cur_time, 11, 2)
      + ':' + SUBSTRING(rc_cur_time, 13, 2)) FROM INSERTED
  SELECT @new_user = rc_user FROM INSERTED
  SELECT @new_user_text = rc_user_text FROM INSERTED
  SELECT @new_namespace = rc_namespace FROM INSERTED
  SELECT @new_title = rc_title FROM INSERTED
  SELECT @new_comment = rc_comment FROM INSERTED
  SELECT @new_minor = rc_minor FROM INSERTED
  SELECT @new_bot = rc_bot FROM INSERTED
  SELECT @new_new = rc_new FROM INSERTED
  SELECT @new_cur_id = rc_cur_id FROM INSERTED
  SELECT @new_this_oldid = rc_this_oldid FROM INSERTED
  SELECT @new_last_oldid = rc_last_oldid FROM INSERTED
  SELECT @new_type = rc_type FROM INSERTED
  SELECT @new_moved_to_ns = rc_moved_to_ns FROM INSERTED
  SELECT @new_moved_to_title = rc_moved_to_title FROM INSERTED
  SELECT @new_patrolled = rc_patrolled FROM INSERTED
  SELECT @new_ip = rc_ip FROM INSERTED
  SELECT @new_old_len = rc_old_len FROM INSERTED
  SELECT @new_new_len = rc_new_len FROM INSERTED
  SELECT @new_deleted = rc_deleted FROM INSERTED
  SELECT @new_logid = rc_logid FROM INSERTED
  SELECT @new_log_type = rc_log_type FROM INSERTED
  SELECT @new_log_action = rc_log_action FROM INSERTED
  SELECT @new_params = rc_params FROM INSERTED
  UPDATE /*_*/recentchanges2 SET
    rc_timestamp = @new_timestamp,
    rc_cur_time = @new_cur_time,
    rc_user = @new_user,
    rc_user_text = @new_user_text,
    rc_namespace = @new_namespace,
    rc_title = @new_title,
    rc_comment = @new_comment,
    rc_minor = @new_minor,
    rc_bot = @new_bot,
    rc_new = @new_new,
    rc_cur_id = @new_cur_id,
    rc_this_oldid = @new_this_oldid,
    rc_last_oldid = @new_last_oldid,
    rc_type = @new_type,
    rc_moved_to_ns = @new_moved_to_ns,
    rc_moved_to_title = @new_moved_to_title,
    rc_patrolled = @new_patrolled,
    rc_ip = @new_ip,
    rc_old_len = @new_old_len,
    rc_new_len = @new_new_len,
    rc_deleted = @new_deleted,
    rc_logid = @new_logid,
    rc_log_type = @new_log_type,
    rc_log_action = @new_log_action,
    rc_params = @new_params
  WHERE rc_id = @old_id
END
;

CREATE TABLE /*_*/watchlist (
  -- Key to user.user_id
  wl_user INT NOT NULL,

  -- Key to page_namespace/page_title
  -- Note that users may watch pages which do not exist yet,
  -- or existed in the past but have been deleted.
  wl_namespace INT NOT NULL DEFAULT 0,
  wl_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- Timestamp when user was last sent a notification e-mail;
  -- cleared when the user visits the page.
  wl_notificationtimestamp VARCHAR(14) DEFAULT NULL,

  CONSTRAINT /*_*/watchlist_pk PRIMARY KEY (wl_user, wl_namespace, wl_title)
)
;
CREATE UNIQUE INDEX /*i*/wl_user ON /*_*/watchlist (wl_user, wl_namespace, wl_title);
CREATE INDEX /*i*/namespace_title ON /*_*/watchlist (wl_namespace, wl_title);

--
-- Used by the math module to keep track
-- of previously-rendered items.
--
CREATE TABLE /*_*/math (
  -- BINARY MD5 hash of the latex fragment, used as an identifier key.
  math_inputhash VARCHAR(16) NOT NULL PRIMARY KEY,

  -- Not sure what this is, exactly...
  math_outputhash VARCHAR(16) NOT NULL,

  -- texvc reports how well it thinks the HTML conversion worked;
  -- if it's a low level the PNG rendering may be preferred.
  math_html_conservativeness tinyint NOT NULL,

  -- HTML output from texvc, if any
  math_html NVARCHAR(MAX),

  -- MathML output from texvc, if any
  math_mathml NVARCHAR(MAX),
)
;

-- Needs fulltext index.
CREATE TABLE /*_*/searchindex (
  -- Key to page_id
  si_page INT NOT NULL PRIMARY KEY,

  -- Munged version of title
  si_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- Munged version of body text
  si_text NVARCHAR(MAX) NOT NULL,

  --FULLTEXT si_title (si_title)
  --FULLTEXT si_text (si_text)
)
;
-- si_title and si_text want full TEXT indexes
CREATE INDEX /*i*/searchindex_title ON /*_*/searchindex(si_title);

--
-- Recognized INTerwiki link prefixes
--
CREATE TABLE /*_*/interwiki (
  -- The INTerwiki prefix, (e.g. "Meatball", or the language prefix "de")
  iw_prefix VARCHAR(32) NOT NULL PRIMARY KEY,

  -- The URL of the wiki, with "$1" as a placeholder for an article name.
  -- Any spaces in the name will be transformed to underscores before
  -- insertion.
  iw_url NVARCHAR(127) NOT NULL,

  -- The URL of the file api.php
  iw_api NVARCHAR(2048) NOT NULL,

  -- The name of the database (for a connection to be established with wfGetLB( 'wikiid' ))
  iw_wikiid VARCHAR(64) NOT NULL,
  -- A boolean value indicating whether the wiki is in this project
  -- (used, for example, to detect redirect loops)
  iw_local BIT NOT NULL,

  -- Boolean value indicating whether INTerwiki transclusions are allowed.
  iw_trans BIT NOT NULL DEFAULT 0,
)
;

--
-- Used for caching expensive grouped queries
--
CREATE TABLE /*_*/querycache (
  -- A key name, generally the base name of of the special page.
  qc_type      VARCHAR(32)  NOT NULL,

  -- Some sort of stored value. Sizes, counts...
  qc_value     INT       NOT NULL DEFAULT '0',

  -- Target namespace+title
  qc_namespace INT       NOT NULL DEFAULT 0,
  qc_title  NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*_*/qc_pk PRIMARY KEY (qc_type,qc_value)
)
;

--
-- For a few generic cache operations if not using Memcached
--
CREATE TABLE /*_*/objectcache (
  keyname NVARCHAR(255) NOT NULL DEFAULT '',
  [value] NVARCHAR(MAX), --NVARCHAR(3766), -- IMAGE,
  exptime VARCHAR(14), -- This is treated as a DATETIME
);
CREATE CLUSTERED INDEX /*i*/objectcache_time ON /*_*/objectcache(exptime);
CREATE UNIQUE INDEX /*i*/objectcache_PK ON /*wgDBprefix*/objectcache(keyname);

--
-- Cache of INTerwiki transclusion
--
CREATE TABLE /*_*/transcache (
  tc_url      NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL PRIMARY KEY,
  tc_contents NVARCHAR(MAX),
  tc_time     DATETIME NOT NULL,
);

CREATE TABLE /*_*/logging2 (
  -- Symbolic keys for the general log type and the action type
  -- within the log. The output format will be controlled by the
  -- action field, but only the type controls categorization.
  log_id INT IDENTITY PRIMARY KEY,
  log_type VARCHAR(32) NOT NULL DEFAULT '',
  log_action VARCHAR(32) NOT NULL DEFAULT '',

  -- Timestamp. Duh.
  log_timestamp VARCHAR(14) NOT NULL DEFAULT '19700101000000',

  -- The user who performed this action; key to user_id
  log_user INT NOT NULL DEFAULT 0,

  -- Name of the user who performed this action
  log_user_text NVARCHAR(255) NOT NULL DEFAULT '',

  -- Key to the page affected. Where a user is the target,
  -- this will point to the user page.
  log_namespace INT NOT NULL DEFAULT 0,
  log_title VARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',
  log_page INT NULL,

  -- Freeform text. Interpreted as edit history comments.
  log_comment NVARCHAR(255) NOT NULL DEFAULT '',

  -- LF separated list of miscellaneous parameters
  log_params VARCHAR(MAX) NOT NULL,
  -- rev_deleted for logs
  log_deleted BIT DEFAULT 0
)
;
CREATE INDEX /*i*/type_time ON /*_*/logging2 (log_type, log_timestamp);
CREATE INDEX /*i*/user_time ON /*_*/logging2 (log_user, log_timestamp);
CREATE INDEX /*i*/page_time ON /*_*/logging2 (log_namespace, log_title, log_timestamp);
CREATE INDEX /*i*/times ON /*_*/logging2 (log_timestamp);
CREATE INDEX /*i*/log_user_type_time ON /*_*/logging2 (log_user, log_type, log_timestamp);
CREATE INDEX /*i*/log_page_id_time ON /*_*/logging2 (log_page, log_timestamp);
CREATE INDEX /*i*/type_action ON /*_*/logging2 (log_type, log_action, log_timestamp);
;
CREATE VIEW /*_*/logging
AS
  SELECT
  CONVERT(INT, log_id) AS log_id,
  log_type,
  log_action,
  CONVERT(VARCHAR(14), log_timestamp, 112)
    + SUBSTRING(CONVERT(VARCHAR, log_timestamp, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, log_timestamp, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, log_timestamp, 114), 7, 2) AS log_timestamp,
  log_user,
  log_user_text,
  log_namespace,
  log_title,
  log_page,
  CONVERT(VARCHAR(512), log_comment) AS log_comment,
  log_params,
  log_deleted
FROM /*_*/logging2
;
CREATE TRIGGER /*_*/logging_INSERT ON /*_*/logging
INSTEAD OF INSERT
AS
BEGIN
  INSERT INTO [logging2]
  SELECT
    ISNULL(LEFT(log_type, 10), ''),
    ISNULL(LEFT(log_action, 10), ''),
    ISNULL(log_timestamp, '1970-01-01 00:00:00'),
    ISNULL(log_user, 0),
    ISNULL(log_user_text, ''),
    ISNULL(log_namespace, 0),
    ISNULL(LEFT(log_title, 255), ''),
    ISNULL(log_page, 0),
    ISNULL(LEFT(log_comment, 255), ''),
    ISNULL(log_params, ''),
    ISNULL(log_deleted, 0)
  FROM INSERTED
END
;

CREATE TRIGGER /*_*/logging_UPDATE ON /*_*/logging
INSTEAD OF UPDATE
AS
BEGIN
  DECLARE @old_id INT -- This is the PRIMARY KEY
  DECLARE @new_type CHAR(10)
  DECLARE @new_action CHAR(10)
  DECLARE @new_timestamp VARCHAR(14)
  DECLARE @new_user INT
  DECLARE @new_user_text NVARCHAR(255)
  DECLARE @new_namespace INT
  DECLARE @new_title NVARCHAR(255)
  DECLARE @new_page INT
  DECLARE @new_comment VARCHAR(255)
  DECLARE @new_params VARCHAR(8000)
  DECLARE @new_deleted BIT
  SELECT @old_id = log_id FROM DELETED
  SELECT @new_type = log_type FROM INSERTED
  SELECT @new_action = log_action FROM INSERTED
  SELECT @new_timestamp = log_timestamp FROM INSERTED
  SELECT @new_user = log_user FROM INSERTED
  SELECT @new_user_text = log_user_text FROM INSERTED
  SELECT @new_namespace = log_namespace FROM INSERTED
  SELECT @new_title = log_title FROM INSERTED
  SELECT @new_page = log_page FROM INSERTED
  SELECT @new_comment = log_comment FROM INSERTED
  SELECT @new_params = log_params FROM INSERTED
  SELECT @new_deleted = log_deleted FROM INSERTED
  UPDATE /*_*/logging2 SET
    log_type = @new_type,
    log_action = @new_action,
    log_timestamp = @new_timestamp,
    log_user = @new_user,
    log_user_text = @new_user_text,
    log_namespace = @new_namespace,
    log_title = @new_title,
    log_page = @new_page,
    log_comment = @new_comment,
    log_params = @new_params,
    log_deleted = @new_deleted
  WHERE log_id = @old_id
END
;

CREATE TABLE /*_*/log_search (
  -- The type of ID (rev ID, log ID, rev timestamp, username)
  ls_field VARCHAR(32) NOT NULL,
  -- The value of the ID
  ls_value VARCHAR(255) NOT NULL,
  -- Key to log_id
  ls_log_id int NOT NULL DEFAULT 0,
  CONSTRAINT /*_*/pk_log_search PRIMARY KEY(ls_field,ls_value,ls_log_id),
) /*$wgDBTableOptions*/
;
--CREATE UNIQUE INDEX /*i*/ls_field_val ON /*_*/log_search (ls_field,ls_value,ls_log_id);
CREATE INDEX /*i*/ls_log_id ON /*_*/log_search (ls_log_id);

CREATE TABLE /*_*/trackbacks (
  tb_id    INT IDENTITY PRIMARY KEY,
  tb_page  INT REFERENCES /*_*/page2(page_id) ON DELETE CASCADE,
  tb_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL,
  tb_url   NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL,
  tb_ex    TEXT,
  tb_name  NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS
)
;
CREATE INDEX /*i*/tb_page ON /*_*/trackbacks(tb_page);

-- Jobs performed by parallel apache threads or a command-line daemon
CREATE TABLE /*_*/job (
  job_id INT NOT NULL IDENTITY PRIMARY KEY,

  -- Command name
  -- Limited to 60 to prevent key length overflow
  job_cmd VARCHAR(60) NOT NULL DEFAULT '',

  -- Namespace and title to act on
  -- Should be 0 and '' if the command does not operate ON a title
  job_namespace INT NOT NULL,
  job_title VARCHAR(255) NOT NULL,

  -- Timestamp of when the job was inserted
  -- NULL for jobs added before addition of the timestamp
  job_timestamp VARCHAR(14) NULL default NULL,
  
  -- Any other parameters to the command
  -- Presently unused, format undefined
  job_params VARCHAR(255) NOT NULL,
)
;
CREATE INDEX /*i*/job_idx ON /*_*/job(job_cmd,job_namespace,job_title);
CREATE INDEX /*i*/job_timestamp ON /*_*/job(job_timestamp);

-- Details of updates to cached special pages
CREATE TABLE /*_*/querycache_info (
  -- Special page name
  -- Corresponds to a qc_type value
  qci_type NVARCHAR(32) NOT NULL DEFAULT '' PRIMARY KEY,

  -- Timestamp of last update
  qci_timestamp VARCHAR(14) NOT NULL DEFAULT '19700101000000',
)
;

-- For each redirect, this table contains exactly one row defining its target
CREATE TABLE /*_*/redirect (
  -- Key to the page_id of the redirect page
  rd_from INT NOT NULL DEFAULT 0 REFERENCES /*_*/page2(page_id) ON DELETE CASCADE,

  -- Key to page_namespace/page_title of the target page.
  -- The target page may or may not exist, and due to renames
  -- and deletions may refer to different page records as time
  -- goes by.
  rd_namespace INT NOT NULL DEFAULT '0',
  rd_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',
  rd_interwiki NVARCHAR(32) DEFAULT NULL,
  rd_fragment NVARCHAR(255) DEFAULT NULL,
  CONSTRAINT /*_*/pk_redirect PRIMARY KEY(rd_namespace,rd_title,rd_from),
)
;
--CREATE UNIQUE INDEX /*i*/rd_ns_title ON /*_*/redirect(rd_namespace,rd_title,rd_from);

-- Used for caching expensive grouped queries that need two links (for example double-redirects)
CREATE TABLE /*_*/querycachetwo (
  -- A key name, generally the base name of of the special page.
  qcc_type NVARCHAR(32) NOT NULL,

  -- Some sort of stored value. Sizes, counts...
  qcc_value INT NOT NULL DEFAULT 0,

  -- Target namespace+title
  qcc_namespace INT NOT NULL DEFAULT 0,
  qcc_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  -- Target namespace+title2
  qcc_namespacetwo INT NOT NULL DEFAULT 0,
  qcc_titletwo NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL DEFAULT '',

  CONSTRAINT /*_*/qcc_type PRIMARY KEY(qcc_type,qcc_value),
)
;
CREATE UNIQUE INDEX /*i*/qcc_title    ON /*_*/querycachetwo(qcc_type,qcc_namespace,qcc_title);
CREATE UNIQUE INDEX /*i*/qcc_titletwo ON /*_*/querycachetwo(qcc_type,qcc_namespacetwo,qcc_titletwo);

CREATE TABLE /*_*/mediawiki_version (
  type        VARCHAR(255) NOT NULL,
  mw_version  VARCHAR(255) NOT NULL,
  notes       VARCHAR(255) NULL,
  pg_version  VARCHAR(255) NULL,
  pg_dbname   VARCHAR(255) NULL,
  pg_user     VARCHAR(255) NULL,
  pg_port     VARCHAR(255) NULL,
  mw_schema   VARCHAR(255) NULL,
  ts2_schema  VARCHAR(255) NULL,
  ctype       VARCHAR(255) NULL,
  sql_version VARCHAR(255) NULL,
  sql_date    VARCHAR(255) NULL,
  cdate       VARCHAR(14) DEFAULT CONVERT(VARCHAR(14), CURRENT_TIMESTAMP, 112)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 1, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 4, 2)
    + SUBSTRING(CONVERT(VARCHAR, CURRENT_TIMESTAMP, 114), 7, 2)
  CONSTRAINT/*_*/mw_vers PRIMARY KEY(mw_version)
)
;

INSERT INTO /*_*/mediawiki_version(type, mw_version) VALUES('MW', '1.18');

--- Used for storing page restrictions (i.e. protection levels)
CREATE TABLE /*_*/page_restrictions (
  -- Page to apply restrictions to (Foreign Key to page).
  pr_page INT NOT NULL,
  -- The protection type (edit, move, etc)
  pr_type VARCHAR(255) NOT NULL,
  -- The protection level (Sysop, autoconfirmed, etc)
  pr_level VARCHAR(255) NOT NULL,
  -- Whether or not to cascade the protection down to pages transcluded.
  pr_cascade INT NOT NULL,
  -- Field for future support of per-user restriction.
  pr_user INT NULL,
  -- Field for time-limited protection.
  pr_expiry VARCHAR(14) NULL,
  -- Field for an ID for this restrictions row (sort-key for Special:ProtectedPages)
  pr_id INT IDENTITY
  CONSTRAINT /*_*/pr_pagetype PRIMARY KEY(pr_page,pr_type),
)
;
--CREATE UNIQUE INDEX /*i*/pr_pagetype ON /*_*/page_restrictions (pr_page,pr_type);
CREATE INDEX /*i*/pr_typelevel ON /*_*/page_restrictions(pr_type,pr_level);
CREATE INDEX /*i*/pr_pagelevel ON /*_*/page_restrictions(pr_level);
CREATE INDEX /*i*/pr_cascade   ON /*_*/page_restrictions(pr_cascade);
;

-- Protected titles - nonexistent pages that have been protected
CREATE TABLE /*_*/protected_titles (
  pt_namespace INT NOT NULL,
  pt_title NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CS_AS NOT NULL,
  pt_user INT NOT NULL,

  pt_reason NVARCHAR(255),
  pt_timestamp VARCHAR(14) NOT NULL,          -- actually a date/time
  pt_expiry VARCHAR(14) NOT NULL DEFAULT '',  -- actually a date/time
  pt_create_perm VARCHAR(60) NOT NULL,
  CONSTRAINT /*_*/pk_protected_titles PRIMARY KEY(pt_namespace,pt_title),
)
;
CREATE UNIQUE INDEX /*i*/pt_namespace_title ON /*_*/protected_titles (pt_namespace,pt_title);
CREATE INDEX /*i*/pt_timestamp ON /*_*/protected_titles (pt_timestamp);
;
-- Name/value pairs indexed by page_id
CREATE TABLE /*_*/page_props (
  pp_page int NOT NULL,
  pp_propname NVARCHAR(60) NOT NULL,
  pp_value NVARCHAR(MAX),
  CONSTRAINT /*_*/pk_page_props PRIMARY KEY(pp_page,pp_propname)
) /*$wgDBTableOptions*/
;

CREATE TABLE /*_*/updatelog (
  ul_key NVARCHAR(50) NOT NULL,
  ul_value NVARCHAR(MAX),
  CONSTRAINT /*_*/pk_updatelog PRIMARY KEY (ul_key)
) /*$wgDBTableOptions*/
;

CREATE TABLE /*_*/change_tag (
  ct_id    INT IDENTITY PRIMARY KEY,
  ct_rc_id INT NULL,
  ct_log_id INT NULL,
  ct_rev_id INT NULL,
  ct_tag NVARCHAR(255) NOT NULL,
  ct_params NVARCHAR(MAX) NULL
)
;

CREATE UNIQUE INDEX /*i*/change_tag_rc_tag ON /*_*/change_tag(ct_rc_id, ct_tag);
CREATE UNIQUE INDEX /*i*/change_tag_log_tag ON /*_*/change_tag(ct_log_id, ct_tag);
CREATE UNIQUE INDEX /*i*/change_tag_rev_tag ON /*_*/change_tag(ct_rev_id, ct_tag);
-- Covering index
CREATE INDEX /*i*/change_tag_tag_id ON /*_*/change_tag(ct_tag,ct_rc_id,ct_rev_id,ct_log_id);

-- Rollup table to pull a LIST of tags simply without ugly GROUP_CONCAT that only works on MySQL 4.1+
CREATE TABLE /*_*/tag_summary (
  ct_id    INT IDENTITY PRIMARY KEY,
  ts_rc_id INT NULL,
  ts_log_id INT NULL,
  ts_rev_id INT NULL,
  ts_tags NVARCHAR(MAX) NOT NULL
) /*$wgDBTableOptions*/
;

CREATE UNIQUE INDEX /*i*/tag_summary_rc_id ON /*_*/tag_summary (ts_rc_id);
CREATE UNIQUE INDEX /*i*/tag_summary_log_id ON /*_*/tag_summary (ts_log_id);
CREATE UNIQUE INDEX /*i*/tag_summary_rev_id ON /*_*/tag_summary (ts_rev_id);


CREATE TABLE /*_*/valid_tag (
  vt_tag NVARCHAR(255) NOT NULL PRIMARY KEY
);

-- Table for storing localisation data
CREATE TABLE /*_*/l10n_cache2 (
  -- Language code
  lc_lang NVARCHAR(32) NOT NULL, -- Changed from NVARCHAR 2 NOV 2011 
  -- Cache key
  lc_key NVARCHAR(255) NOT NULL, -- Changed from NVARCHAR 2 NOV 2011 
  -- Value
  lc_value NVARCHAR(MAX) NULL, -- Changed from NVARCHAR 2 NOV 2011 
  CONSTRAINT /*_*/pk_l10_cache2 PRIMARY KEY(lc_lang, lc_key)  
) /*$wgDBTableOptions*/
;

CREATE VIEW /*_*/l10n_cache AS
SELECT
  lc_lang AS lc_lang,
  lc_key AS lc_key,
  lc_value AS lc_value
FROM /*_*/l10n_cache2
;

CREATE TRIGGER /*_*/l10n_cache_insert ON /*_*/l10n_cache
INSTEAD OF INSERT
AS
BEGIN
BEGIN TRY
  INSERT INTO /*_*/l10n_cache2
  SELECT lc_lang, lc_key, lc_value
  FROM INSERTED
END TRY
BEGIN CATCH
  DECLARE @new_lang NVARCHAR(32)
  DECLARE @new_key NVARCHAR(255)
  DECLARE @new_value NVARCHAR(MAX)
  SELECT @new_lang = lc_lang FROM INSERTED
  SELECT @new_key = lc_key FROM INSERTED
  SELECT @new_value = lc_value FROM INSERTED
  UPDATE /*_*/l10n_cache SET
    lc_value = @new_value
  WHERE lc_lang = @new_lang AND lc_key = @new_key
END CATCH
END
;

-- Table for storing JSON message blobs for the resource loader
CREATE TABLE /*_*/msg_resource (
  -- Resource name
  mr_resource NVARCHAR(255) NOT NULL,
  -- Language code
  mr_lang NVARCHAR(32) NOT NULL,
  -- JSON blob
  mr_blob NVARCHAR(MAX) NOT NULL,
  -- Timestamp of last update
  mr_timestamp VARCHAR(14) NOT NULL
  
  CONSTRAINT /*i*/mr_resource_lang PRIMARY KEY (mr_resource, mr_lang)
) /*$wgDBTableOptions*/
;

-- Table for administering which message is contained in which resource
CREATE TABLE /*_*/msg_resource_links (
  mrl_resource NVARCHAR(255) NOT NULL,
  -- Message key
  mrl_message NVARCHAR(255) NOT NULL
  CONSTRAINT /*i*/ mrl_message_resource PRIMARY KEY (mrl_message, mrl_resource)
) /*$wgDBTableOptions*/
;

-- Table for tracking which local files a module depends on that aren't
-- registered directly.
-- Currently only used for tracking images that CSS depends on
CREATE TABLE /*_*/module_deps (
  -- Module name
  md_module VARCHAR(255) NOT NULL,
  -- Skin name
  md_skin VARCHAR(32) NOT NULL,
  -- JSON blob with file dependencies
  md_deps NVARCHAR(MAX) NOT NULL
  
  CONSTRAINT /*i*/md_module_skin PRIMARY KEY (md_module, md_skin)
) /*$wgDBTableOptions*/
;

-- Table for holding configuration changes
CREATE TABLE /*_*/config (
  -- Config var name
  cf_name VARBINARY(255) NOT NULL PRIMARY KEY,
  -- Config var value
  cf_value VARBINARY(MAX) NOT NULL
) /*$wgDBTableOptions*/
;
-- Should cover *most* configuration - strings, ints, bools, etc.

CREATE TABLE /*_*/php_sessions (
  sessionid VARCHAR(40) NOT NULL default '',
  expiry INT NOT NULL default '0',
  value VARCHAR(MAX) NOT NULL,
  PRIMARY KEY (sessionid)
)
;

--- Add the full-text capabilities
-- These steps are no longer applicaple with the use of Lucene-based search!
-- STEP 1: Enable Full Text Search for the database
--sp_fulltext_database 'enable';
-- STEP 2: Create a full-text catalog
--sp_fulltext_catalog 'WikiCatalog', 'create'
-- STEP 3: Create a full-text index for the table
--sp_fulltext_table /*_*/text, 'create', 'WikiCatalog', 'PK_Text'
-- STEP 4: Add the column to the table's full-text index
--sp_fulltext_column /*wgDBprefix*/text, 'old_text', 'add'
-- STEP 5: Activate the newly created full-text index
--sp_fulltext_table 'FTI_Wiki_Text', 'activate'
-- STEP 6: Populate the newly created full-text catalog
