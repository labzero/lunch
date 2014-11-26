(function( $ ) {
  $.fn.quickAdvanceTable = function(){
    var $table = this;
    var $initiateButton = $(".dashboard-quick-advance-flyout .initiate-quick-advance");
    var selected_rate = {};

    var $flyoutTableCells = $('.dashboard-quick-advance-flyout td');
    $flyoutTableCells.on('click', function(){
      var $this = $(this);
      $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected cell-hovered');
      var col = $(this).index();
      $this.addClass('cell-selected').closest('tr').find('td:first-child').addClass('cell-selected');
      $($table.find('th')[col]).addClass('cell-selected');
      selected_rate['advance_term'] = $this.data('advance-term');
      selected_rate['advance_type'] = $this.data('advance-type');
      selected_rate['advance_rate'] = parseFloat($this.text());
      $initiateButton.hasClass('active') ? '' : $initiateButton.addClass('active');
    });

    $flyoutTableCells.hover( function(){
      var $this = $(this);
      var col = $this.index();
      if (!$this.hasClass('cell-selected') && col != 0) {
        $this.toggleClass('cell-hovered').closest('tr').find('td:first-child').toggleClass('cell-hovered');
        $($table.find('th')[col]).toggleClass('cell-hovered');
      }
    });

    // quick advance trigger
    $initiateButton.on('click', function(){
      if ($initiateButton.hasClass('active') && !$.isEmptyObject(selected_rate)) {
        initiateQuickAdvance(JSON.stringify(selected_rate));
      };
    });

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