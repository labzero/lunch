$(function () {
  $('.nav-securities').on('click', function(event) {
    event.preventDefault();
    event.stopPropagation();
    $('body').flyout({topContent: $('.nav-securities-flyout').clone(true), rowClass: 'nav-securities-flyout-row', hideCloseButton: true});
    $('.flyout .nav-securities-flyout .primary-button').attr('href', $(event.target).attr('href'))
  });
});