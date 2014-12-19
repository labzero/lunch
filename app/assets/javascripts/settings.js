$(function () {
  $('.settings-email input[type="checkbox"]').on('click', function(event){
    $(this).closest('tr').toggleClass('settings-item-checked');
    // imitate auto-save
    var dateOptions = {
      weekday: "short", year: "numeric", month: "short",
      day: "numeric", hour: "2-digit", minute: "2-digit"
    };
    var now = new Date();
    $('.settings-save-message-timestamp').html(now.toLocaleTimeString("en-us", dateOptions));
    $('.settings-save-message').show();
  });
});