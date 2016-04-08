var Fhlb;
if (typeof Fhlb === 'undefined') {
  Fhlb = {};
};

if (typeof Fhlb.Utils === 'undefined') {
  Fhlb.Utils = {
    onlyAllowDigits: function(e, extra_allowed_ascii_codes) {
      var allowedAsciiCodes = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57];

      if (extra_allowed_ascii_codes) {
        allowedAsciiCodes = allowedAsciiCodes.concat(extra_allowed_ascii_codes);
      };

      if (!(allowedAsciiCodes.indexOf(e.which)>=0)) {
        e.preventDefault();
      };
    },
    addCommasToInputField: function(e) {
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
    },
    validateSecurID: function($form) {
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
      };
      if (!token.match(/^\d{6}$/)) {
        valid = false;
        $token.addClass('input-field-error');
        $form.find('p[data-error-type=invalid_token]').show();
      };
      return valid;
    },
    findAndDisplaySecurIDErrors: function($form) {
      var errorType = $form.data('securid-status');
      var $pin = $form.find('input.securid-field-pin');
      var $token = $form.find('input.securid-field-token');

      $form.find('p[data-error-type=' + errorType + ']').show();
      if (errorType == 'invalid_pin' || errorType == 'must_change_pin') {
        $pin.addClass('input-field-error');
      } else if (errorType == 'invalid_token' || errorType == 'must_resynchronize') {
        $token.addClass('input-field-error');
      } else if (errorType == 'denied') {
        $pin.addClass('input-field-error');
        $token.addClass('input-field-error');
      };
    }
  };
};