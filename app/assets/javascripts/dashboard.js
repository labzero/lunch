$(function () {
  var $quickAdvancesInputField = $('.dashboard-module-advances input');

  $quickAdvancesInputField.on('keypress', function(e){
    onlyAllowDigits(e);
  });

  function onlyAllowDigits(e) {
    var allowedKeycodes = [8, 13, 16, 17, 18, 19, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 45]; // see http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes for mapping
    var keycode = e.which;

    // allow digits
    for (i = 48; i < 58; i++) {
      allowedKeycodes.push(i);
    };
    if (!(allowedKeycodes.indexOf(keycode)>=0)) {
      e.preventDefault();
    };
  };

  $quickAdvancesInputField.on('input', function(event){
    addCommasToInputField(event);
    openQuickAdvanceFlyout(event, $(this));
  });
  
  $('.quick-advance-limited-pricing-notice').on('click', function(event){
    openQuickAdvanceFlyout(event, $quickAdvancesInputField);
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    var $flyoutInput = $('.flyout-top-section input');
    if ($flyoutInput.length > 0) {
      $flyoutInput.focus();
      $flyoutInput[0].setSelectionRange(1, 1);
    }
  }).on('flyout-reset-initiated', function(){
    $quickAdvancesInputField.val('').data('flyout-trigger', 'active');
    $('.quick-advance-desk-closed-message a').data('flyout-trigger', 'active');
  });

  function openQuickAdvanceFlyout(event, $element) {
    event.stopPropagation();
    event.preventDefault();
    if ($element.data('flyout-trigger') == 'active') {
      $element.data('flyout-trigger', 'inactive');
      $('.flyout').addClass('dashboard-quick-advance-flyout');
      $('.flyout-bottom-section').addClass('column-3-span-2');
      var topContent = [$('.dashboard-module-advances header').clone(), $('<div class="flyout-top-section-body"></div>').append($('.dashboard-module-advances .input-field-container, .dashboard-module-advances h2, .quick-advance-desk-closed-message').clone())];
      var bottomContent = $('.quick-advance-rates, .quick-advance-last-updated-message, .quick-advance-limited-pricing-message, .quick-advance-instruction, .dashboard-module-advances .initiate-quick-advance, .rate-advances-footer, .quick-advance-error').clone();
      $('.dashboard-module-advances').flyout({topContent:topContent, bottomContent:bottomContent, useReferenceElement:true});
      var $amountField = $('.dashboard-quick-advance-flyout input[name=amount]');
      $amountField.on('keypress', function(e){
        onlyAllowDigits(e);
      });
      $amountField.on('keyup', function(e){
        addCommasToInputField(e);
      });
      getQuickAdvanceRates();
    };
  };

  function addCommasToInputField(e) {
    var rememberPositionKeycodes = [8,37,38,39,40];
    var target = e.target;
    var position = target.selectionStart;
    var currentVal = $(target).val();
    var newVal = currentVal.replace(/\D/g,'').replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");
    if (currentVal !== newVal) {
      $(target).val(newVal);
      if (rememberPositionKeycodes.indexOf(e.which) >= 0) {
        target.selectionEnd = position;
      };
    };
  };

  function getQuickAdvanceRates() {
    $.get('/dashboard/quick_advance_rates', function(data) {
      showQuickAdvanceRates(data);
    })
  };

  function showQuickAdvanceRates(data) {
    var table = $('.dashboard-quick-advance-flyout table');
    var tbody = table.find('tbody');
    tbody.children().remove();
    tbody.append($(data.html));
    table.quickAdvanceTable(data.id);
  };

  function showQuickAdvanceClosedState() {
    $('.primary-button.initiate-quick-advance, .rate-advances-footer, .dashboard-module-advances .input-field-container, .flyout .input-field-container').remove();
    $('.quick-advance-desk-closed-message').show();
    $('.quick-advance-last-updated-message').addClass('show-message');
    $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected');
    $('.dashboard-quick-advance-flyout .selectable-cell').addClass('disabled-cell');
  };

  if ($('.dashboard-module-advances').length > 0) {
    var isCheckingRate = false;
    var $rate_element = $('.dashboard-advances-rate');
    var $rate_element_children = $rate_element.children();
    setInterval(function() {
      if (!isCheckingRate) {
        isCheckingRate = true;
        $.get('/dashboard/current_overnight_vrc').done(function(data) {
          $rate_element.html(data.rate).append($rate_element_children);
          if (!data.quick_advances_active) {
            showQuickAdvanceClosedState();
          }
        }).always(function() {
          isCheckingRate = false;
        });
      };
    }, 30000);
  };

});