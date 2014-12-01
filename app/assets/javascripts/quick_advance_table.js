(function( $ ) {
  $.fn.quickAdvanceTable = function(){
    var $table = this;
    var $initiateButton = $(".dashboard-quick-advance-flyout .initiate-quick-advance");
    var selected_rate = {};

    var $flyoutTableCells = $('.dashboard-quick-advance-flyout td.selectable-cell');
    $flyoutTableCells.on('click', function(){
      var $this = $(this);
      $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected cell-hovered');
      var col = getColumnIndex($this);
      $this.addClass('cell-selected').closest('tr').find('td.row-label').addClass('cell-selected');
      $($table.find('tr.quick-advance-column-labels th')[col]).addClass('cell-selected');
      selected_rate['advance_term'] = $this.data('advance-term');
      selected_rate['advance_type'] = $this.data('advance-type');
      selected_rate['advance_rate'] = parseFloat($this.text());
      $initiateButton.hasClass('active') ? '' : $initiateButton.addClass('active');
    });

    $flyoutTableCells.hover( function(){
      var $this = $(this);
      var col = getColumnIndex($this);
      if (!$this.hasClass('cell-selected') && $this.hasClass('selectable-cell')) {
        $this.toggleClass('cell-hovered').closest('tr').find('td.row-label').toggleClass('cell-hovered');
        $($table.find('tr.quick-advance-column-labels th')[col]).toggleClass('cell-hovered');
      }
    });

    // quick advance trigger
    $initiateButton.on('click', function(){
      if ($initiateButton.hasClass('active') && !$.isEmptyObject(selected_rate)) {
        initiateQuickAdvance(JSON.stringify(selected_rate));
      };
    });

    function getColumnIndex($cell) {
      if ($cell.closest('tr').hasClass('quick-advance-table-label-row')) {
        return $cell.index() - 1;
      } else {
        return $cell.index();
      }
    }

    function initiateQuickAdvance(rate_data) {
      $.post('/dashboard/quick_advance_preview', {rate_data: rate_data}, function(htmlResponse){
        var $flyoutBottomSection = $('.flyout-bottom-section');
        var $oldNodes = $('.flyout-top-section-body span, .flyout-bottom-section table, .flyout-bottom-section .initiate-quick-advance');

        // append the html response, hide old nodes and show the new ones
        $flyoutBottomSection.append($(htmlResponse));
        $oldNodes.hide();
        $('.flyout-top-section-body').append($flyoutBottomSection.find('.quick-advance-preview-subheading')); // this part of the html response must get appended to top-section

        // event listener and handler for back button click
        $('.quick-advance-back-button').on('click', function() {
          $('.quick-advance-preview-subheading, .quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
          $oldNodes.show();
        });

        // event listener and handler for .confirm-quick-advance button click
        $('.confirm-quick-advance').on('click', function(){
          // TODO add ajax POST to route that will execute the advance
        });
      });
    };

  };
}( jQuery ));