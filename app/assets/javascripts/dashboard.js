$(function () {

  $('.dashboard-module-advances input').on('input', function(event){
    var $this = $(this);
    if ($this.data('flyout-trigger') == 'active') {
      $this.data('flyout-trigger', 'inactive');
      $('.flyout').addClass('dashboard-quick-advance-flyout');
      $('.flyout-bottom-section').addClass('column-3-span-2');
      var topContent = [$('.dashboard-module-advances header').clone(), $('<div class="flyout-top-section-body"></div>').append($('.dashboard-module-advances .input-field-container').clone())];
      var bottomContent = $('.dashboard-module-advances table, .dashboard-module-advances .initiate-quick-advance').clone();
      $('.dashboard-module-advances').flyout(topContent, bottomContent);
      getQuickAdvanceRates();
    }
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    $('.flyout-top-section input').focus();
    $('.flyout-top-section input')[0].setSelectionRange(1, 1);
  }).on('flyout-reset-initiated', function(){
    $('.dashboard-module-advances input').val('').data('flyout-trigger', 'active');
  });

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

  if (('.dashboard-module-advances').length > 0) {
    var isCheckingRate = false;
    var $rate_element = $('.dashboard-advances-rate');
    var $rate_element_children = $rate_element.children();
    setInterval(function() {
      if (!isCheckingRate) {
        isCheckingRate = true;
        $.get('/dashboard/current_overnight_vrc').done(function(data) {
          $rate_element.html(data.rate).append($rate_element_children);
        }).always(function() {
          isCheckingRate = false;
        });
      };
    }, 30000);
  };

});