$(function() {
  var $newMcuForm = $('.mortgage-collateral-update-new-form');
  var $pledgeTypeDropdown = $('.mcu-pledge-type-dropdown');
  var $mcuTypeDropdown = $('.mcu-mcu-type-dropdown');
  var $programTypeDropdown = $('.mcu-program-type-dropdown');
  var $pledgeTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[pledge_type]"]');
  var $mcuTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[mcu_type]"]');
  var $programTypeField = $newMcuForm.find('select[name="mortgage_collateral_update[program_type]"]');

  $pledgeTypeField.on('change', function(e) {
    $([$mcuTypeDropdown, $programTypeDropdown]).each(function() {resetDropdown(this)});
    enableDropdown($mcuTypeDropdown);
    disableDropdown($programTypeDropdown);
    if ($pledgeTypeField.val() === 'specific') {
      $(['add', 'delete']).each(function() {hideDropdownSelection($mcuTypeDropdown, this)});
      $(['pledge', 'depledge']).each(function() {showDropdownSelection($mcuTypeDropdown, this)});
      $('.mcu-upload-legal-section-specific').show();
      $('.mcu-upload-legal-section-blanket-lien').hide();
    } else if ($pledgeTypeField.val() === 'blanket_lien') {
      $(['pledge', 'depledge']).each(function() {hideDropdownSelection($mcuTypeDropdown, this)});
      $(['add', 'delete']).each(function() {showDropdownSelection($mcuTypeDropdown, this)});
      $('.mcu-upload-legal-section-blanket-lien').show();
      $('.mcu-upload-legal-section-specific').hide();
    };
  });

  $mcuTypeField.on('change', function(e) {
    enableDropdown($programTypeDropdown);
    resetDropdown($programTypeDropdown);
  });

  function hideDropdownSelection($dropdown, selection) {
    $dropdown.find('option[value=' + selection + ']').hide();
    $dropdown.find('li[data-dropdown-value=' + selection + ']').hide();
  };

  function showDropdownSelection($dropdown, selection) {
    $dropdown.find('option[value=' + selection + ']').show();
    $dropdown.find('li[data-dropdown-value=' + selection + ']').show();
  };

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
});