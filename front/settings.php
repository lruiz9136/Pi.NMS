<!-- ---------------------------------------------------------------------------
#  Pi.NMS
#  Lightweight network management system
#
#  settings.php - Front module. Settings page
#-------------------------------------------------------------------------------
#  lruiz9136 2026        GNU GPLv3
#--------------------------------------------------------------------------- -->

<?php
  require 'php/templates/header.php';
?>

<!-- Page ------------------------------------------------------------------ -->
  <div class="content-wrapper">

<!-- Content header--------------------------------------------------------- -->
    <section class="content-header">
      <?php require 'php/templates/notification.php'; ?>

      <h1 id="pageTitle">
         Settings
      </h1>
    </section>

<!-- Main content ---------------------------------------------------------- -->
    <section class="content">

      <div class="row">
        <div class="col-lg-8 col-md-10 col-xs-12">
          <div class="box box-aqua">

            <div class="box-header">
              <h3 class="box-title text-aqua">Updates</h3>
            </div>

            <div class="box-body">
              <table class="table table-bordered table-striped">
                <tbody>
                  <tr>
                    <th style="width: 180px;">Repository</th>
                    <td id="sourceRepo">--</td>
                  </tr>
                  <tr>
                    <th>Branch</th>
                    <td id="sourceBranch">--</td>
                  </tr>
                  <tr>
                    <th>Installed Commit</th>
                    <td id="sourceCommit">--</td>
                  </tr>
                  <tr>
                    <th>Latest Commit</th>
                    <td id="latestCommit">--</td>
                  </tr>
                  <tr>
                    <th>Installed At</th>
                    <td id="sourceInstalledAt">--</td>
                  </tr>
                  <tr>
                    <th>Status</th>
                    <td id="updateStatus">--</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="box-footer">
              <button type="button" class="btn btn-primary" onclick="checkForUpdates()">
                <i class="fa fa-refresh"></i> Check for Updates
              </button>
              <button type="button" class="btn btn-warning" id="runUpdateButton" onclick="runUpdate()" disabled>
                <i class="fa fa-download"></i> Run Update
              </button>
            </div>

          </div>

          <div class="box box-warning" id="updateLogBox" style="display: none;">
            <div class="box-header">
              <h3 class="box-title text-yellow">Update Log</h3>
            </div>
            <div class="box-body">
              <pre id="updateLog" style="min-height: 180px; max-height: 420px; overflow: auto; white-space: pre-wrap;">--</pre>
            </div>
          </div>
        </div>
      </div>

    </section>
    <!-- /.content -->
  </div>
  <!-- /.content-wrapper -->

  <div class="modal fade" id="updateConfirmModal" tabindex="-1" role="dialog" aria-labelledby="updateConfirmTitle">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header bg-yellow">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 class="modal-title" id="updateConfirmTitle">
            <i class="fa fa-download"></i> Run Update
          </h4>
        </div>
        <div class="modal-body">
          <p>Update Pi.NMS from the configured branch now?</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
          <button type="button" class="btn btn-warning" onclick="confirmRunUpdate()">
            <i class="fa fa-download"></i> Run Update
          </button>
        </div>
      </div>
    </div>
  </div>

<!-- ----------------------------------------------------------------------- -->
<?php
  require 'php/templates/footer.php';
?>

<!-- page script ----------------------------------------------------------- -->
<script>

  main();
  var updatePollTimer = null;

// -----------------------------------------------------------------------------
function main () {
  checkForUpdates();
}


// -----------------------------------------------------------------------------
function checkForUpdates () {
  $('#updateStatus').html ('Checking...');
  $('#runUpdateButton').prop ('disabled', true);

  $.get('php/server/settings.php?action=checkUpdate', function(data) {
    var result = JSON.parse(data);

    $('#sourceRepo').html        (escapeHtml(result.repo));
    $('#sourceBranch').html      (escapeHtml(result.branch));
    $('#sourceCommit').html      (formatCommit(result.installed_commit));
    $('#latestCommit').html      (formatCommit(result.latest_commit));
    $('#sourceInstalledAt').html (escapeHtml(result.installed_at));

    if (result.error != '') {
      $('#updateStatus').html ('<span class="label label-danger">Error</span> ' + escapeHtml(result.error));
    } else if (result.update_available == true) {
      $('#updateStatus').html ('<span class="label label-warning">Update available</span>');
      checkUpdateRunner();
    } else if (result.update_available == false) {
      $('#updateStatus').html ('<span class="label label-success">Up to date</span>');
    } else {
      $('#updateStatus').html ('<span class="label label-default">Unknown</span>');
    }
  });
}


// -----------------------------------------------------------------------------
function checkUpdateRunner () {
  $('#updateStatus').html ('<span class="label label-warning">Update available</span> Checking updater...');

  $.get('php/server/settings.php?action=checkRunner', function(data) {
    var result = JSON.parse(data);

    if (result.ok == true) {
      $('#updateStatus').html ('<span class="label label-warning">Update available</span>');
      $('#runUpdateButton').prop ('disabled', false);
      return;
    }

    $('#updateLogBox').show();
    $('#updateLog').text(result.log || result.error || 'Update preflight failed.');
    $('#updateStatus').html ('<span class="label label-danger">Updater not ready</span>');
  });
}


// -----------------------------------------------------------------------------
function runUpdate () {
  $('#updateConfirmModal').modal('show');
}


// -----------------------------------------------------------------------------
function confirmRunUpdate () {
  $('#updateConfirmModal').modal('hide');

  $('#runUpdateButton').prop ('disabled', true);
  $('#updateLogBox').show();
  $('#updateLog').text('Starting update...');
  $('#updateStatus').html ('<span class="label label-info">Update running</span>');

  $.post('php/server/settings.php?action=runUpdate', function(data) {
    var result = JSON.parse(data);

    if (result.error != '') {
      $('#updateStatus').html ('<span class="label label-danger">Error</span> ' + escapeHtml(result.error));
      $('#updateLog').text(result.log || result.error);
      return;
    }

    pollUpdateStatus();
    updatePollTimer = setInterval(pollUpdateStatus, 3000);
  });
}


// -----------------------------------------------------------------------------
function pollUpdateStatus () {
  $.get('php/server/settings.php?action=updateStatus', function(data) {
    var result = JSON.parse(data);
    $('#updateLogBox').show();
    $('#updateLog').text(result.log || '--');
    $('#updateLog').scrollTop($('#updateLog')[0].scrollHeight);

    if (result.running == true) {
      $('#updateStatus').html ('<span class="label label-info">Update running</span>');
      return;
    }

    if (updatePollTimer != null) {
      clearInterval(updatePollTimer);
      updatePollTimer = null;
    }

    if (result.exit_code == 0) {
      $('#updateStatus').html ('<span class="label label-success">Update complete</span>');
      $('#sourceCommit').html      (formatCommit(result.installed_commit));
      $('#sourceInstalledAt').html (escapeHtml(result.installed_at));
      setTimeout(checkForUpdates, 1500);
    } else if (result.exit_code != null) {
      $('#updateStatus').html ('<span class="label label-danger">Update failed</span>');
      $('#runUpdateButton').prop ('disabled', false);
    } else if (result.error != '') {
      $('#updateStatus').html ('<span class="label label-danger">Error</span> ' + escapeHtml(result.error));
    }
  });
}


// -----------------------------------------------------------------------------
function formatCommit (commit) {
  if (commit == null || commit == '' || commit == 'unknown') {
    return '--';
  }

  return '<code>' + escapeHtml(commit.substring(0, 12)) + '</code>';
}


// -----------------------------------------------------------------------------
function escapeHtml (text) {
  if (text == null || text == '') {
    return '--';
  }

  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

</script>
