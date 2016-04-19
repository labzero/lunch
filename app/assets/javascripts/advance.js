$(function () {
  var $formPreview = $('.add-advance-form');
  var $rateTable = $('.advance-rates-table');
  var addAdvanceRatesPromise;
  var $amountField = $('input[name="advance_request[amount]"]');
  var $typeField = $('input[name="advance_request[type]"]');
  var $termField = $('input[name="advance_request[term]"]');
  var $idField = $('input[name="advance_request[id]"]');
  var $submitFieldPreview = $formPreview.find('input[type=submit]');

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

  function validateForm() {
    if($amountField.val() && $('.add-advance-rate-cell.cell-selected').length > 0) {
      $submitFieldPreview.attr('disabled', false).addClass('active');
    } else {
      $submitFieldPreview.attr('disabled', true);
    };
  };

  function getAdvanceRates() {
    if (!addAdvanceRatesPromise) {
      var fetchRatesUrl = $rateTable.data('fetch-rates-url');
      addAdvanceRatesPromise = $.get(fetchRatesUrl);
      addAdvanceRatesPromise.error(function() {
        addAdvanceRatesPromise = false;
      });
    };
    return addAdvanceRatesPromise;
  };

  function showAdvanceRates() {
    getAdvanceRates().success(function(data) {
      var tbody = $rateTable.find('tbody');
      tbody.children().remove();
      tbody.append($(data.html));
      bindRateTableCells();
      $idField.val(data.id);
      Fhlb.Track.quick_advance_rate_table();
      addAdvanceRatesPromise = false;
      selectColumnLabelIfRatePreSelected();
      validateForm();
    });
  };

  function bindRateTableCells() {
    var $rateTableCells = $rateTable.find('td.selectable-cell');
    $rateTableCells.on('click', function(){
      var $this = $(this);
      if (!$this.hasClass('disabled-cell')) {
        $('.advance-rates-table td, .advance-rates-table th').removeClass('cell-selected cell-hovered');
        var col = getColumnIndex($this);
        $this.addClass('cell-selected').closest('tr').find('td.row-label').addClass('cell-selected');
        $($rateTable.find('tr.add-advance-column-labels th')[col]).addClass('cell-selected');
      };
      validateForm();
    });

    // Hover behavior
    $rateTableCells.hover( function(){
      var $this = $(this);
      var col = getColumnIndex($this);
      if (!$this.hasClass('cell-selected') && $this.hasClass('selectable-cell')) {
        $this.toggleClass('cell-hovered').closest('tr').find('td.row-label').toggleClass('cell-hovered');
        $($rateTable.find('tr.add-advance-column-labels th')[col]).toggleClass('cell-hovered');
      };
    });
  };

  function getColumnIndex($cell) {
    if ($cell.closest('tr').hasClass('add-advance-table-label-row')) {
      return $cell.index() - 1;
    } else {
      return $cell.index();
    };
  };

  function selectColumnLabelIfRatePreSelected() {
    var $selectedCell = $rateTable.find('td.cell-selected.selectable-cell');
    if ($selectedCell.length) {
      var col = getColumnIndex($selectedCell);
      $($rateTable.find('tr.add-advance-column-labels th')[col]).addClass('cell-selected');
    };
  };

  function setRateFromElementData($element) {
    $typeField.val($element.data('advance-type'));
    $termField.val($element.data('advance-term'));
  };

  $formPreview.on('submit', function(){
    var $selectedCell = $($rateTable.find('.cell-selected.add-advance-rate-cell'));
    setRateFromElementData($selectedCell);
    showAddAdvanceLoadingState();
    $submitFieldPreview.attr('disabled', true); // Backup to prevent resubmission, as page is already covered by overlay and inaccessible.
  });

  // Get rates only when there is a rate table
  if ($rateTable.length > 0) {
    showAdvanceRates();
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
});