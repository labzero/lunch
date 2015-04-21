$(function () {
  var $reportForm = $('.report .report-header-buttons form');
  var jobStatusTimer;
  var jobCancelUrl;

  $reportForm.on('submit', function(event){
    openLoadingFlyout();
  });

  $reportForm.on('ajax:success', function(event, data, status, xhr) {
    jobCancelUrl = data.jobCancelUrl;
    checkJobStatus(data.job_status_url);
  });

  $reportForm.on('ajax:failure', function(event, data, status, xhr) {
    downloadError();
  });

  function openLoadingFlyout() {
    $('body').flyout({topContent: $('.loading-report').clone(true)});
    $('.flyout').addClass('flyout-loading-message');
  };

  $('.cancel-report-download').on('click', function(){
    $.get(jobCancelUrl);
    clearTimeout(jobStatusTimer);
  });

  function checkJobStatus(url) {
    $.get(url)
      .done(function(data) {
        var job_status = data.job_status;
        if (job_status == 'completed') {
          downloadJob(data.download_url);
        } else if(job_status == 'failed') {
          downloadError();
        } else {
          jobStatusTimer = setTimeout(function(){checkJobStatus(url)}, 1000);
        };
      })
      .fail(function(data) {
        downloadError();
      });
  };

  function downloadJob(url) {
    window.location.href = url;
    $reportForm.trigger('reportDownloadStarted', {download_url: url});
    closeFlyout();
  };

  function closeFlyout() {
    $('.flyout').trigger('flyout-close');
  };

  function downloadError() {
    $('.flyout').addClass('flyout-loading-error');
  };

});