var Fhlb;
if (typeof Fhlb === 'undefined') {
  Fhlb = {};
};

if (typeof Fhlb.Track === 'undefined') {
  (function() {
    function ga_defined() {
      return typeof ga === 'function'
    };
    function sendEvent(eventCategory, eventLabel) {
      if (ga_defined()) {
        ga('send', {
          hitType: 'event',
          eventCategory: eventCategory,
          eventAction: 'view',
          eventLabel: eventLabel
        });
      };
    };
    function sendQuickAdvanceEvent(eventCategory) {
      if (ga_defined()) {
        ga('send', {
          hitType: 'event',
          eventCategory: eventCategory,
          eventAction: 'view',
          eventLabel: 'Quick Advance'
        });
      };
    };
    Fhlb.Track = {
      // Old Advances Flow - delete as part of MEM-1460
      quick_advance_rate_table:     function(){sendQuickAdvanceEvent('Quick Advance Rate Table')},
      quick_advance_stock_purchase: function(){sendQuickAdvanceEvent('Quick Advance Stock Purchase')},
      quick_advance_preview:        function(){sendQuickAdvanceEvent('Quick Advance Preview Advance')},
      quick_advance_confirmation:   function(){sendQuickAdvanceEvent('Quick Advance Confirmation')},
      quick_advance_preview_error:  function(){sendQuickAdvanceEvent('Quick Advance Preview Error')},
      quick_advance_catchall_error: function(){sendQuickAdvanceEvent('Quick Advance Catchall Error')},
      // Advances Flow
      advance_rate_table:                  function(){sendEvent('Rate Table View', 'Advances')},
      advance_preview:                     function(){sendEvent('Preview', 'Advances')},
      stock_purchase:                      function(){sendEvent('Stock Gross-Up Pption', 'Advances')},
      advance_success:                     function(){sendEvent('Success', 'Advances')},
      advance_error:                       function(){sendEvent('Error', 'Advances')},
      // Securities Flow
      securities_request_form:             function(){sendEvent('Form View', 'Securities')},
      securities_file_upload:              function(){sendEvent('File Upload', 'Securities')},
      securities_file_upload_failed:       function(){sendEvent('File Upload Error', 'Securities')},
      securities_submit_request:           function(){sendEvent('Request Submitted', 'Securities')},
      securities_submit_request_failed:    function(){sendEvent('Request Submitted Error', 'Securities')},
      securities_authorize_request:        function(){sendEvent('Request Authorized', 'Securities')},
      securities_authorize_request_failed: function(){sendEvent('Request Authorization Error', 'Securities')},
      // 500 Error Page
      generic_error_page:                  function(){sendEvent('500 Error', 'Errors')},
      // Session Time-Out
      session_time_out:                    function(){sendEvent('Session Time-Out', 'Session')}
    };
  })();
};