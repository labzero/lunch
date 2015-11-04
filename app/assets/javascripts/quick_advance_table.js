(function( $ ) {
  $.fn.quickAdvanceTable = function(){
    var $table = this;
    var $initiateButton = $(".dashboard-quick-advance-flyout .initiate-quick-advance");
    var $amountField = $('.dashboard-quick-advance-flyout input[name=amount]');
    var $flyout = $('.dashboard-quick-advance-flyout');
    var selected_rate = {};
    var $catchAllError = $flyout.find('.quick-advance-error').remove().show();
    var $flyoutBottomSection = $('.flyout-bottom-section');

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

    function showQuickAdvancePreviewError() {
      $('.flyout-top-section-body .quick-advance-preview-subheading').show();

      // event listener and handler for back button click
      $('.quick-advance-back-button').on('click', function () {
        $('.quick-advance-preview, .quick-advance-back-button, .confirm-quick-advance').remove();
        $('.quick-advance-preview-subheading').hide();
        $flyout.find('.flyout-top-section-body span, .quick-advance-limited-pricing-message, .quick-advance-instruction, .quick-advance-rates, .flyout-bottom-section .initiate-quick-advance, .flyout-bottom-section .rate-advances-footer').show();
        transitionToRatesFromLoading();
      });
    }

    function initiateQuickAdvance(rate_data) {
      transitionToLoadingFromRates();
      $.post('/dashboard/quick_advance_preview', packageParameters(rate_data), function(json){
        var $oldNodes = $flyout.find('.flyout-top-section-body span, .quick-advance-limited-pricing-message, .quick-advance-instruction, .quick-advance-rates, .flyout-bottom-section .initiate-quick-advance, .flyout-bottom-section .rate-advances-footer');

        // append the html response, hide old nodes and show the new ones
        $flyoutBottomSection.append($(json.html));
        $oldNodes.hide();
        if (json.preview_error == true) {
          showQuickAdvancePreviewError();
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
            setRsaEventListener();
            setConfirmQuickAdvanceListener();
          }
          else {
            $flyout.find('.flyout-top-section-body .quick-advance-capstock-subheading').show();

            // event listener and handler for back button click
            $('.quick-advance-capstock-back-button').on('click', function () {
              $('.quick-advance-capstock, .quick-advance-capstock-back-button, .confirm-quick-advance-capstock').remove();
              $('.quick-advance-capstock-subheading').hide();
              $oldNodes.show();
              transitionToRatesFromLoading();
            });

            // event listener and handler for .confirm-quick-advance button click
            $('.confirm-quick-advance-capstock').on('click', function () {
              initiateQuickAdvanceWithoutCapstockCheck({stock_choice: $flyout.find('input[name=stock_choice]:checked').val()});
            });
          }
        }

      }).error(showCatchAllError);
    };

    function initiateQuickAdvanceWithoutCapstockCheck(params) {
      var $flyoutBottomSection = $('.flyout-bottom-section');
      transitionToLoadingFromCapstock();
      $.post('/dashboard/quick_advance_preview', params, function(json){
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
          $oldNodes.show();
          $('.flyout-top-section-body .quick-advance-capstock-subheading').show();
          transitionToCapstockFromLoading();
        });
        setRsaEventListener();
        setConfirmQuickAdvanceListener();     
      }).error(showCatchAllError);
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
          $flyoutBottomSection.append($(json.html));
          if (json.advance_success) {
            $quickAdvancePreview.hide();
            $flyoutTopSection.find('.quick-advance-preview-subheading').hide();
            $flyoutTopSection.find('.quick-advance-confirmation-subheading').show();
          } else {
            $('.quick-advance-preview.loading').remove();
            $('.quick-advance-confirmation-subheading').hide();
            showQuickAdvancePreviewError();
          }
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
      }).error(showCatchAllError);
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
      $flyoutBottomSection.find('button, input').attr('disabled', 'disabled');
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
      $flyoutBottomSection.find('input[type=radio]').removeAttr('disabled');
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
    };

    function packageParameters(rate_data) {
      return $.extend(rate_data, {amount: $amountField.val()});
    };

    function setRsaEventListener() {
      var $initiateButton = $('.confirm-quick-advance');
      var $secureIDTokenField = $('#securid_token');
      var $secureIDPinField = $('#securid_pin');
      if ($secureIDPinField.length && $secureIDTokenField.length) {
        $.each([$secureIDPinField, $secureIDTokenField], (function(i, $element){
          $element.on('keyup', function(){
            if ($secureIDTokenField.val().length == 6 && $secureIDPinField.val().length == 4) {
              $initiateButton.addClass('active');
            } else {
              $initiateButton.removeClass('active');
            };
          });
        }));
      };
    };
    
    function setConfirmQuickAdvanceListener() {
      var $flyoutBottomSection = $('.flyout-bottom-section');
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
          performQuickAdvance(authentication_details);
        }
      });
    };

    function showCatchAllError () {
      $flyoutBottomSection.children().hide();
      $flyoutBottomSection.append($catchAllError.clone());
      $catchAllError.find('.quick-advance-error-button').removeAttr('disabled');
    };

  };
}( jQuery ));