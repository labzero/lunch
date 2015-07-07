$(function () {

  $('.dashboard-module-advances input').on('input', function(event){
    openQuickAdvanceFlyout(event, $(this));
  });

  $('.quick-advance-desk-closed-message a').on('click', function(event){
    openQuickAdvanceFlyout(event, $(this));
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    var $flyoutInput = $('.flyout-top-section input');
    if ($flyoutInput.length > 0) {
      $flyoutInput.focus();
      $flyoutInput[0].setSelectionRange(1, 1);
    }
  }).on('flyout-reset-initiated', function(){
    $('.dashboard-module-advances input').val('').data('flyout-trigger', 'active');
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
      var bottomContent = $('.quick-advance-last-updated-message, .dashboard-module-advances table, .dashboard-module-advances .initiate-quick-advance, .rate-advances-footer').clone();
      $('.dashboard-module-advances').flyout({topContent:topContent, bottomContent:bottomContent, useReferenceElement:true});
      getQuickAdvanceRates();
    }
  };

  function getQuickAdvanceRates() {
    $.get('/dashboard/quick_advance_rates', function(data) {
      showQuickAdvanceRates(data);
    })
  };

  function showQuickAdvanceRates(rates) {
    var table = $('.dashboard-quick-advance-flyout table');
    table.append($(rates)).quickAdvanceTable();
    $('.dashboard-quick-advance-flyout td.selectable-cell[data-advance-term=\'overnight\'][data-advance-type=\'whole\']').click();
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