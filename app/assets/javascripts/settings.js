$(function () {
  var settingsSaveButton = $('.settings-email .save-button');
  var $resetPin = $('.settings-reset-pin');
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

  $('.settings-group .settings-group-cta, .settings-group input[type=reset]').click(function() {
    var $this = $(this);
    $this.parents('.settings-group').toggleClass('open');
    $this.parents('.settings-group').find('.form-flash-message').hide();
  });
  $resetPin.find('form').on('ajax:success', function(event, json, status, xhr) {
    if (json.status == 'success') {
      $resetPin.find('.form-flash-message').hide();
      $resetPin.find('.form-flash-message[data-type=success]').show();
      $resetPin.find('form').trigger('reset');
      $resetPin.toggleClass('open');
    } else {
      var $field = $();
      var error = 'unknown';

      if (json.status == 'invalid_token' || json.status == 'must_resynchronize') {
        $field = $resetPin.find('input[name=securid_token]');
        error = json.status;
      } else if (json.status == 'invalid_pin') {
        $field = $resetPin.find('input[name=securid_pin]');
        error = 'invalid_pin'
      } else if (json.status == 'denied') {
        $field = $resetPin.find('input[name=securid_token]');
        $resetPin.find('input[name=securid_pin]').addClass('input-field-error');
        error = 'denied';
      } else if (json.status == 'invalid_new_pin') {
        $field = $resetPin.find('input[name=securid_new_pin]');
        error = 'invalid_pin';
      } else {
        $resetPin.find('.form-flash-message[data-type=error]').show();
      }

      $field.addClass('input-field-error');
      $field.parents('li').find('p[data-error-type=' + error + ']').show();
    }
  }).on('ajax:error', function(event, xhr, status, error) {
    $resetPin.find('.form-flash-message').hide();
    $resetPin.find('.form-flash-message[data-type=error]').show();
  }).on('ajax:complete', function(event, xhr, status) {
    $resetPin.removeClass('loading');
    $resetPin.find('input').removeAttr('disabled');
  }).on('ajax:beforeSend', function(event) {
    var valid = true;
    var $field;
    $resetPin.find('.form-flash-message').hide();
    $resetPin.find('.form-error').hide();
    $resetPin.find('.input-field-error').removeClass('input-field-error');

    $.each(['securid_pin', 'securid_new_pin', 'securid_confirm_pin'], function(index, name) {
      $field = $resetPin.find('input[name=' + name + ']');
      if (!$field.val().match(/^\d{4}$/) ) {
        valid = false;
        $field.parents('li').find('.form-error[data-error-type=invalid_pin]').show();
        $field.addClass('input-field-error');
      }
    });

    $field = $resetPin.find('input[name=securid_token]');
    if (!$field.val().match(/^\d{6}$/) ) {
      valid = false;
      $field.parents('li').find('.form-error[data-error-type=invalid_token]').show();
      $field.addClass('input-field-error');
    }

    $field = $resetPin.find('input[name=securid_confirm_pin]');
    if ($field.val() != $resetPin.find('input[name=securid_new_pin]').val()) {
      valid = false;
      $field.parents('li').find('.form-error[data-error-type=pin_mismatch]').show();
      $field.addClass('input-field-error');
    }

    if (valid) {
      $resetPin.addClass('loading');
      $resetPin.find('input').attr('disabled', true);
    };

    return valid;
  });
});
