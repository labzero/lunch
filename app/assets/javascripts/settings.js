$(function () {
  var settingsSaveButton = $('.settings-email .save-button');
  $('.settings-email input[type="checkbox"]').on('click', function(event){
    var settings = getEmailSettings();
    $(this).closest('tr').toggleClass('settings-item-checked');
    saveSettings(settings, true);
  });

  settingsSaveButton.on('click', function(event){
    var settings = getEmailSettings();
    settingsSaveButton.on('saved-settings', location.reload());
    saveSettings(settings);
  });

  function getEmailSettings() {
    var settings = {};
    settings['cookies'] = {};
    $('.settings-email input').each(function(i, input){
      var id = $(input).attr('id');
      settings['cookies'][id] = input.checked;
    });
    return settings;
  };

  function saveSettings(data, autosave) {
    $.post('/settings/save', data, function(response){
      if (autosave) {
        $('.settings-save-message-timestamp').html(response['timestamp']);
        $('.settings-save-message').show();
      };
      response['status'] === 200 ? settingsSaveButton.trigger('saved-settings') : settingsSaveButton.trigger('error-saving-settings');
    });
  };
});
