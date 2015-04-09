(function( $ ) {
  $.fn.quickAdvanceTable = function(){
    var $table = this;
    var $initiateButton = $(".dashboard-quick-advance-flyout .initiate-quick-advance");
    var $amountField = $('.dashboard-quick-advance-flyout input[name=amount]');
    var selected_rate = {};

    var $flyoutTableCells = $('.dashboard-quick-advance-flyout td.selectable-cell');
    $flyoutTableCells.on('click', function(){
      var $this = $(this);
      if (!$this.hasClass('disabled-cell')) {
        $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected cell-hovered');
        var col = getColumnIndex($this);
        $this.addClass('cell-selected').closest('tr').find('td.row-label').addClass('cell-selected');
        $($table.find('tr.quick-advance-column-labels th')[col]).addClass('cell-selected');
        setRateFromElementData($this);
        $initiateButton.hasClass('active') ? '' : $initiateButton.addClass('active');
      };
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
        initiateQuickAdvance(selected_rate);
      };
    });

    function getColumnIndex($cell) {
      if ($cell.closest('tr').hasClass('quick-advance-table-label-row')) {
        return $cell.index() - 1;
      } else {
        return $cell.index();
      }
    };

    function initiateQuickAdvance(rate_data) {
      $.post('/dashboard/quick_advance_preview', packageParameters(rate_data), function(htmlResponse){
        var $flyoutBottomSection = $('.flyout-bottom-section');
        var $oldNodes = $('.flyout-top-section-body span, .flyout-bottom-section table, .flyout-bottom-section .initiate-quick-advance');

        // append the html response, hide old nodes and show the new ones
        $flyoutBottomSection.append($(htmlResponse));
        $oldNodes.hide();
        $('.flyout-top-section-body .quick-advance-preview-subheading').show();

        // event listener and handler for back button click
        $('.quick-advance-back-button').on('click', function() {
          $('.quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
          $oldNodes.show();
        });

        // event listener and handler for .confirm-quick-advance button click
        $('.confirm-quick-advance').on('click', function(){
          confirmQuickAdvance(selected_rate); //
        });
      });
    };

    function confirmQuickAdvance(rate_data) {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvancePreview = $flyoutBottomSection.find('.quick-advance-preview');
      $quickAdvancePreview.addClass('loading');
      var height = $flyoutBottomSection.find('.quick-advance-body p:not(.quick-advance-loading-message)').height();
      $flyoutBottomSection.find('.quick-advance-loading-message').height(height);
      $flyoutBottomSection.find('button').attr('disabled', 'disabled');
      $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
      $flyoutTopSection.find('.quick-advance-confirmation-subheading').show();
      setTimeout(function() {
        $.post('/dashboard/quick_advance_confirmation', packageParameters(rate_data), function(htmlResponse){
          $quickAdvancePreview.hide();
          $flyoutBottomSection.append($(htmlResponse));
          $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
          $flyoutTopSection.find('.quick-advance-confirmation-subheading').show();
        });
      }, 3000);
    };

    function setRateFromElementData($element) {
      selected_rate['advance_term'] = $element.data('advance-term');
      selected_rate['advance_type'] = $element.data('advance-type');
      selected_rate['advance_rate'] = $element.data('advance-rate');
    };

    function packageParameters(rate_data) {
      return $.extend({amount: $amountField.val()}, rate_data)
    }

  };
}( jQuery ));