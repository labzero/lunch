$(function () {

  $('.dashboard-module-advances input').on('input', function(event){
    var $this = $(this);
    if ($this.hasClass('flyout-trigger')) {
      $this.removeClass('flyout-trigger');
      $('.flyout').addClass('dashboard-quick-advance-flyout');
      var topContent = $('.dashboard-module-advances header, .dashboard-module-advances .input-field-container').clone();
      $('.dashboard-module-advances').flyout(topContent, bottomContent);
    }
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    $('.flyout-top-section input').focus();
    $('.flyout-top-section input')[0].setSelectionRange(1, 1);
  }).on('flyout-reset-initiated', function(){
    $('.dashboard-module-advances input').val('').addClass('flyout-trigger');
  });

});