$(function() {
  var $rules_limits_text_fields = $('.rules-limits-form input[type=text]').on('keydown');
  $rules_limits_text_fields.on('keypress', function(e){
    Fhlb.Utils.onlyAllowDigits(e);
  });
  $rules_limits_text_fields.on('keyup', function(e){
    Fhlb.Utils.addCommasToInputField(e);
  });

  var $advance_availability_by_member_dropdown = $('#advance-availability-by-member-dropdown');
  if ($advance_availability_by_member_dropdown) {
    $advance_availability_by_member_dropdown.on('change', function(e) {
      var showEnabled = null;
      switch($('.dropdown li.selected').data('dropdown-value')) {
        case 'all':
          showEnabled = null;
          break;
        case 'enabled':
          showEnabled = true;
          break;
        case 'disabled':
          showEnabled = false;
          break;
        default:
          showEnabled = null; //display all
      }
      var checkboxes = $('.advance-availability .report-cell-right input[type=checkbox]');
      var displayIndex = 1;
      for (var i = 0; i < checkboxes.length; ++i) {
        var checkbox = checkboxes[i];
        var row = checkbox.parentElement.parentElement;
        if (displayIndex % 2 == 0) {
          $(row).removeClass('odd').addClass('even');
        } else {
          $(row).removeClass('even').addClass('odd');
        }
        if (showEnabled == null) {
          row.style['display'] = 'table-row';
          ++displayIndex;
        } else {
          if (checkboxes[i].checked) {
            if (showEnabled) {
              row.style['display'] = 'table-row';
              ++displayIndex;
            } else {
              row.style['display'] = 'none';
            }
          } else { //checkbox not checked
            if (showEnabled) {
              row.style['display'] = 'none';
            } else {
              row.style['display'] = 'table-row';
              ++displayIndex;
            }
          }
        }
      }
    })
  };

  var $earlyShutoffForm = $('.rules-early-shutoff-form');
  $earlyShutoffForm.on('submit', function(e) {
    var frc_shutoff_time = $earlyShutoffForm.find('select[name=frc_shutoff_time_hour]').val() + $earlyShutoffForm.find('select[name=frc_shutoff_time_minute]').val();
    $earlyShutoffForm.find('input[name="early_shutoff_request[frc_shutoff_time]"]').val(frc_shutoff_time);
    var vrc_shutoff_time = $earlyShutoffForm.find('select[name=vrc_shutoff_time_hour]').val() + $earlyShutoffForm.find('select[name=vrc_shutoff_time_minute]').val();
    $earlyShutoffForm.find('input[name="early_shutoff_request[vrc_shutoff_time]"]').val(vrc_shutoff_time);    
  });
});