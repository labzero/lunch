$(function() {
  var $newMcuForm = $('.mortgage-collateral-update-new-form');
  var $pledgeTypeDropdown = $('.mcu-pledge-type-dropdown');
  var $mcuTypeDropdown = $('.mcu-mcu-type-dropdown');
  var $programTypeDropdown = $('.mcu-program-type-dropdown');
  var $pledgeTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[pledge_type]"]');
  var $mcuTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[mcu_type]"]');
  var $programTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[program_type]"]');
  var $mcuUploadInput = $('.mcu-upload-area input[type=file]');
  var $mcuUploadFileNameField = $('.mcu-upload-file-name');
  var $mcuUploadInstructions = $('.mcu-upload-instructions');
  var $mcuUploadCompleteSection = $('.mcu-upload-complete');

  $pledgeTypeField.on('change', function(e) {
    $([$mcuTypeDropdown, $programTypeDropdown]).each(function() {resetDropdown(this)});
    enableDropdown($mcuTypeDropdown);
    disableDropdown($programTypeDropdown);
    if ($pledgeTypeField.val() === 'specific') {
      $('.mcu-upload-legal-section-specific').show();
      $('.mcu-upload-legal-section-blanket-lien').hide();
    } else if ($pledgeTypeField.val() === 'blanket_lien') {
      $('.mcu-upload-legal-section-blanket-lien').show();
      $('.mcu-upload-legal-section-specific').hide();
    };
  });

  $mcuTypeField.on('change', function(e) {
    $programTypeDropdown.removeClass('selected');
    $selectedProgramType = $('.mcu-program-type-dropdown.' + $mcuTypeField[0].options[$mcuTypeField[0].selectedIndex].value);
    $selectedProgramType.addClass('selected');
    enableDropdown($programTypeDropdown);
    resetDropdown($programTypeDropdown);
  });

  function enableDropdown($dropdown) {
    $dropdown.attr('disabled', false);
  };

  function disableDropdown($dropdown) {
    $dropdown.attr('disabled', true);
  };

  function resetDropdown($dropdown) {
    var placeHolderText = $dropdown.data('default-text');
    $dropdown.find('select').val("");
    $dropdown.find('.dropdown-selection').text(placeHolderText);
    $dropdown.find('li').removeClass('selected');
  };

  $mcuUploadInput.on('change', function(e) {
    $mcuUploadFileNameField.text(e.target.files[0].name);
    $mcuUploadInstructions.hide();
    $mcuUploadCompleteSection.show();
  });

  $('.mcu-upload-file-discard').on('click', function(e) {
    $mcuUploadInput.val('');
    $mcuUploadFileNameField.text('');
    $mcuUploadCompleteSection.hide();
    $mcuUploadInstructions.show();
  });
});