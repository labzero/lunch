$(function () {
  var $reportForm;
  var $deferredReport;
  var jobStatusTimer;
  var jobCancelUrl;

  function bindReport() {
    $reportForm = $('.report .report-header-buttons form');
    $deferredReport = $('.report[data-deferred]');

    $reportForm.on('submit', function(event){
      event.stopPropagation();
      event.preventDefault();
      openLoadingFlyout();
      $.ajax({
        url     : $(this).attr('action'),
        method  : $(this).attr('method'),
        dataType: 'json',
        data    : $(this).serialize(),
        success : function( data, status, xhr ) {
          jobCancelUrl = data.jobCancelUrl;
          checkDownloadJobStatus(data.job_status_url);
        },
        error   : function( xhr, status, err ) {
          downloadError();
        }
      });
    });

    if ($deferredReport.length == 1) {
      checkDeferredJobStatus($deferredReport, $deferredReport.data('deferred'), $deferredReport.data('deferred-load'));
    };
  };

  bindReport();

  function openLoadingFlyout() {
    $('body').flyout({topContent: $('.loading-report').clone(true)});
    $('.flyout').addClass('flyout-loading-message');
  };

  $('.cancel-report-download').on('click', function(){
    $.get(jobCancelUrl);
    clearTimeout(jobStatusTimer);
  });

  function checkDownloadJobStatus(url) {
    $.get(url)
      .done(function(data) {
        var job_status = data.job_status;
        if (job_status == 'completed') {
          downloadJob(data.download_url);
        } else if(job_status == 'failed') {
          downloadError();
        } else {
          jobStatusTimer = setTimeout(function(){checkDownloadJobStatus(url)}, 1000);
        };
      })
      .fail(function(data) {
        downloadError();
      });
  };

  function downloadJob(url) {
    $reportForm.trigger('reportDownloadStarted', {download_url: url});
    closeFlyout();
    window.location.href = url;
  };

  function closeFlyout() {
    $('.flyout').trigger('flyout-close');
  };

  function downloadError() {
    $('.flyout').addClass('flyout-loading-error');
  };

  function deferredJobError($report) {
    $report.find('.table-loading').removeClass('table-loading').addClass('table-error');
  };

  function loadDeferredJob($report, url) {
    $.get(url).done(function(data) {
      var $newReport = $(data);
      $report.replaceWith($newReport);
      $newReport.trigger('dropdown-rebind');
      $newReport.trigger('filter-rebind');
      $newReport.trigger('datepicker-rebind');
      $newReport.trigger('table-rebind');
      bindReport();
    }).fail(function() {
      deferredJobError($report);
    });
  };

  function checkDeferredJobStatus($report, status_url, load_url) {
    $.get(status_url).done(function(data) {
      var job_status = data.job_status;
      if (job_status == 'completed') {
        loadDeferredJob($report, load_url);
      } else if(job_status == 'failed') {
        deferredJobError($report);
      } else {
        jobStatusTimer = setTimeout(function(){checkDeferredJobStatus($report, status_url, load_url)}, 1000);
      };
    }).fail(function() {
      deferredJobError($report);
    });
  };

});