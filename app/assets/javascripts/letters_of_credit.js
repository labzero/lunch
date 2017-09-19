$(function() {
  $letterOfCreditAmendFormSubmit = $('.letter-of-credit-amend-request').find('input[type=submit]');
  $letterOfCreditRequestForm = $('.letter-of-credit-request-form');
  $letterOfCreditRequestPreviewForm = $('.letter-of-credit-preview');

  $letterOfCreditPreviewFormSubmit = $('.letter-of-credit-preview').find('input[type=submit]');
  $letterOfCreditAmendPreviewForm = $('.letter-of-credit-amend-preview')
  $letterOfCreditAmendPreviewFormSubmit = $('.letter-of-credit-amend-preview').find('input[type=submit]');


  var $secureIDTokenField = $('#securid_token');
  var $secureIDPinField = $('#securid_pin');

  var $amountField = $('input[name="letter_of_credit_request[amount]"]');
  var $expirationDateField = $('input[type="hidden"][name="letter_of_credit_request[expiration_date]"]');
  var $amendedAmountField = $('input[name="letter_of_credit_request[amended_amount]"]');
  var $amendedExpirationDateField = $(".input-field-container-horizontal.amended_expiration_date .datepicker_input_field .input-mini");

  $('.amended_expiration_date .datepicker-trigger').on('showCalendar.daterangepicker', function(e) {
    enableSubmitIfValuesChanged();
  });
  $amendedAmountField.on('keyup', function(e) {enableSubmitIfValuesChanged();} );

  function enableSubmitIfValuesChanged() {
    // On the Letter of Credit amendment page, submit button is enable iff user has changed the amended amount or the amended expiration date
    var expDate = (moment)( $expirationDateField.val() ).format('MM/DD/YYYY');
    var amendedExpDate = (moment)( $amendedExpirationDateField.last().val() ).format('MM/DD/YYYY');
    var disable = (($amountField.val() == $amendedAmountField.val()) && (expDate == amendedExpDate));
    $letterOfCreditAmendFormSubmit.attr('disabled', disable);
  };

  $amountField.on('keypress', function(e){
    Fhlb.Utils.onlyAllowDigits(e);
  });
  $amountField.on('keyup', function(e){
    Fhlb.Utils.addCommasToInputField(e);
    validateForm();
  });
  if ($amountField.length > 0) {
    Fhlb.Utils.addCommasToInputField({target: $amountField});
  };

  $amendedAmountField.on('keypress', function(e){
      Fhlb.Utils.onlyAllowDigits(e);
  });
  $amendedAmountField.on('keyup', function(e){
      Fhlb.Utils.addCommasToInputField(e);
      enableSubmitIfValuesChanged();
  });
  if ($amendedAmountField.length > 0) {
    Fhlb.Utils.addCommasToInputField({target: $amendedAmountField});
  };

  function validateForm() {
    if($amountField.val()) {
      $letterOfCreditPreviewFormSubmit.attr('disabled', false).addClass('active');
    } else {
      $letterOfCreditPreviewFormSubmit.attr('disabled', true).removeClass('active');
    };
  };

  // Validate length of SecurID token and pin
  Fhlb.Utils.bindFormSubmitStateToSecureIDFields($letterOfCreditRequestPreviewForm, $secureIDPinField, $secureIDTokenField);
  Fhlb.Utils.bindFormSubmitStateToSecureIDFields($letterOfCreditAmendPreviewForm, $secureIDPinField, $secureIDTokenField);

  $letterOfCreditRequestPreviewForm.on('submit', function(e) {
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
      return false;
    };
  });

  $letterOfCreditAmendPreviewForm.on('submit', function(e) {
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
        return false;
    };
  });

  if ($letterOfCreditRequestForm.length > 0) {
    Fhlb.Utils.findAndDisplaySecurIDErrors($letterOfCreditRequestForm);
  };

  function bindControls(targetControl, targetEvent, targetUrl, method) {
    $targetControl = $(targetControl);
    $loadingFlyout = $('.loading-flyout');
    $targetControl.on(targetEvent, function(event){
      event.stopPropagation();
      event.preventDefault();
      openLoadingFlyout();
      $.ajax({
        url     : $(this).attr(targetUrl),
        method  : method,
        dataType: 'json',
        data    : $(this).serialize(),
        success : function( data, status, xhr ) {
          $jobCancelUrl = data.job_cancel_url;
          checkDownloadJobStatus(data.job_status_url);
        },
        error   : function( xhr, status, err ) {
          downloadError();
        }
      });
    });

    $('.cancel-download').on('click', function(){
      cancelDownloadJob();
    });
  };

  bindControls('.letters-of-credit-download-pdf', 'click', 'href', 'GET');

  function openLoadingFlyout() {
    $('body').flyout({topContent: $($loadingFlyout).clone(true)});
    $('.flyout').addClass('flyout-loading-message');
  };

  function cancelDownloadJob() {
    $targetControl.trigger('downloadCanceled', {job_cancel_url: $jobCancelUrl});
    $.get($jobCancelUrl);
    clearTimeout($jobStatusTimer);
  };

  function checkDownloadJobStatus(url) {
    $.get(url)
      .done(function(data) {
        var job_status = data.job_status;
        if (job_status == 'completed') {
          downloadJob(data.download_url);
        } else if(job_status == 'failed') {
          downloadError();
        } else {
          $jobStatusTimer = setTimeout(function(){checkDownloadJobStatus(url)}, 1000);
        };
      })
      .fail(function(data) {
        downloadError();
      });
  };

  function downloadJob(url) {
    $targetControl.trigger('downloadStarted', {download_url: url});
    closeFlyout();
    window.location.href = url;
  };

  function closeFlyout() {
    $('.flyout').trigger('flyout-close');
  };

  function downloadError() {
    $('.flyout').addClass('flyout-loading-error');
  };
});