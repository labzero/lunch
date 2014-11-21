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
    var advance_types = ["whole_loan", "agency", "aaa", "aa"];
    for (var term in rates) {
      var $row = $("<tr><td>" + term.replace(/_/g, " ") + "</td></tr>");
      advance_types.map(function(advance_type){
        var $cell = $("<td data-term=\"" + term + "\" data-advance-type=\"" + advance_type + "\">" + rates[term][advance_type] + "</td>");
        $row.append($cell);
      });
      table.append($row);
    };
    table.quickAdvanceTable();
  };

});