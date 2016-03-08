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
    }
  };
};