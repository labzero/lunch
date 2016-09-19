$(function() {
  var $form = $('.manage-securities-form');
  var $checkboxes = $form.find('input[type=checkbox]');
  var $submitButtons = $form.find('a[data-manage-securities-form-submit]');
  var $securitiesUploadInstructions = $('.securities-upload-instructions');
  var $securitiesReleaseWrapper = $('.securities-release-table-wrapper');
  var $securitiesField = $('input[name="securities"]');

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
      $(input).attr('name', 'securities_request[securities]');
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
    var requiredDeliveryInstructionsFields = $('.securities-delivery-instructions-field[data-delivery-instruction-type="' + deliveryInstructionsType + '"] input');
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