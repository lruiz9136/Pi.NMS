<?php
//------------------------------------------------------------------------------
//  Pi.NMS
//  Lightweight network management system
//
//  settings.php - Front module. Server side. Settings actions
//------------------------------------------------------------------------------
//  lruiz9136 2026        GNU GPLv3
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//  Action selector
//------------------------------------------------------------------------------
  ini_set ('max_execution_time','15');

  if (isset ($_REQUEST['action']) && !empty ($_REQUEST['action'])) {
    $action = $_REQUEST['action'];
    switch ($action) {
      case 'checkUpdate':  checkUpdate();  break;
      case 'checkRunner':  checkRunner();  break;
      case 'runUpdate':    runUpdate();    break;
      case 'updateStatus': updateStatus(); break;
      default:             echo json_encode (array ('error' => 'Unknown action')); break;
    }
  }


//------------------------------------------------------------------------------
//  Check for Update
//------------------------------------------------------------------------------
function checkUpdate() {
  $source = readSourceMetadata();
  $repo = valueOrDefault ($source, 'SOURCE_REPO', '');
  $branch = valueOrDefault ($source, 'SOURCE_BRANCH', '');
  $installedCommit = valueOrDefault ($source, 'SOURCE_COMMIT', 'unknown');
  $installedAt = valueOrDefault ($source, 'SOURCE_INSTALLED_AT', 'unknown');

  $error = '';
  $updateAvailable = null;
  $latestCommit = '';

  if ($repo == '' || $branch == '') {
    $error = 'Installed repository or branch is missing from config/source.conf.';
  } else {
    $latestCommit = getLatestCommit ($repo, $branch);
  }

  if ($error == '' && $latestCommit == '') {
    $error = 'Unable to reach GitHub update metadata.';
  } elseif ($installedCommit == 'unknown' || $installedCommit == '') {
    $updateAvailable = null;
  } else {
    $updateAvailable = ($installedCommit != $latestCommit);
  }

  echo json_encode (array (
    'repo' => $repo,
    'branch' => $branch,
    'installed_commit' => $installedCommit,
    'latest_commit' => $latestCommit,
    'installed_at' => $installedAt,
    'update_available' => $updateAvailable,
    'error' => $error
  ));
}


//------------------------------------------------------------------------------
//  Check Update Runner
//------------------------------------------------------------------------------
function checkRunner() {
  $result = runUpdatePreflight();

  echo json_encode (array (
    'ok' => $result['exit_code'] === 0,
    'exit_code' => $result['exit_code'],
    'log' => $result['log'],
    'error' => $result['exit_code'] === 0 ? '' : 'Update preflight failed.'
  ));
}


//------------------------------------------------------------------------------
//  Run Update
//------------------------------------------------------------------------------
function runUpdate() {
  ini_set ('max_execution_time','30');

  $paths = getUpdatePaths();
  $source = readSourceMetadata();
  $repo = valueOrDefault ($source, 'SOURCE_REPO', '');
  $branch = valueOrDefault ($source, 'SOURCE_BRANCH', '');
  $archiveUrl = valueOrDefault ($source, 'SOURCE_ARCHIVE_URL', '');
  $installedCommit = valueOrDefault ($source, 'SOURCE_COMMIT', 'unknown');

  if ($repo == '' || $branch == '') {
    echo json_encode (array ('error' => 'Update blocked because config/source.conf does not define SOURCE_REPO and SOURCE_BRANCH.'));
    return;
  }

  if (!isValidSourceValue ($repo) || !isValidSourceValue ($branch)) {
    echo json_encode (array ('error' => 'Update blocked because config/source.conf contains an invalid repository or branch.'));
    return;
  }

  if ($archiveUrl == '') {
    $archiveUrl = 'https://github.com/'. $repo .'/archive/refs/heads/'. $branch .'.tar.gz';
  }

  $latestCommit = getLatestCommit ($repo, $branch);
  if ($latestCommit == '') {
    echo json_encode (array ('error' => 'Unable to reach GitHub update metadata.'));
    return;
  }

  if ($installedCommit != 'unknown' && $installedCommit != '' && $installedCommit == $latestCommit) {
    echo json_encode (array ('error' => 'Update blocked because Pi.NMS is already up to date.'));
    return;
  }

  $preflight = runUpdatePreflight();
  if ($preflight['exit_code'] !== 0) {
    echo json_encode (array (
      'error' => 'Update preflight failed.',
      'log' => $preflight['log']
    ));
    return;
  }

  if (!prepareUpdateJobDirectory ($paths)) {
    echo json_encode (array ('error' => 'Update job directory is not writable by the web server.'));
    return;
  }

  if (isUpdateRunning ($paths)) {
    echo json_encode (array ('error' => 'An update is already running.', 'log' => readLogTail ($paths['log'])));
    return;
  }

  @unlink ($paths['exit']);
  @unlink ($paths['log']);
  $stateWritten = file_put_contents ($paths['state'], json_encode (array (
    'started_at' => gmdate ('c'),
    'repo' => $repo,
    'branch' => $branch
  )));

  if ($stateWritten === false) {
    echo json_encode (array ('error' => 'Unable to write update job state.'));
    return;
  }

  if (file_put_contents ($paths['log'], '') === false) {
    @unlink ($paths['state']);
    echo json_encode (array ('error' => 'Unable to write update job log.'));
    return;
  }

  $env = array (
    'PINMS_REPO' => $repo,
    'PINMS_BRANCH' => $branch,
    'PINMS_ARCHIVE_URL' => $archiveUrl,
    'PINMS_HOME' => $paths['home'],
    'PINMS_INSTALL_DIR' => dirname ($paths['home'])
  );

  $command = buildEnvCommand ($env) .' /bin/bash '. escapeshellarg ($paths['script']);
  $wrapped = '( cd '. escapeshellarg ($paths['log_dir']) .' && '. $command .'; code=$?; echo $code > '. escapeshellarg ($paths['exit']) .' ) >> '. escapeshellarg ($paths['log']) .' 2>&1 & echo $!';
  $pid = trim (shell_exec ($wrapped));

  if ($pid == '') {
    @unlink ($paths['state']);
    echo json_encode (array ('error' => 'Unable to start update process.'));
    return;
  }

  echo json_encode (array ('error' => '', 'pid' => $pid));
}


//------------------------------------------------------------------------------
//  Update Status
//------------------------------------------------------------------------------
function updateStatus() {
  $paths = getUpdatePaths();
  $exitCode = null;
  $running = false;
  $error = '';

  if (file_exists ($paths['exit'])) {
    $exitCode = intval (trim (file_get_contents ($paths['exit'])));
  } elseif (file_exists ($paths['state'])) {
    $running = true;
  } else {
    $error = 'No update has been started.';
  }

  $source = readSourceMetadata();

  echo json_encode (array (
    'running' => $running,
    'exit_code' => $exitCode,
    'log' => readLogTail ($paths['log']),
    'installed_commit' => valueOrDefault ($source, 'SOURCE_COMMIT', 'unknown'),
    'installed_at' => valueOrDefault ($source, 'SOURCE_INSTALLED_AT', 'unknown'),
    'error' => $error
  ));
}


//------------------------------------------------------------------------------
//  Run Update Preflight
//------------------------------------------------------------------------------
function runUpdatePreflight() {
  $paths = getUpdatePaths();
  $source = readSourceMetadata();
  $repo = valueOrDefault ($source, 'SOURCE_REPO', '');
  $branch = valueOrDefault ($source, 'SOURCE_BRANCH', '');
  $archiveUrl = valueOrDefault ($source, 'SOURCE_ARCHIVE_URL', '');

  if ($archiveUrl == '' && $repo != '' && $branch != '') {
    $archiveUrl = 'https://github.com/'. $repo .'/archive/refs/heads/'. $branch .'.tar.gz';
  }

  if (!file_exists ($paths['script'])) {
    return array (
      'exit_code' => 1,
      'log' => 'Update script was not found: '. $paths['script']
    );
  }

  if (!prepareUpdateJobDirectory ($paths)) {
    return array (
      'exit_code' => 1,
      'log' => 'Update job directory is not writable by the web server.'
    );
  }

  $env = array (
    'PINMS_REPO' => $repo,
    'PINMS_BRANCH' => $branch,
    'PINMS_ARCHIVE_URL' => $archiveUrl,
    'PINMS_HOME' => $paths['home'],
    'PINMS_INSTALL_DIR' => dirname ($paths['home'])
  );

  $preflightLog = $paths['log_dir'] . '/web_update_preflight.log';
  $command = buildEnvCommand ($env) .' /bin/bash '. escapeshellarg ($paths['script']) .' --check';
  $wrapped = '( cd '. escapeshellarg ($paths['log_dir']) .' && '. $command .' ) > '. escapeshellarg ($preflightLog) .' 2>&1; echo $?';
  $output = shell_exec ($wrapped);
  $exitCode = ($output === null || trim ($output) === '') ? 1 : intval (trim ($output));

  return array (
    'exit_code' => $exitCode,
    'log' => readLogTail ($preflightLog)
  );
}


//------------------------------------------------------------------------------
//  Read Source Metadata
//------------------------------------------------------------------------------
function readSourceMetadata() {
  $path = '../../../config/source.conf';
  $values = array();

  if (!file_exists ($path)) {
    return $values;
  }

  $lines = file ($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
  foreach ($lines as $line) {
    if (strpos (trim ($line), '#') === 0 || strpos ($line, '=') === false) {
      continue;
    }

    list ($key, $value) = explode ('=', $line, 2);
    $key = trim ($key);
    $value = trim ($value);
    $value = trim ($value, "\"'");
    $values[$key] = $value;
  }

  return $values;
}


//------------------------------------------------------------------------------
//  Get Latest Commit
//------------------------------------------------------------------------------
function getLatestCommit ($repo, $branch) {
  $repo = preg_replace ('/[^A-Za-z0-9_.\/-]/', '', $repo);
  $branch = preg_replace ('/[^A-Za-z0-9_.\/-]/', '', $branch);
  $url = 'https://api.github.com/repos/'. $repo .'/commits/'. $branch;

  $command = 'curl -fsSL --max-time 10 -H "User-Agent: Pi.NMS" '. escapeshellarg ($url);
  $output = shell_exec ($command);
  if ($output == null || $output == '') {
    return '';
  }

  $data = json_decode ($output, true);
  if (!is_array ($data) || !isset ($data['sha'])) {
    return '';
  }

  return $data['sha'];
}


//------------------------------------------------------------------------------
//  Update Paths
//------------------------------------------------------------------------------
function getUpdatePaths() {
  $home = realpath (__DIR__ . '/../../..');
  $logDir = rtrim (sys_get_temp_dir(), '/\\') . '/pinms-update-' . md5 ($home);

  return array (
    'home' => $home,
    'script' => $home . '/install/pinms_update.sh',
    'log_dir' => $logDir,
    'log' => $logDir . '/web_update.log',
    'exit' => $logDir . '/web_update.exit',
    'state' => $logDir . '/web_update.state'
  );
}


//------------------------------------------------------------------------------
//  Prepare Update Job Directory
//------------------------------------------------------------------------------
function prepareUpdateJobDirectory ($paths) {
  if (!is_dir ($paths['log_dir']) && !mkdir ($paths['log_dir'], 0775, true)) {
    return false;
  }

  return is_writable ($paths['log_dir']);
}


//------------------------------------------------------------------------------
//  Is Update Running
//------------------------------------------------------------------------------
function isUpdateRunning ($paths) {
  return file_exists ($paths['state']) && !file_exists ($paths['exit']);
}


//------------------------------------------------------------------------------
//  Build Environment Command
//------------------------------------------------------------------------------
function buildEnvCommand ($env) {
  $parts = array();
  foreach ($env as $key => $value) {
    $parts[] = $key .'='. escapeshellarg ($value);
  }

  return implode (' ', $parts);
}


//------------------------------------------------------------------------------
//  Read Log Tail
//------------------------------------------------------------------------------
function readLogTail ($path) {
  if (!file_exists ($path)) {
    return '';
  }

  $contents = file_get_contents ($path);
  if (strlen ($contents) > 20000) {
    return substr ($contents, -20000);
  }

  return $contents;
}


//------------------------------------------------------------------------------
//  Validate Source Value
//------------------------------------------------------------------------------
function isValidSourceValue ($value) {
  return preg_match ('/^[A-Za-z0-9_.\/-]+$/', $value) === 1;
}


//------------------------------------------------------------------------------
//  Defaults
//------------------------------------------------------------------------------
function valueOrDefault ($array, $key, $default) {
  if (isset ($array[$key]) && $array[$key] != '') {
    return $array[$key];
  }

  return $default;
}

?>
