$(function () {

  $('.dashboard-module-advances input').on('input', function(event){
    var $this = $(this);
    if ($this.data('flyout-trigger') == 'active') {
      $this.data('flyout-trigger', 'inactive');
      $('.flyout').addClass('dashboard-quick-advance-flyout');
      var topContent = [$('.dashboard-module-advances header').clone(), $('<div class="flyout-top-section-body"></div>').append($('.dashboard-module-advances .input-field-container').clone())];
      $('.dashboard-module-advances').flyout(topContent);
    }
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    $('.flyout-top-section input').focus();
    $('.flyout-top-section input')[0].setSelectionRange(1, 1);
  }).on('flyout-reset-initiated', function(){
    $('.dashboard-module-advances input').val('').data('flyout-trigger', 'active');
  });

});