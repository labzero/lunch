$(function() {
  $beneficiaryNewFormSubmit = $('.beneficiary-new').find('input[type=submit]');
  var $name = $('input[name="beneficiary_request[name]"]');
  var $city = $('input[name="beneficiary_request[city]"]');
  var $zip = $('input[name="beneficiary_request[zip]"]');
  var $street_address = $('textarea[name="beneficiary_request[street_address]"]');
  var $state = $('select[name="beneficiary_request[state]"]');

  $name.on('keyup', function(e){
    validateForm();
  });

  $city.on('keyup', function(e){
    validateForm();
  });

  $zip.on('keyup', function(e){
    validateForm();
  });

  $street_address.on('keyup', function(e){
    validateForm();
  });

  $state.on('change', function(e){
    validateForm();
  });

  function validateForm() {
    if ($name.val() && $city.val() && $zip.val() && $street_address.val() && $('.dropdown-selection').text() != "Select State") {
      $beneficiaryNewFormSubmit.attr('disabled', false).addClass('active');
    } else {
      $beneficiaryNewFormSubmit.attr('disabled', true).removeClass('active');
    };
  };
});