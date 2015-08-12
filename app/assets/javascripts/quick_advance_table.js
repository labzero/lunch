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
        selected_rate['check_capstock'] = true;
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
      var $flyoutBottomSection = $('.flyout-bottom-section');
      transitionToLoadingFromRates();
      $.post('/dashboard/quick_advance_preview', packageParameters(rate_data), function(json){
        var $oldNodes = $('.flyout-top-section-body span, .quick-advance-instruction, .quick-advance-rates, .flyout-bottom-section .initiate-quick-advance, .flyout-bottom-section .rate-advances-footer');

        // append the html response, hide old nodes and show the new ones
        $flyoutBottomSection.append($(json.html));
        $oldNodes.hide();
        if (json.preview_error == true) {
          $('.flyout-top-section-body .quick-advance-preview-subheading').show();

          // event listener and handler for back button click
          $('.quick-advance-back-button').on('click', function () {
            $('.quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
            $('.quick-advance-preview-subheading').hide();
            $oldNodes.show();
            transitionToRatesFromLoading();
          });
        }
        else {
          if (json.preview_success == true) {
            $('.flyout-top-section-body .quick-advance-preview-subheading').show();

            // event listener and handler for back button click
            $('.quick-advance-back-button').on('click', function () {
              $('.quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
              $('.quick-advance-preview-subheading').hide();
              $oldNodes.show();
              transitionToRatesFromLoading();
            });

            // event listener and handler for .confirm-quick-advance button click
            $('.confirm-quick-advance').on('click', function () {
              var $pin = $flyoutBottomSection.find('input[name=securid_pin]');
              var $token = $flyoutBottomSection.find('input[name=securid_token]');
              var pin = $pin.val();
              var token = $token.val();
              if ((!$pin.length && !$token.length) || validateSecurID($flyoutBottomSection)) {
                var authentication_details = {
                  securid_pin: pin,
                  securid_token: token
                };
                performQuickAdvance($.extend(authentication_details, selected_rate));
              }
            });
          }
          else {
            $('.flyout-top-section-body .quick-advance-capstock-subheading').show();

            // event listener and handler for back button click
            $('.quick-advance-capstock-back-button').on('click', function () {
              $('.quick-advance-capstock, .quick-advance-capstock-back-button, .confirm-quick-advance-capstock').remove();
              $('.quick-advance-capstock-subheading').hide();
              selected_rate['amount'] = json.original_amount;
              $oldNodes.show();
              transitionToRatesFromLoading();
            });

            // event listener and handler for .confirm-quick-advance button click
            $('.confirm-quick-advance-capstock').on('click', function () {
              if ($('#continue_transaction').prop('checked') == true) {
                selected_rate['amount'] = json.original_amount;
                selected_rate['stock'] = json.net_stock_required;
              }
              else {
                selected_rate['amount'] = json.gross_amount;
                selected_rate['stock'] = json.gross_net_stock_required;
              }
              selected_rate['check_capstock'] = false;
              initiateQuickAdvanceWithooutCapstockCheck(selected_rate);
            });
          }
        }

      }).error(function() {
        transitionToRatesFromLoading();
      });
    };

    function initiateQuickAdvanceWithooutCapstockCheck(rate_data) {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      transitionToLoadingFromCapstock();
      $.post('/dashboard/quick_advance_preview', packageParameters(rate_data), function(json){
        var $flyoutBottomSection = $('.flyout-bottom-section');
        var $oldNodes = $flyoutBottomSection.find('.quick-advance-capstock, .quick-advance-capstock-back-button, .confirm-quick-advance-capstock');

        // append the html response, hide old nodes and show the new ones
        $oldNodes.hide();
        $('.quick-advance-capstock-subheading').hide();
        $flyoutBottomSection.append($(json.html));

        $('.flyout-top-section-body .quick-advance-preview-subheading').show();

        // event listener and handler for back button click
        $('.quick-advance-back-button').on('click', function() {
          $('.quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
          $('.quick-advance-preview-subheading').hide();
          selected_rate['amount'] = json.original_amount;
          $oldNodes.show();
          $('.flyout-top-section-body .quick-advance-capstock-subheading').show();
          transitionToCapstockFromLoading();
        });

        // event listener and handler for .confirm-quick-advance button click
        $('.confirm-quick-advance').on('click', function() {
          var $pin = $flyoutBottomSection.find('input[name=securid_pin]');
          var $token = $flyoutBottomSection.find('input[name=securid_token]');
          var pin = $pin.val();
          var token = $token.val();
          if ((!$pin.length && !$token.length) || validateSecurID($flyoutBottomSection)) {
            var authentication_details = {
              securid_pin: pin,
              securid_token: token
            };
            performQuickAdvance($.extend(authentication_details, selected_rate));
          }
        });

      }).error(function() {
        transitionToCapstockFromLoading();
        $flyoutBottomSection.find('p[data-error-type=unknown]').show();
      });
    }

    function validateSecurID ($form) {
      var $pin = $form.find('input.securid-field-pin');
      var $token = $form.find('input.securid-field-token');
      var pin = $pin.val();
      var token = $token.val();
      var valid = true;
      $form.find('.input-field-error').removeClass('input-field-error');
      $form.find('p[data-error-type]').hide();
      if (!pin.match(/^\d{4}$/)) {
        valid = false;
        $pin.addClass('input-field-error');
        $form.find('p[data-error-type=invalid_pin]').show();
      }
      if (!token.match(/^\d{6}$/)) {
        valid = false;
        $token.addClass('input-field-error');
        $form.find('p[data-error-type=invalid_token]').show();
      }
      return valid;
    };

    function performQuickAdvance(rate_data) {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvancePreview = $flyoutBottomSection.find('.quick-advance-preview');
      transitionToLoadingFromPreview();
      $.post('/dashboard/quick_advance_perform', packageParameters(rate_data), function(json) {
        if (json.securid == 'authenticated') {
          $quickAdvancePreview.hide();
          $flyoutBottomSection.append($(json.html));
          $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
          $flyoutTopSection.find('.quick-advance-confirmation-subheading').show();
        } else {
          var error = 'unknown';

          $flyoutBottomSection.find('.input-field-error').removeClass('input-field-error');
          transitionToPreviewFromLoading();

          if ($.inArray(json.securid, ['invalid_token', 'invalid_pin', 'denied', 'must_resynchronize', 'must_change_pin']) != -1) {
            error = json.securid;
          }

          $flyoutBottomSection.find('p[data-error-type=' + error + ']').show();

          if (json.securid == 'invalid_pin' || json.securid == 'must_change_pin') {
            $flyoutBottomSection.find('input[name=securid_pin]').addClass('input-field-error');
          } else if (json.securid == 'invalid_token' || json.securid == 'must_resynchronize') {
            $flyoutBottomSection.find('input[name=securid_token]').addClass('input-field-error');
          } else if (json.securid == 'denied') {
            $flyoutBottomSection.find('input[name=securid_pin], input[name=securid_token]').addClass('input-field-error');
          }
        }
      }).error(function() {
        transitionToPreviewFromLoading();
        $flyoutBottomSection.find('p[data-error-type=unknown]').show();
      });
    };

    function transitionToLoadingFromPreview () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvancePreview = $flyoutBottomSection.find('.quick-advance-preview');
      $quickAdvancePreview.addClass('loading');
      var height = $flyoutBottomSection.find('.quick-advance-body p:not(.quick-advance-loading-message)').height();
      $flyoutBottomSection.find('.quick-advance-loading-message').height(height);
      $flyoutBottomSection.find('button').attr('disabled', 'disabled');
      $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
      $flyoutTopSection.find('.quick-advance-confirmation-subheading').show();
    };

    function transitionToPreviewFromLoading () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvancePreview = $flyoutBottomSection.find('.quick-advance-preview');
      $quickAdvancePreview.removeClass('loading');
      $flyoutBottomSection.find('.quick-advance-loading-message').height('auto');
      $flyoutBottomSection.find('button').removeAttr('disabled');
      $flyoutTopSection.find('.quick-advance-preview-subheading').show();
      $flyoutTopSection.find('.quick-advance-confirmation-subheading').hide();
    };

    function transitionToLoadingFromCapstock () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvanceCapstock= $flyoutBottomSection.find('.quick-advance-capstock');
      $quickAdvanceCapstock.addClass('loading');
      var height = $flyoutBottomSection.find('.quick-advance-body p:not(.quick-advance-loading-message)').height();
      $flyoutBottomSection.find('.quick-advance-loading-message').height(height);
      $flyoutBottomSection.find('button').attr('disabled', 'disabled');
      $flyoutTopSection.find('.quick-advance-capstock-subheading').hide();
      $flyoutTopSection.find('.quick-advance-preview-subheading').show();
    };

    function transitionToCapstockFromLoading () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $flyoutTopSection = $('.flyout-top-section-body');
      var $quickAdvanceCapstock= $flyoutBottomSection.find('.quick-advance-capstock');
      $quickAdvanceCapstock.removeClass('loading');
      $flyoutBottomSection.find('.quick-advance-loading-message').height('auto');
      $flyoutBottomSection.find('button').removeAttr('disabled');
      $flyoutTopSection.find('.quick-advance-capstock-subheading').show();
      $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
    };

    function transitionToLoadingFromRates () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $quickAdvanceRates= $flyoutBottomSection.find('.quick-advance-rates');
      $quickAdvanceRates.addClass('loading');
      $flyoutBottomSection.find('button').removeClass('active');
      $flyoutBottomSection.find('button').attr('disabled', 'disabled');
    };

    function transitionToRatesFromLoading () {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      var $quickAdvanceRates= $flyoutBottomSection.find('.quick-advance-rates');
      $quickAdvanceRates.removeClass('loading');
      $flyoutBottomSection.find('button').addClass('active');
      $flyoutBottomSection.find('button').removeAttr('disabled');
    };

    function setRateFromElementData($element) {
      selected_rate['advance_term'] = $element.data('advance-term');
      selected_rate['advance_type'] = $element.data('advance-type');
      selected_rate['advance_rate'] = $element.data('advance-rate');
      selected_rate['maturity_date'] = $element.data('maturity-date');
      selected_rate['payment_on'] = $element.data('payment-on');
      selected_rate['interest_day_count'] = $element.data('interest-day-count');
    };

    function packageParameters(rate_data) {
      return $.extend({amount: $amountField.val()}, rate_data)
    }

  };
}( jQuery ));