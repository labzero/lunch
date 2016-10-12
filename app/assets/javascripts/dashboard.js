$(function () {

  function showDashboardAddAdvanceClosedState() {
    $('.etransact-status-message-closed ').show();
    $('.dashboard-module-add-advance-link, .dashboard-module-add-advance-form input, .dashboard-module-add-advance-form .input-field-container').hide();
    $('.dashboard-module-advances').addClass('dashboard-module-advances-closed');
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
    if ($rate_element.is('.dashboard-element-loading')) {
      getOvernightVrc();
    }
  };

  function getOvernightVrc() {
    if (!isCheckingRate) {
      isCheckingRate = true;
      $.get('/dashboard/current_overnight_vrc').done(function(data) {
        $rate_element_children.remove();
        if (typeof data.rate == 'undefined' || data.rate == null) {
          $('.dashboard-module-add-advance-link, .dashboard-vrc-overnight-message, .dashboard-advances-rate').hide();
        }
        else
        {
          $('.dashboard-module-add-advance-link, .dashboard-vrc-overnight-message, .dashboard-advances-rate').show();
          $rate_element.html(data.rate).append($rate_element_children);
        }
        if (!data.etransact_active) {
          showDashboardAddAdvanceClosedState();
        }
      }).always(function() {
        isCheckingRate = false;
        $rate_element.removeClass('dashboard-element-loading');
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