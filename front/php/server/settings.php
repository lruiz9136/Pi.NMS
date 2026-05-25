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
      default:             echo json_encode (array ('error' => 'Unknown action')); break;
    }
  }


//------------------------------------------------------------------------------
//  Check for Update
//------------------------------------------------------------------------------
function checkUpdate() {
  $source = readSourceMetadata();
  $repo = valueOrDefault ($source, 'SOURCE_REPO', 'lruiz9136/Pi.NMS');
  $branch = valueOrDefault ($source, 'SOURCE_BRANCH', 'main');
  $installedCommit = valueOrDefault ($source, 'SOURCE_COMMIT', 'unknown');
  $installedAt = valueOrDefault ($source, 'SOURCE_INSTALLED_AT', 'unknown');

  $latestCommit = getLatestCommit ($repo, $branch);
  $error = '';
  $updateAvailable = null;

  if ($latestCommit == '') {
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
//  Defaults
//------------------------------------------------------------------------------
function valueOrDefault ($array, $key, $default) {
  if (isset ($array[$key]) && $array[$key] != '') {
    return $array[$key];
  }

  return $default;
}

?>