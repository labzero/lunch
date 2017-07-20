$(function () {
  var $formPreview = $('.add-advance-form');
  var $rateTable = $('.advance-rates-table');
  var $rateCustomTable = $('.advance-rates-custom-table');
  var addAdvanceRatesPromise;
  var addAdvanceCustomRatesPromise;
  var $amountField = $('input[name="advance_request[amount]"]');
  var $typeField = $('input[name="advance_request[type]"]');
  var $termField = $('input[name="advance_request[term]"]');
  var $idField = $('input[name="advance_request[id]"]');
  var $submitFieldPreview = $formPreview.find('input[type=submit]');
  var $alternateFundingWrapper = $('.advance-alternate-funding-date-wrapper');

  $amountField.on('keypress', function(e){
    Fhlb.Utils.onlyAllowDigits(e);
  });
  $amountField.on('keyup', function(e){
    Fhlb.Utils.addCommasToInputField(e);
    validateForm();
  });

  function showAddAdvanceLoadingState() {
    $('.add-advance-loading-overlay').fadeIn();
    $('.add-advance-action-message').show();
    $('.add-advance-instructions').hide();
  };

  function showRatesLoadingState(table) {
    table.addClass('add-advance-table-loading');
  };

  function validateForm() {
    if($amountField.val() && $('.add-advance-rate-cell.cell-selected').length > 0) {
      $submitFieldPreview.attr('disabled', false).addClass('active');
    } else {
      $submitFieldPreview.attr('disabled', true);
    };
  };

  function showTableErrorState($table) {
    $table.removeClass('add-advance-table-loading');
    $table.addClass('add-advance-table-error');
  }

  function getAdvanceRates(funding_date, maturity_date) {
    if (!addAdvanceRatesPromise) {
      var fetchRatesUrl = $rateTable.data('fetch-rates-url');
      addAdvanceRatesPromise = $.get(fetchRatesUrl, {funding_date: funding_date, maturity_date: maturity_date});
      addAdvanceRatesPromise.error(function() {
        showTableErrorState($rateTable);
      }).always(function() {
        addAdvanceRatesPromise = false;
      });
    };
    return addAdvanceRatesPromise;
  };

  function getCustomAdvanceRates(funding_date, maturity_date) {
    if (!addAdvanceCustomRatesPromise) {
      var fetchRatesUrl = $rateCustomTable.data('fetch-custom-rates-url');
      addAdvanceCustomRatesPromise = $.get(fetchRatesUrl, {funding_date: funding_date, maturity_date: maturity_date});
      addAdvanceCustomRatesPromise.error(function() {
        showTableErrorState($rateCustomTable);
      }).always(function() {
        addAdvanceCustomRatesPromise = false;
      });
    };
    return addAdvanceCustomRatesPromise;
  };

  function showAdvanceRates(funding_date, maturity_date) {
    if (maturity_date) {
      getCustomAdvanceRates(funding_date, maturity_date).success(function (data) {
        $rateCustomTable.children().remove();
        $rateCustomTable.append($(data.html));
        bindApplyHandler();
        bindRateTableCells($rateCustomTable);
        $idField.val(data.id);
        selectColumnLabelIfRatePreSelected($rateCustomTable);
        $rateCustomTable.removeClass('add-advance-table-loading');
        var $calendarEle = $formPreview.find('.advance-custom-date-maturity-calendar-partial');
        $('.add-advance-form').find('.datepicker-trigger').find('input').val(moment(maturity_date).format('L'));
        $calendarEle.trigger('datepicker-rebind');
      });
    }
    getAdvanceRates(funding_date, maturity_date).success(function (data) {
      var tbody = $rateTable.find('tbody');
      tbody.children().remove();
      tbody.append($(data.html));
      if ((data.alternate_funding_date_html) && (!maturity_date)) {
        var $fundingDateWrapper = $formPreview.find('.advance-funding-date-wrapper');
        var isVisible = $fundingDateWrapper.is(':visible');
        var $newFundingDateWrapper = $(data.alternate_funding_date_html);
        $fundingDateWrapper.replaceWith($newFundingDateWrapper);
        if (isVisible) {
          $newFundingDateWrapper.show();
        }
      }
      $('.advance-alternate-funding-date-close').attr('disabled', false);
      bindApplyHandler();
      bindRateTableCells($rateTable);
      maturity_date ? null : $idField.val(data.id);
      Fhlb.Track.advance_rate_table();
      selectColumnLabelIfRatePreSelected($rateTable);
      enableCustomFunding($rateTable);
      validateForm();
      $rateTable.removeClass('add-advance-table-loading');
    });
  };

  function bindRateTableCells(table) {
    var $rateTableCells = table.find('td.selectable-cell');
    $rateTableCells.on('click', function(){
      var $this = $(this);
      if (!$this.hasClass('disabled-cell')) {
        $('.advance-rates-table td, .advance-rates-table th').removeClass('cell-selected cell-hovered');
        $('.advance-rates-custom-table td, .advance-rates-custom-table th').removeClass('cell-selected cell-hovered');
        $this.addClass('cell-selected').closest('tr').find('td.row-label').addClass('cell-selected');
        $($rateTable.find('tr.add-advance-column-labels th')[$this.index()]).addClass('cell-selected');
      };
      validateForm();
    });

    // Hover behavior
    $rateTableCells.hover( function(){
      var $this = $(this);
      if (!$this.hasClass('cell-selected') && $this.hasClass('selectable-cell')) {
        $this.toggleClass('cell-hovered').closest('tr').find('td.row-label').toggleClass('cell-hovered');
        $($rateTable.find('tr.add-advance-column-labels th')[$this.index()]).toggleClass('cell-hovered');
      };
    });
  };

  function enableCustomFunding(table) {
    if (table.find('tr.frc-rates').find('.disabled-cell').length) {
      $('.advance-alternate-funding-date-edit').attr('disabled', true);
      $('.advance-custom-date-add').attr('disabled', true);
    }
    else {
      $('.advance-alternate-funding-date-edit').attr('disabled', false);
      $('.advance-custom-date-add').attr('disabled', false);
    };
  };

  function selectColumnLabelIfRatePreSelected(table) {
    var $selectedCell = table.find('td.cell-selected.selectable-cell');
    if ($selectedCell.length && !table.hasClass('add-advance-table-loading')) {
      var col = $selectedCell.index();
      $($rateTable.find('tr.add-advance-column-labels th')[col]).addClass('cell-selected');
    };
  };

  function removeColumnLabelIfRatePreSelected(table) {
    var $selectedCell = table.find('td.cell-selected.selectable-cell');
    if ($selectedCell.length) {
      var col = $selectedCell.index();
      $($rateTable.find('tr.add-advance-column-labels th')[col]).removeClass('cell-selected');
    };
  };

  function setRateFromElementData($element) {
    $typeField.val($element.data('advance-type'));
    $termField.val($element.data('advance-term'));
  };

  $formPreview.on('submit', function(){
    var $selectedCell = $($rateTable.find('.cell-selected.add-advance-rate-cell'));
    if ($selectedCell.length > 0) {
      setRateFromElementData($selectedCell);
    }
    else {
      $selectedCell = $($rateCustomTable.find('.cell-selected.add-advance-rate-cell'));
      setRateFromElementData($selectedCell);
    }
    showAddAdvanceLoadingState();
    $submitFieldPreview.attr('disabled', true); // Backup to prevent resubmission, as page is already covered by overlay and inaccessible.
  });

  // Get rates only when there is a rate table
  if ($rateTable.length > 0) {
    setTimeout(function() {showAdvanceRates(getFundingDate(), getMaturityDate());}, 1);
  };

  // Perform Advance
  var $formPerform = $('.perform-advance-form');
  var $submitFieldPerform = $formPerform.find('input[type=submit]');
  var $secureIDTokenField = $('#securid_token');
  var $secureIDPinField = $('#securid_pin');

  // Validate length of SecurID token and pin
  if ($secureIDPinField.length && $secureIDTokenField.length) {
    $.each([$secureIDPinField, $secureIDTokenField], (function(i, $element){
      $element.on('keyup', function(){
        if ($secureIDTokenField.val().length == 6 && $secureIDPinField.val().length == 4) {
          $submitFieldPerform.addClass('active');
          $submitFieldPerform.attr('disabled', false);
        } else {
          $submitFieldPerform.removeClass('active');
          $submitFieldPerform.attr('disabled', true);
        };
      });
    }));
  };

  if ($formPerform.length > 0) {
    Fhlb.Utils.findAndDisplaySecurIDErrors($formPerform);
  };

  $formPerform.on('submit', function(e) {
    if ($secureIDTokenField.length > 0 && $secureIDPinField.length > 0 && !Fhlb.Utils.validateSecurID($(this))) {
      return false
    } else {
      showAddAdvanceLoadingState();
    };
  });

  // Rate Table Toggle Behavior
  var $rateTableWrapper = $('.advance-rates-table-wrapper');
  $('.advance-rates-table-toggle span').on('click', function(e) {
    var selectedTermType = $(this).data('active-term-type');
    $('.advance-alternate-funding-date-wrapper').hide();
    $('.advance-create-custom-date-wrapper').hide();
    if (selectedTermType == 'frc') {
      $('.advance-funding-date-wrapper').show();
      $('.advance-custom-date-wrapper').show();
    }
    else {
      $('.advance-funding-date-wrapper').hide();
      $('.advance-custom-date-wrapper').hide();
      $('.advance-create-custom-date-wrapper').hide();
      $('.advance-select-custom-date-wrapper').hide();
    }

    if ($rateTableWrapper.attr('data-active-term-type') !== selectedTermType) {
      $rateTableWrapper.attr('data-active-term-type', selectedTermType);
      $rateTable.find('td, th').removeClass('cell-selected');
      $rateCustomTable.find('td, th').removeClass('cell-selected');
      validateForm();
    };
  });

  // Close Default Funding Date Selector
  $('.advance-alternate-funding-date-close').on('click', function(e) {
    $('.advance-alternate-funding-date-wrapper').hide();
    $('.advance-funding-date-wrapper').show();
    e.stopPropagation();
    e.preventDefault();
  });

  // Open Custom Date Selector
  $('.advance-custom-date-add').on('click', function(e) {
    $('.advance-custom-date-wrapper').hide();
    $('.advance-select-custom-date-wrapper').hide();
    $('.advance-create-custom-date-wrapper').show();
    $('.add-advance-form').find('.datepicker-trigger').find('input').attr('disabled', false);
    e.stopPropagation();
    e.preventDefault();
  });

  // Cancel Custom Date Selector
  $('.advance-custom-date-cancel').on('click', function(e) {
    if ($rateCustomTable.hasClass('add-advance-table-loading')) {
      $('.advance-custom-date-wrapper').show();
      $('.advance-create-custom-date-wrapper').hide();
      $('.advance-select-custom-date-wrapper').hide();
    }
    else {
      $('.advance-custom-date-wrapper').hide();
      $('.advance-create-custom-date-wrapper').hide();
      $('.advance-select-custom-date-wrapper').show();
    };
    e.stopPropagation();
    e.preventDefault();
  });


  //event listener and handler for .btn-success button click
  function bindApplyHandler() {
    $formPreview.find('.datepicker-trigger').on('apply.daterangepicker', function() {
      toggleViewCustomRates();
    });

    // Edit Custom Date Selector
    $('.advance-custom-date-edit').on('click', function(e) {
      $('.advance-custom-date-wrapper').hide();
      $('.advance-select-custom-date-wrapper').hide();
      $('.advance-create-custom-date-wrapper').show();
      e.stopPropagation();
      e.preventDefault();
    });

    // Open Alternate Funding Date Selector
    $('.advance-alternate-funding-date-edit').on('click', function(e) {
      $('.advance-alternate-funding-date-wrapper').show();
      $('.advance-funding-date-wrapper').hide();
      e.stopPropagation();
      e.preventDefault();
    });
  }
  bindApplyHandler();

  function getMaturityDate() {
    var $datePickerTrigger = $($formPreview.find('.datepicker-trigger'));
    var maturityDate = $datePickerTrigger.find('input').val();
    if ((maturityDate != null) && (maturityDate != '') && (moment(maturityDate).startOf('day') > moment().startOf('day'))) {
      maturityDate = moment(maturityDate).format('YYYY-MM-DD');
    }
    return maturityDate;
  }

  function getFundingDate() {
    return $alternateFundingWrapper.find('input[name=alternate-funding-date]:checked').val();
  }

  // event listener and handler for alternate funding date button click
  $('input[name=alternate-funding-date]').on('click', function () {
    var funding_date = $alternateFundingWrapper.find('input[name=alternate-funding-date]:checked').val();
    $('.advance-custom-date-wrapper').show();
    $('.advance-create-custom-date-wrapper').hide();
    $('.advance-select-custom-date-wrapper').hide();
    $('.advance-alternate-funding-date-close').attr('disabled', true);
    removeColumnLabelIfRatePreSelected($rateTable);
    removeColumnLabelIfRatePreSelected($rateCustomTable);
    showRatesLoadingState($rateTable);
    showAdvanceRates(funding_date, getMaturityDate());
  });

  // event listener and handler for custom date button click
  $('.view-custom-rates').on('click', function (e) {
    $('.advance-custom-date-wrapper').hide();
    $('.advance-create-custom-date-wrapper').hide();
    $('.advance-select-custom-date-wrapper').show();
    var $viewCustomRates = $('.view-custom-rates');
    $viewCustomRates.removeClass('active');
    $viewCustomRates.attr('disabled', true);
    showRatesLoadingState($rateTable);
    showRatesLoadingState($rateCustomTable);
    showAdvanceRates(getFundingDate(), getMaturityDate());
    e.stopPropagation();
    e.preventDefault();
  });

  // event listener and handler for maturity date input keystrokes
  $('.datepicker-trigger').on('keyup', function (e) {
    var $datePickerTrigger = $($formPreview.find('.datepicker-trigger'));
    var maturityDateInput = $datePickerTrigger.find('input').val();
    if (moment(maturityDateInput, "M/D/YYYY", true).isValid() ||
        moment(maturityDateInput, "M/D/YY", true).isValid() ) {
       toggleViewCustomRates();
    }
  });

  function toggleViewCustomRates() {
    var $viewCustomRates = $('.view-custom-rates');
    var fundingDate = new Date(getFundingDate());
    var maturityDate = new Date(getMaturityDate());
    var diffDays = (maturityDate - fundingDate)/(1000 * 3600 * 24);
    if (diffDays >=1) {
        $viewCustomRates.addClass('active');
        $viewCustomRates.attr('disabled', false);
    }
    else {
        $viewCustomRates.removeClass('active');
        $viewCustomRates.attr('disabled', true);
    }
  }

  // Google Analytics -
  $('.add-advance-preview').length ? Fhlb.Track.advance_preview() : null;
  $('.add-advance-capstock').length ? Fhlb.Track.stock_purchase() : null;
  $('.add-advance-confirmation').length ? Fhlb.Track.advance_success() : null;
  $('.add-advance-error').length ? Fhlb.Track.advance_error() : null;
});