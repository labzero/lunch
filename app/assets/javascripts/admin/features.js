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
  $('body').on('ajax:beforeSend', '.admin-feature-link-remove', function(e, xhr, settings) {
    $(this).addClass('admin-feature-link-loading');
    $(this).closest('tr').removeClass('admin-feature-row-error');
    $('.admin-feature-edit .secondary-button').attr('disabled', 'disabled');
  }).on('ajax:success', '.admin-feature-link-remove', function(e, data, status, xhr) {
    var $row = $(this).closest('tr');
    var $table = $(this).closest('table');
    var $tbody = $table.find('tbody');
    setTimeout(function() {
      $row.remove();
      if ($('.admin-feature-edit table tr:not(.admin-feature-none-enabled)').length == 0) {
        $('.admin-feature-edit .admin-conditional-icon').removeClass('admin-conditional-icon').addClass('admin-off-icon');
      }
      if ($tbody.find('tr').length == 0) {
        $tbody.append($table.data('empty-html'));
      }
    }, 1);
  }).on('ajax:error', '.admin-feature-link-remove', function(e, data, status, xhr) {
    $(this).removeClass('admin-feature-link-loading');
    $(this).closest('tr').addClass('admin-feature-row-error');
  }).on('ajax:complete', '.admin-feature-link-remove', function(e, xhr, status) {
    setTimeout(function () {
      if ($('.admin-feature-edit .admin-feature-link-loading').length == 0) {
        $('.admin-feature-edit .secondary-button').removeAttr('disabled');
      }
    }, 1);
  })

});