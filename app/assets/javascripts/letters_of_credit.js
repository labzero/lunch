$(function() {
  $letterOfCreditPreviewFormSubmit = $('.letter-of-credit-preview').find('input[type=submit]');
  $letterOfCreditRequestForm = $('.letter-of-credit-request-form');
  var $amountField = $('input[name="letter_of_credit_request[amount]"]');
  var $secureIDTokenField = $('#securid_token');
  var $secureIDPinField = $('#securid_pin');

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

  function validateForm() {
    if($amountField.val()) {
      $letterOfCreditPreviewFormSubmit.attr('disabled', false).addClass('active');
    } else {
      $letterOfCreditPreviewFormSubmit.attr('disabled', true).removeClass('active');
    };
  };

  // Validate length of SecurID token and pin
  Fhlb.Utils.bindFormSubmitStateToSecureIDFields($letterOfCreditRequestForm, $secureIDPinField, $secureIDTokenField);

  $letterOfCreditRequestForm.on('submit', function(e) {
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
      return false;
    };
  });

  if ($letterOfCreditRequestForm.length > 0) {
    Fhlb.Utils.findAndDisplaySecurIDErrors($letterOfCreditRequestForm);
  };
});