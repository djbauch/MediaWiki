--
-- New user field for tracking registration time
-- 2005-12-21
--

ALTER TABLE /*$wgDBprefix*/user2
  -- Timestamp of account registration.
  -- Accounts predating this schema addition may contain NULL.
  ADD user_registration DATETIME DEFAULT NULL;
