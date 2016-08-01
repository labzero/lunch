$(function() {
  var $form = $('.manage-securities-form');
  var $checkboxes = $form.find('input[type=checkbox]');
  var $submitButton = $form.find('input[type=submit]');
  var $securitiesUploadInstructions = $('.securities-upload-instructions');
  var $securitiesReleaseWrapper = $('.securities-release-table-wrapper');
  $checkboxes.on('change', function(e){
    // if boxes checked and all values are the same, enable submit
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
    if (status) {
      $submitButton.attr('disabled', false);
    } else {
      $submitButton.attr('disabled', true);
    };
  });

  // Value of data attribute used in CSS to show/hide appropriate 'delivery-instructions-field'
  $('select[name="securities_release_request[delivery_type]"]').on('change', function(){
    $('.securities-delivery-instructions-fields').attr('data-selected-delivery-instruction', $(this).val());
  });

  // Confirm deletion of release
  $('.delete-release-trigger').on('click', function(e) {
    confirmReleaseDeletion();
  });

  function confirmReleaseDeletion() {
    $('body').flyout({
      topContent: $('.delete-release-flyout').clone(true),
      hideCloseButton: true
    });
    $('.flyout').addClass('flyout-confirmation-dialogue');
  };

  // Handle DELETE request
  $('.delete-release-flyout').on('ajax:success', function(e, data, status, xhr) {
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

  // Add the securities fields to release form from the download form.  Keeps one source of truth for securities in the DOM.
  $('.securities-submit-release-form').on('submit', function(e){
    var submitReleaseForm = $(this);
    var securitiesFieldsClones = $('input[name="securities"]').clone();
    $.each(securitiesFieldsClones, function(i, input) {
      $(input).attr('name', 'securities_release_request[securities]');
      submitReleaseForm.append(input);
    });

  });

  var $securitiesForm = $('.securities-submit-release-form');
  var $submitField = $securitiesForm.find('input[type=submit]');
  var $secureIDTokenField = $('#securid_token');
  var $secureIDPinField = $('#securid_pin');

  // Validate length of SecurID token and pin
  if ($secureIDPinField.length && $secureIDTokenField.length) {
    $.each([$secureIDPinField, $secureIDTokenField], (function(i, $element){
      $element.on('keyup', function(){
        if ($secureIDTokenField.val().length == 6 && $secureIDPinField.val().length == 4) {
          $submitField.addClass('active');
          $submitField.attr('disabled', false);
        } else {
          $submitField.removeClass('active');
          $submitField.attr('disabled', true);
        };
      });
    }));
  };

  if ($securitiesForm.length > 0) {
    Fhlb.Utils.findAndDisplaySecurIDErrors($securitiesForm);
  };

  $securitiesForm.on('submit', function(e) {
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
      return false;
    } else {
      return true;
    }
  });

  $securitiesReleaseWrapper.on('click', '.safekeep-pledge-upload-again', function(e){
    $securitiesUploadInstructions.hide();
    $('.safekeep-pledge-download-area').show();
    $securitiesReleaseWrapper.empty();
  });

  $('.additional-legal h3').on('click', function(event) {
    $('.additional-legal').toggleClass('expanded-legal');
  });
});