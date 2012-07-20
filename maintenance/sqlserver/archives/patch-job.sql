
-- Jobs performed by parallel apache threads or a command-line daemon
CREATE TABLE /*$wgDBprefix*/job (
  job_id int NOT NULL IDENTITY,

  -- Command name, currently only refreshLinks is defined
  job_cmd VARCHAR(255) NOT NULL default '',

  -- Namespace and title to act on
  -- Should be 0 and '' if the command does not operate on a title
  job_namespace int NOT NULL,
  job_title varchar(255) NOT NULL,

  -- Any other parameters to the command
  -- Presently unused, format undefined
  job_params VARCHAR(255) NOT NULL,

  CONSTRAINT job_id PRIMARY KEY (job_id),
) /*$wgDBTableOptions*/;
CREATE INDEX /*$wgDBprefix*/job_idx ON /*$wgDBprefix*/job(job_cmd,job_namespace,job_title);
