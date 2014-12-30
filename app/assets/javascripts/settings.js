$(function () {
  $('.settings-email input[type="checkbox"]').on('click', function(event){
    var $this = $(this);
    var id = $this.attr('id');
    var checked = $this[0].checked;
    var data = {};

    $this.closest('tr').toggleClass('settings-item-checked');
    data['cookies'] = {};
    data['cookies'][id] = checked;
    $.post('/settings/save', data, function(response){
      $('.settings-save-message-timestamp').html(response['timestamp']);
      $('.settings-save-message').show();
    });
  });
});
