var Fhlb;
if (typeof Fhlb === 'undefined') {
  Fhlb = {};
};

if (typeof Fhlb.Track === 'undefined') {
  (function() {
    function ga_defined() {
      return typeof ga === 'function'
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
      quick_advance_rate_table:     function(){sendQuickAdvanceEvent('Quick Advance Rate Table')},
      quick_advance_stock_purchase: function(){sendQuickAdvanceEvent('Quick Advance Stock Purchase')},
      quick_advance_preview:        function(){sendQuickAdvanceEvent('Quick Advance Preview Advance')},
      quick_advance_confirmation:   function(){sendQuickAdvanceEvent('Quick Advance Confirmation')},
      quick_advance_preview_error:  function(){sendQuickAdvanceEvent('Quick Advance Preview Error')},
      quick_advance_catchall_error: function(){sendQuickAdvanceEvent('Quick Advance Catchall Error')}
    };
  })();
};