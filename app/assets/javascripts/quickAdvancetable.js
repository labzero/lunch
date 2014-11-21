(function( $ ) {
  $.fn.quickAdvanceTable = function(){
    var table = this;

    var $flyoutTableCells = $('.dashboard-quick-advance-flyout td');
    $flyoutTableCells.on('click', function(){
      $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected cell-hovered');
      var col = $(this).index();
      $(this).addClass('cell-selected').closest('tr').find('td:first-child').addClass('cell-selected');
      $(table.find('th')[col]).addClass('cell-selected');
    });

    $flyoutTableCells.hover( function(){
      var $this = $(this);
      var col = $this.index();
      if (!$this.hasClass('cell-selected') && col != 0) {
        $this.toggleClass('cell-hovered').closest('tr').find('td:first-child').toggleClass('cell-hovered');
        $(table.find('th')[col]).toggleClass('cell-hovered');
      }
    });
  };
}( jQuery ));