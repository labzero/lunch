$(function() {
  var $form = $('.manage-securities-form');
  var $checkboxes = $form.find('input[type=checkbox]');
  var $submitButtons = $form.find('a[data-manage-securities-form-submit]');
  var $securitiesUploadInstructions = $('.securities-upload-instructions');
  var $securitiesReleaseWrapper = $('.securities-release-table-wrapper');
  var $securitiesField = $('input[name="securities"]');
  var $targetControl;
  var $jobStatusTimer;
  var $jobCancelUrl;
  var $loadingFlyout;

  function enableSubmitIfSameStatus() {
    // if boxes checked and all values are the same, assign `securities_request_kind` and enable submit
    var status = false;
    $form.find('input[type=checkbox]:checked').each(function(){
      var thisStatus = $(this).data('status');
      if (!status) {
        status = thisStatus;
      }
      else if (thisStatus != status) {
        status = false;
        return false;
      };
    });
    $submitButtons.attr('disabled', status ? false : true);
  };

  $checkboxes.on('change', enableSubmitIfSameStatus);
  $('.manage-securities-table').on('checkboxes-reset.dt', enableSubmitIfSameStatus);

  $submitButtons.on('click', function(event) {
    var actionUrl = $(event.currentTarget).data('manage-securities-form-submit');
    $form.attr('action', actionUrl).submit();
  });

  // Value of data attribute used in CSS to show/hide appropriate 'delivery-instructions-field'
  $('select[name="securities_request[delivery_type]"]').on('change', function(){
    $('.securities-delivery-instructions-fields').attr('data-selected-delivery-instruction', $(this).val());
  });

  // Confirm deletion of release
  $('.delete-request-trigger').on('click', function(e) {
    confirmReleaseDeletion();
  });

  function confirmReleaseDeletion() {
    $('body').flyout({
      topContent: $('.delete-request-flyout').clone(true),
      hideCloseButton: true
    });
    $('.flyout').addClass('flyout-confirmation-dialogue');
  };

  // Handle DELETE request
  $('.delete-request-flyout').on('ajax:success', function(e, data, status, xhr) {
    window.location.href = data['url']
  }).on('ajax:error', function(e, data, status, xhr) {
    var $errorSection = $('.securities-delete-request-error');
    var error_message = data['error_message'];
    if (error_message) {
      $errorSection.find('p').text(error_message);
    };
    $('.securities-delete-request-confirmation').hide();
    $errorSection.show();
  });

  // Toggle Edit Securities Instructions
  $('.securities-download').on('click', function(){
    $('.securities-download-instructions').toggle();
  });


  // Toggle Edit Securities Instructions for Pledging and Safekeeping New Securities
  $('.securities-download-safekeep-pledge').on('click', function(){
    $securitiesUploadInstructions.toggle();
  });

  var $securitiesForm = $('.securities-submit-request-form');
  var $submitField = $securitiesForm.find('input[type=submit]');
  var $secureIDTokenField = $('#securid_token');
  var $secureIDPinField = $('#securid_pin');

  // Add the securities fields to release form from the download form.  Keeps one source of truth for securities in the DOM.
  $('.securities-submit-request-form').on('submit', function(e){
    var submitReleaseForm = $(this);
    var securitiesFieldsClones = $('input[name="securities"]').clone();
    $.each(securitiesFieldsClones, function(i, input) {
      $(input).attr('name', 'securities_request[securities]');
      submitReleaseForm.append(input);
    });
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
      return false;
    } else {
      trackRequestFormSubmit();
      return true;
    }
  });

  // Validate length of SecurID token and pin
  if ($secureIDPinField.length && $secureIDTokenField.length) {
    $.each([$secureIDPinField, $secureIDTokenField], (function(i, $element){
      $element.on('keyup', validateSecuritiesRequestFields);
    }));
  };

  // Validate input fields
  $securitiesForm.find('input').on('keyup', validateSecuritiesRequestFields);
  $securitiesForm.find('select').on('change', validateSecuritiesRequestFields);
  $securitiesField.on('change', validateSecuritiesRequestFields);
  validateSecuritiesRequestFields();

  function validateSecuritiesRequestFields() {
    if (brokerInstructionsValid() && deliveryInstructionsValid() && securitiesValid() && secureIDValid()) {
      $submitField.addClass('active');
      $submitField.attr('disabled', false);
    } else {
      $submitField.removeClass('active');
      $submitField.attr('disabled', true);
    };
  };

  function secureIDValid() {
    if ($secureIDPinField.length && $secureIDTokenField.length) {
      return $secureIDTokenField.val().length == 6 && $secureIDPinField.val().length == 4;
    } else {
      return true;
    };
  };

  function securitiesValid() {
    var isValid = ($securitiesField.val() && $securitiesField.val() !== 'null') ? true : false;
    return isValid;
  };

  function brokerInstructionsValid() {
    var inputFieldNames = ['trade_date', 'settlement_date'];
    var selectFieldNames = ['pledge_type', 'transaction_code', 'settlement_type'];
    var brokerInstructionsFields = [];
    $.each(inputFieldNames, function(i, fieldName) {
      var field = $('input[name="securities_request[' + fieldName + ']"]');
      field.length ? brokerInstructionsFields.push(field) : null;
    });
    $.each(selectFieldNames, function(i, fieldName) {
      var field = $('select[name="securities_request[' + fieldName + ']"]');
      field.length ? brokerInstructionsFields.push(field) : null;
    });
    return fieldsValid(brokerInstructionsFields);
  };

  function deliveryInstructionsValid() {
    var deliveryInstructionsType = $('.securities-delivery-instructions-fields').attr('data-selected-delivery-instruction');
    var requiredDeliveryInstructionsFields = $('.securities-delivery-instructions-field[data-delivery-instruction-type="' + deliveryInstructionsType + '"] input:not([data-required=false])');
    return fieldsValid(requiredDeliveryInstructionsFields);
  };

  function fieldsValid(fields) {
    var isValid = true;
    $.each(fields, function(i, field) {
      if (!$(field).val()) {
        isValid = false;
        return false;
      };
    });
    return isValid;
  };

  if ($securitiesForm.length > 0) {
    Fhlb.Utils.findAndDisplaySecurIDErrors($securitiesForm);
  };

  $securitiesReleaseWrapper.on('click', '.safekeep-pledge-upload-again', function(e){
    $securitiesUploadInstructions.hide();
    $('.safekeep-pledge-download-area').show();
    $securitiesReleaseWrapper.empty();
    $securitiesField.val('null');
    validateSecuritiesRequestFields();
    $('.securities-request-upload-success').hide();
  });

  $('.additional-legal h3').on('click', function(event) {
    $('.additional-legal').toggleClass('expanded-legal');
  });

 function bindControls(targetControl, targetEvent, targetUrl) {
    $targetControl = $(targetControl);
    $loadingFlyout = $('.loading-flyout');
    $targetControl.on(targetEvent, function(event){
      event.stopPropagation();
      event.preventDefault();
      openLoadingFlyout();
      $.ajax({
        url     : $(this).attr(targetUrl),
        method  : 'GET',
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

  bindControls('.authorized-requests a', 'click', 'href');

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

  // BEGIN - Google Analytics
  var authorizer = $submitField.data('authorizer');
  function trackRequestFormSubmit() {
    if (authorizer) {
      var hasRequestId = $('input[name="securities_request[request_id]"]').val().length;
      if (hasRequestId) {
        Fhlb.Track.securities_authorize_request();
      } else {
        Fhlb.Track.securities_submit_request();
        Fhlb.Track.securities_authorize_request();
      };
    } else {
      Fhlb.Track.securities_submit_request();
    };
  };

  if ($('.securities-submit-request-form-errors').length) {
    authorizer ? Fhlb.Track.securities_authorize_request_failed() : Fhlb.Track.securities_submit_request_failed();
  };

  $('.securities-submit-request-form').length ? Fhlb.Track.securities_request_form() : null;
  $('.securities-download-instructions, .safekeep-pledge-download-area').on('file-uploading', Fhlb.Track.securities_file_upload);
  $('.securities-download-instructions, .safekeep-pledge-download-area').on('upload-failed', Fhlb.Track.securities_file_upload_failed);
  // END - Google Analytics
});