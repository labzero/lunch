$(function () {

  // set up all date-pickers on the page
  $('.datepicker-trigger').each(function(i, datePickerTrigger) {

    var $datePickerTrigger = $(datePickerTrigger);
    var $wrapper = $($datePickerTrigger.siblings('.datepicker-wrapper'));
    var openDir = $wrapper.data('date-picker-open-direction') || false;
    var singleDatePicker = $wrapper.data('date-picker-single-date-picker') || false;
    var presets = $wrapper.data('date-picker-presets');
    var $form = $($wrapper.data('date-picker-form'));
    var ranges = {};
    var lastCustomLabel;
    var defaultPreset = 1;
    var maxDate = $wrapper.data('date-picker-max-date') ? moment($wrapper.data('date-picker-max-date')) : false;
    $.each(presets, function(index, preset) {
      if (preset.start_date) {
        preset.start_date = moment(preset.start_date);
      };
      if (preset.end_date) {
        preset.end_date = moment(preset.end_date);
      };
      if (!preset.is_custom) {
        ranges[preset.label] = [preset.start_date, preset.end_date]
      } else {
        lastCustomLabel = preset.label;
      };
      if (preset.is_default) {
        defaultPreset = index;
      };
    });

    var startDate = presets[defaultPreset].start_date;
    var endDate = presets[defaultPreset].end_date

    initializeDatePicker($datePickerTrigger, $wrapper, {
      ranges: ranges,
      customLabel: lastCustomLabel,
      opens: openDir,
      defaultPreset: defaultPreset,
      startDate: startDate,
      endDate: endDate,
      singleDatePicker: singleDatePicker,
      maxDate: maxDate
    });
    datePickerSelectionHandler($datePickerTrigger, $wrapper, presets);
    setDatePickerApplyListener($datePickerTrigger, $form);
    setDatePickerPlaceholder($datePickerTrigger, startDate, endDate);
  });

  function initializeDatePicker($datePickerTrigger, $datePickerWrapper, options) {
    $datePickerTrigger.daterangepicker(
      {
        startDate: options.startDate,
        endDate: options.endDate,
        ranges: options.ranges,
        maxDate: options.maxDate,
        parentEl: $datePickerWrapper,
        locale: {
          customRangeLabel: options.customLabel,
          cancelLabel: ''
        },
        opens: options.opens,
        singleDatePicker: options.singleDatePicker
      }
    );
    $datePickerWrapper.find('.daterangepicker .ranges').insertBefore($datePickerWrapper.find('.calendar.first'));
    $datePickerWrapper.find('.range_inputs').html($datePickerWrapper.find('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons
    $($datePickerWrapper.find('.ranges li')[options.defaultPreset]).click(); // default to "Last Month" when first opening
    if (options.singleDatePicker) {
      // hide the calendar when you're first opening the datepicker, unless the 'custom' tab is the one selected
      $('.datepicker-trigger').on('show.daterangepicker', function(event){
        if ( !$datePickerWrapper.find('.ranges li').last().hasClass('active') ) {
          $datePickerWrapper.find('.calendar.single').hide();
        }
      });
      $datePickerWrapper.find('.ranges').show(); // always show the pre-selected tabs (daterangepicker.js hides these when set with the option singleDatePicker
      $datePickerWrapper.find('.calendar').off('click.daterangepicker', 'td.available'); // remove daterangepicker's event handling so that we can force user to click 'apply' button when selecting custom date
      $datePickerWrapper.find('.calendar').on('click.daterangepicker', 'td.available', function(event){
        var $target = $(event.target);
        event.stopPropagation();
        event.preventDefault();
        // set start and end dates to this date
        var monthAndYear = $target.closest('table').find('th.month').text();
        var day = $target.text();
        var selectedDate = new Date(monthAndYear + ' ' + day);
        $datePickerTrigger.data('daterangepicker').setStartDate(selectedDate);
        $datePickerTrigger.data('daterangepicker').setEndDate(selectedDate);
      });
    }
  };

  // Choosing "This Month" or "Last Month" shouldn't close the datepicker until the apply button is pressed
  function datePickerSelectionHandler($datePickerTrigger, $datePickerWrapper, presets){
    $datePickerWrapper.find('.ranges ul li').each(function(index, label) {
      var $label = $(label);
      $(label).on('click', function(event){
        event.stopPropagation();
        $('.ranges ul li').removeClass('active');
        $label.addClass('active');
        if (presets[index]) {
          var preset = presets[index];
          if (!preset.is_custom) {
            $datePickerWrapper.find('.calendar').hide();
            
            if (preset.start_date) {
              $datePickerTrigger.data('daterangepicker').setStartDate(preset.start_date);
            };

            if (preset.end_date) {
              $datePickerTrigger.data('daterangepicker').setEndDate(preset.end_date);
            };
          } else {
            var calendarSelector = '.calendar';
            if ($datePickerTrigger.data('daterangepicker').singleDatePicker) {
              calendarSelector += '.right';
            }
            $datePickerWrapper.find(calendarSelector).show();
          };
        };
      });
    });
  };

  // accessing the start and end dates once the apply button is pressed
  function setDatePickerApplyListener($datePickerTrigger, $form){
    $datePickerTrigger.on('apply.daterangepicker', function(ev, picker) {
      ev.stopPropagation();
      setDatePickerPlaceholder($datePickerTrigger, picker.startDate, picker.endDate);
      $form.find('input[name=start_date]').val(picker.startDate.format('YYYY-MM-DD'));
      if (!$($datePickerTrigger.siblings('.datepicker-wrapper')).data('date-picker-single-date-picker')) {
        $form.find('input[name=end_date]').val(picker.endDate.format('YYYY-MM-DD'));
      }
      $form.submit();
    });
  };

  function setDatePickerPlaceholder($datePickerTrigger, startDate, endDate) {
    if ($($datePickerTrigger.siblings('.datepicker-wrapper')).data('date-picker-single-date-picker')) {
      var input_field_text = $datePickerTrigger.data('date-picker-input-field-text').replace(/\{replace_date\}/, startDate.format('MM/DD/YYYY'));
      $datePickerTrigger.find('input').val(input_field_text);
    }
    else {
      $datePickerTrigger.find('input').val(startDate.format('MM/DD/YYYY') + ' - ' + endDate.format('MM/DD/YYYY'));
    };
  }

});