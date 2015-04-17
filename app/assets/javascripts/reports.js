$(function () {
  var $advances_report_form = $('.advances-detail-report .report-header-buttons form');
  var jobStatusTimer;
  var job_cancel_url;

  $advances_report_form.on('submit', function(event){
    openLoadingFlyout();
  });

  $advances_report_form.on('ajax:success', function(event, data, status, xhr) {
    job_cancel_url = data.job_cancel_url;
    checkJobStatus(data.job_status_url, data.report_format);
  });

  $advances_report_form.on('ajax:failure', function(event, data, status, xhr) {
    downloadError();
  });

  function openLoadingFlyout() {
    $('body').flyout({topContent: $('.loading-report').clone(true)});
    $('.flyout').addClass('flyout-loading-message');
  };

  function closeLoadingFlyout() {
    $('body').flyout({closeFlyoutAction: {parentEl: $('body'), event:{target:null}}}); // TODO check if sneaking an empty event in there with a null target is legit
  };

  $('.cancel-report-download').on('click', function(){
    $.get(job_cancel_url);
    clearTimeout(jobStatusTimer);
    closeLoadingFlyout();
  });

  function checkJobStatus(url, format) {
    $.get(url, {export_format: format})
      .done(function(data) {
        var job_status = data.job_status;
        if (job_status == 'completed') {
          downloadJob(data.download_url, data.export_format);
        }
        else if(job_status == 'failed') {
          downloadError();
        } else {
          jobStatusTimer = setTimeout(function(){checkJobStatus(url, data.export_format)}, 1000);
        };
      })
      .fail(function(data) {
        downloadError();
      });
  };

  function downloadJob(url, export_format) {
    closeLoadingFlyout();
    var export_param = '?export_format=' + export_format;
    window.location.href = url + export_param;
  };

  function downloadError() {
    $('.flyout').addClass('flyout-loading-error');
    var $flyoutMessage = $('.flyout .loading-report p');
    var $flyoutLink = $('.flyout .loading-report a');
    $flyoutMessage.text($flyoutMessage.data('error-text'));
    $flyoutLink.text($flyoutLink.data('error-text'));
  };

});