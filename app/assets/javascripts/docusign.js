$(function() {
  $('.docusign-sign-trigger').on('click', function(event) {
    event.stopPropagation();
    event.preventDefault();
    var $target = $(event.target);
    var $link = $target.attr('href');
    var $title = $target.attr('data-docusign-title');
    confirmDocusignClick($link, $title);
  });

  function confirmDocusignClick($link, $title) {
    $('body').flyout({
      topContent: $('.docusign-form-flyout').clone(true),
      hideCloseButton: true
    });
    var $flyout = $('.flyout')
    $flyout.addClass('flyout-confirmation-dialogue');
    var $flyoutTitle = $flyout.find('.docusign-form-name');
    $flyoutTitle[0].innerHTML = $title;
    var $flyoutLink = $flyout.find('.primary-button');
    $flyoutLink[0].href = $link;
  };
});