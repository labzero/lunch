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
      setRateFromElementData($this);
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
    };

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
          setRateFromElementData($(this));
          confirmQuickAdvance(JSON.stringify(selected_rate)); //
        });
      });
    };

    function confirmQuickAdvance(rate_data) {
      $.post('/dashboard/quick_advance_confirmation', {rate_data: rate_data}, function(jsonResponse){
        // we're going to render a partial here once we get the designs for this confirmation
        // in the meantime, just replacing some nodes in .quick-advance-preview to display confirmation number and allow flyout close
        $('.quick-advance-preview').addClass('quick-advance-confirmation');
        $('.quick-advance-preview-message, .quick-advance-back-button, .confirm-quick-advance').remove();
        $('.quick-advance-summary')
          .prepend("<p>Advance Number: <span>" + jsonResponse['confirmation_number'] +"</span></p>");
        $('.flyout-bottom-section')
          .append('<button class = "primary-button quick-advance-confirmation-button">Close</button>');
        $('.quick-advance-confirmation-button').on('click', function(){
          $('.flyout-close-button').click(); // again, definitely not how we want to handle this, but waiting until designs are finalized to build out
        });
      });
    };

    function setRateFromElementData($element) {
      selected_rate['advance_term'] = $element.data('advance-term');
      selected_rate['advance_type'] = $element.data('advance-type');
      selected_rate['advance_rate'] = $element.data('advance-rate');
    };

  };
}( jQuery ));