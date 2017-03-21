$(function() {

  $('body').on('click', 'button[data-confirmation-dialog-name]:not([disabled])', function(e) {
    var dialogName = $(this).data('confirmation-dialog-name');
    var dialog = $('.admin-confirmation-dialog[data-confirmation-dialog-name=' + dialogName + ']').clone();
    dialog.on('ajax:beforeSend', function(e, xhr, settings) {
      dialog.addClass('admin-confirmation-loading');
    }).on('ajax:error', function(e, xhr, status, error) {
      dialog.find('h3:first-child').text(error);
      dialog.removeClass('admin-confirmation-loading');
      dialog.addClass('admin-confirmation-error');
    }).on('ajax:success', function(e, data, status, xhr) {
      $('main').html(data);
      dialog.trigger('flyout-close');
    });
    $(this).flyout({topContent: dialog, resetContent: true, hideCloseButton: true, rowClass: 'admin-flyout-confirmation'});
    e.preventDefault();
    e.stopPropagation();
  });

});