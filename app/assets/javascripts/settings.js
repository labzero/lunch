$(function () {
  var settingsSaveButton = $('.settings-email .save-button');
  var $resetPin = $('.settings-reset-pin');
  var $resetToken = $('.settings-resynchronize-token');
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

  function showUsersFlyout($ele, content) {
    $ele.flyout({topContent: content, resetContent: true, rowClass: 'settings-users-flyout', hideCloseButton: true});
  };

  function showUsersError($ele) {
    showUsersFlyout($ele, $('.settings-users .settings-users-error').clone().show());
  }

  function showUsersLoading($ele) {
    showUsersFlyout($ele, $('.settings-users .settings-users-loading').clone().show());
  }

  var lockSelector = '.settings-user-lock a';
  $('.settings-users').on('ajax:success', lockSelector, function(event, json, status, xhr) {
    var $ele = $(event.target);
    showUsersFlyout($ele, json.html);
    $ele.parents('tr').replaceWith(json.row_html);
  }).on('ajax:error', lockSelector, function(event, xhr, status, error) {
    var $ele = $(event.target);
    showUsersError($ele);
  }).on('ajax:beforeSend', lockSelector, function(event) {
    var $ele = $(event.target);
    showUsersLoading($ele);
  });

  function buildFormErrorHandler ($root) {
    return function(event, xhr, status, error) {
      $root.find('.form-flash-message').hide();
      $root.find('.form-flash-message[data-type=error]').show();
    }
  }

  function buildFormCompleteHandler ($root) {
    return function(event, xhr, status) {
      $root.removeClass('loading');
      $root.find('input').removeAttr('disabled');
    }
  }

  function handleSuccess($root) {
    $root.find('.form-flash-message').hide();
    $root.find('.form-flash-message[data-type=success]').show();
    $root.find('form').trigger('reset');
    $root.toggleClass('open');
  }

  function handleError($root, status, custom_handler) {
    var $field = $();
    var error = 'unknown';
    if (status == 'invalid_token') {
      $field = $root.find('input[name=securid_token]');
      error = status;
    } else if (status == 'invalid_pin') {
      $field = $root.find('input[name=securid_pin]');
      error = 'invalid_pin'
    } else if (status == 'denied') {
      $field = $root.find('input[name=securid_token]');
      $resetPin.find('input[name=securid_pin]').addClass('input-field-error');
      error = 'denied';
    } else {
      var error_found = false;
      if (custom_handler) {
        var result = custom_handler($root, status);
        if (result) {
          $field = result[0];
          error = result[1];
          error_found = true;
        }
      }
      if (!error_found) {
        $root.find('.form-flash-message[data-type=error]').show();
      }
    }

    $field.addClass('input-field-error');
    $field.parents('fieldset').find('p[data-error-type=' + error + ']').show();
  }

  function beforeValidate($root) {
    $root.find('.form-flash-message').hide();
    $root.find('.form-error').hide();
    $root.find('.input-field-error').removeClass('input-field-error');
  }

  function validatePin($root, field_name) {
    var valid = true;
    var $field = $root.find('input[name=' + field_name + ']');
    if (!$field.val().match(/^\d{4}$/) ) {
      valid = false;
      $field.parents('fieldset').find('.form-error[data-error-type=invalid_pin]').show();
      $field.addClass('input-field-error');
    }

    return valid;
  }

  function validateToken($root, field_name) {
    var valid = true;
    var $field = $root.find('input[name=' + field_name + ']');
    if (!$field.val().match(/^\d{6}$/) ) {
      valid = false;
      $field.parents('fieldset').find('.form-error[data-error-type=invalid_token]').show();
      $field.addClass('input-field-error');
    }

    return valid;
  }

  function afterValidate ($root, valid) {
    if (valid) {
      $root.addClass('loading');
      $root.find('input').attr('disabled', true);
    };
  }

  $resetPin.find('form').on('ajax:success', function(event, json, status, xhr) {
    if (json.status == 'success') {
      handleSuccess($resetPin);
    } else {
      handleError($resetPin, json.status, function($root, status) {
        if (status == 'must_resynchronize') {
          return [$root.find('input[name=securid_token]'), status];
        }
        if (status == 'invalid_new_pin') {
          return [$root.find('input[name=securid_new_pin]'), 'invalid_pin'];
        }

        return false;
      });
    }
  }).on('ajax:error', buildFormErrorHandler($resetPin))
  .on('ajax:complete', buildFormCompleteHandler($resetPin))
  .on('ajax:beforeSend', function(event) {
    var valid = true;
    beforeValidate($resetPin);

    $.each(['securid_pin', 'securid_new_pin', 'securid_confirm_pin'], function(index, name) {
      if (!validatePin($resetPin, name)) {
        valid = false;
      }
    });

    if (!validateToken($resetPin, 'securid_token')) {
      valid = false;
    }

    var $field = $resetPin.find('input[name=securid_confirm_pin]');
    if ($field.val() != $resetPin.find('input[name=securid_new_pin]').val()) {
      valid = false;
      $field.parents('li').find('.form-error[data-error-type=pin_mismatch]').show();
      $field.addClass('input-field-error');
    }

    afterValidate($resetPin, valid);

    return valid;
  });

  $resetToken.find('form').on('ajax:success', function(event, json, status, xhr) {
    if (json.status == 'success') {
      handleSuccess($resetToken);
    } else {
      handleError($resetToken, json.status, function($root, status) {
        if (status == 'invalid_next_token') {
          return [$root.find('input[name=securid_next_token]'), 'invalid_token'];
        }

        return false;
      });
    }
  }).on('ajax:error', buildFormErrorHandler($resetToken))
  .on('ajax:complete', buildFormCompleteHandler($resetToken))
  .on('ajax:beforeSend', function(event) {
    var valid = true;
    beforeValidate($resetToken);

    $.each(['securid_token', 'securid_next_token'], function(index, name) {
      if (!validateToken($resetToken, name)) {
        valid = false;
      }
    });

    if (!validatePin($resetToken, 'securid_pin')) {
      valid = false;
    }

    afterValidate($resetToken, valid);

    return valid;
  });
});
