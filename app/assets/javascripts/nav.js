$(function() {
  $('.nav-menu').closest('li').click(function(event) {
    if ($(event.target).parents('.nav-dropdown').length) {
      return true;
    }
    $(event.currentTarget).siblings().find('.nav-dropdown').hide();
    $(this).find('.nav-dropdown').toggle();
    event.stopPropagation();
    event.preventDefault();
    return false;
  });
  $('body').click(function() {
    $('.nav-dropdown').hide();
  });
  $(document).on('keydown', function(e) {
    if (e.keyCode === 27) {
      e.preventDefault();
      e.stopPropagation();
      $('.nav-dropdown').hide();
    };
  });
});