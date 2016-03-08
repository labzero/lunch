$(function () {
  var $quickAdvancesInputField = $('.dashboard-module-advances input');
  var quickAdvanceRatesPromise;

  $quickAdvancesInputField.on('keypress', function(e){
    Fhlb.Utils.onlyAllowDigits(e);
  });

  $quickAdvancesInputField.on('input', function(event){
    addCommasToInputField(event);
    openQuickAdvanceFlyout(event, $(this));
  });

  $('.quick-advance-limited-pricing-notice, .dashboard-vrc-overnight-message[data-flyout-trigger], .dashboard-advances-rate[data-flyout-trigger]').on('click', function(event){
    openQuickAdvanceFlyout(event, $quickAdvancesInputField);
  });

  $('.dashboard-module-advances').on('flyout-initialized', function(){
    var $flyoutInput = $('.flyout-top-section input');
    if ($flyoutInput.length > 0) {
      $flyoutInput.focus();
      $flyoutInput[0].setSelectionRange(1, 1);
    }
  }).on('flyout-reset-initiated', function(){
    $quickAdvancesInputField.val('').data('flyout-trigger', 'active');
    $('.quick-advance-desk-closed-message-group a').data('flyout-trigger', 'active');
  });

  function openQuickAdvanceFlyout(event, $element) {
    event.stopPropagation();
    event.preventDefault();
    if ($element.data('flyout-trigger') == 'active') {
      $element.data('flyout-trigger', 'inactive');
      $('.flyout').addClass('dashboard-quick-advance-flyout');
      $('.flyout-bottom-section').addClass('column-3-span-2');
      var topContent = [$('.dashboard-module-advances header').clone(), $('<div class="flyout-top-section-body"></div>').append($('.dashboard-module-advances .input-field-container, .dashboard-module-advances h2, .quick-advance-desk-closed-message-group').clone())];
      var bottomContent = $('.quick-advance-rates, .quick-advance-last-updated-message, .quick-advance-limited-pricing-message, .quick-advance-instruction, .dashboard-module-advances .initiate-quick-advance, .rate-advances-footer, .quick-advance-error').clone();
      $('.dashboard-module-advances').flyout({topContent:topContent, bottomContent:bottomContent, useReferenceElement:true});
      var $amountField = $('.dashboard-quick-advance-flyout input[name=amount]');
      $amountField.attr('id', 'quick-advance-amount'); // to conform to HTML5 standards and avoid duplicate ids
      $amountField.on('keypress', function(e){
        Fhlb.Utils.onlyAllowDigits(e);
      });
      $amountField.on('keyup', function(e){
        addCommasToInputField(e);
      });
      showQuickAdvanceRates();
    };
  };

  function addCommasToInputField(e) {
    var rememberPositionKeycodes = [8,37,38,39,40];
    var target = e.target;
    var position = target.selectionStart;
    var currentVal = $(target).val();
    var newVal = currentVal.replace(/\D/g,'').replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1,");
    if (currentVal !== newVal) {
      $(target).val(newVal);
      if (rememberPositionKeycodes.indexOf(e.which) >= 0) {
        target.selectionEnd = position;
      };
    };
  };

  function getQuickAdvanceRates() {
    if (!quickAdvanceRatesPromise) {
      quickAdvanceRatesPromise = $.get('/dashboard/quick_advance_rates');
      quickAdvanceRatesPromise.error(function() {
        quickAdvanceRatesPromise = false;
      });
    }
    return quickAdvanceRatesPromise;
  };

  function showQuickAdvanceRates() {
    getQuickAdvanceRates().success(function(data) {
      var table = $('.dashboard-quick-advance-flyout table');
      var tbody = table.find('tbody');
      tbody.children().remove();
      tbody.append($(data.html));
      table.quickAdvanceTable(data.id);
      Fhlb.Track.quick_advance_rate_table();
      quickAdvanceRatesPromise = false;
    });
  };

  function showQuickAdvanceClosedState() {
    $('.primary-button.initiate-quick-advance, .rate-advances-footer, .dashboard-module-advances .input-field-container, .flyout .input-field-container').remove();
    $('.dashboard-module-advances').addClass('dashboard-module-advances-closed');
    $('.dashboard-module-advances .quick-advance-desk-closed-message-group').children().hide();
    $('.dashboard-module-advances .quick-advance-desk-closed-message').show();
    $('.dashboard-quick-advance-flyout td, .dashboard-quick-advance-flyout th').removeClass('cell-selected');
    $('.dashboard-quick-advance-flyout .selectable-cell').addClass('disabled-cell');
    if (!$('.quick-advance-confirmation-subheading').is(':visible')) {
      $('.quick-advance-last-updated-message').addClass('show-message');
    };
  };

  if ($('.dashboard-module-advances').length > 0) {
    var isCheckingRate = false;
    var $rate_element = $('.dashboard-advances-rate');
    var $rate_element_children = $rate_element.children();
    setInterval(function() {
      if (!isCheckingRate) {
        getOvernightVrc();
      };
    }, 30000);
    getOvernightVrc();
    getQuickAdvanceRates();
  };

  function getOvernightVrc() {
    if (!isCheckingRate) {
      isCheckingRate = true;
      $.get('/dashboard/current_overnight_vrc').done(function(data) {
        $rate_element_children.remove();
        if (typeof data.rate == 'undefined' || data.rate == null) {
          $('.dashboard-vrc-overnight-message').hide();
          $('.dashboard-advances-rate').hide();
        }
        else
        {
          $('.dashboard-vrc-overnight-message').show();
          $('.dashboard-advances-rate').show();
          $rate_element.html(data.rate).append($rate_element_children);
        }
        if (!data.quick_advances_active) {
          showQuickAdvanceClosedState();
        }
      }).always(function() {
        isCheckingRate = false;
        $rate_element.removeClass('dashboard-element-loading')
      });
    };
  };

  // Handle loading of deferred elements on dashboard
  var $deferredElements = $('.dashboard-module-content-deferred');
  $.each($deferredElements, function(i, el) {
    var $el = $(el);
    checkDeferredElementStatus($el, $el.data('deferred'), $el.data('deferred-load'));
  });

  function checkDeferredElementStatus($el, status_url, load_url) {
    $.get(status_url).done(function(data) {
      var job_status = data.job_status;
      if (job_status == 'completed') {
        loadDeferredElement($el, load_url);
      } else if(job_status == 'failed') {
        deferredElementError($el);
      } else {
        jobStatusTimer = setTimeout(function(){checkDeferredElementStatus($el, status_url, load_url)}, 1000);
      };
    }).fail(function() {
      deferredElementError($el);
    });
  };

  function loadDeferredElement($el, url) {
    $.get(url).done(function(data) {
      var $newContent = $(data);
      $el.replaceWith($newContent);
    }).fail(function() {
      deferredElementError($el);
    });
  };

  function deferredElementError($el) {
    $el.find('.dashboard-module-loading').hide();
    $el.find('.dashboard-module-temporarily-unavailable').show();
  };

});