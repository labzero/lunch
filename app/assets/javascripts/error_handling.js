$(function() {
  var $errorPage = $('.error-page');
  ($errorPage.length && $errorPage.data('error-type') === 500) ? Fhlb.Track.generic_error_page() : null;
});