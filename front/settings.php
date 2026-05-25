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
            </div>

          </div>
        </div>
      </div>

    </section>
    <!-- /.content -->
  </div>
  <!-- /.content-wrapper -->

<!-- ----------------------------------------------------------------------- -->
<?php
  require 'php/templates/footer.php';
?>

<!-- page script ----------------------------------------------------------- -->
<script>

  main();

// -----------------------------------------------------------------------------
function main () {
  checkForUpdates();
}


// -----------------------------------------------------------------------------
function checkForUpdates () {
  $('#updateStatus').html ('Checking...');

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
    } else if (result.update_available == false) {
      $('#updateStatus').html ('<span class="label label-success">Up to date</span>');
    } else {
      $('#updateStatus').html ('<span class="label label-default">Unknown</span>');
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