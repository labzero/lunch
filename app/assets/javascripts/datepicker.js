$(function () {
  function bindDatepickers() {
    // set up all date-pickers on the page
    $('.datepicker-trigger').each(function(i, datePickerTrigger) {
      var $datePickerTrigger = $(datePickerTrigger);

      if ($datePickerTrigger.data('datepicker-initialized')) {
        return;
      };

      var $wrapper = $($datePickerTrigger.siblings('.datepicker-wrapper'));
      var openDir = $wrapper.data('date-picker-open-direction') || false;
      var singleDatePicker = $wrapper.data('date-picker-single-date-picker') || false;
      var presets = $wrapper.data('date-picker-presets');
      var $form = $($wrapper.data('date-picker-form'));
      var ranges = {};
      var lastCustomLabel;
      var defaultPreset = 1;
      var maxDate = moment($wrapper.data('date-picker-max-date'));
      var minDate = $wrapper.data('date-picker-min-date') ? moment($wrapper.data('date-picker-min-date')) : false;
      var filter = $wrapper.data('date-picker-filter');
      var filterOptions = $wrapper.data('date-picker-filter-options');
      var today = $wrapper.data('date-picker-today');
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
        maxDate: maxDate,
        minDate: minDate,
        filter: filter,
        filterOptions: filterOptions,
        today: today
      });
      datePickerSelectionHandler($datePickerTrigger, $wrapper, presets);
      setDatePickerApplyListener($datePickerTrigger, $form);
      setDatePickerPlaceholder($datePickerTrigger, startDate, endDate);
      if (filter !== undefined) {
        disablePresets($datePickerTrigger, filter, filterOptions, today);
        if (singleDatePicker) {
          $datePickerTrigger.on('updateCalendar.daterangepicker showCalendar.daterangepicker show.daterangepicker', function(){
            filterDates(filter, filterOptions);
          });
        };
      };

      $datePickerTrigger.data('datepicker-initialized', true);
    });
  };

  bindDatepickers();

  $('body').on('datepicker-rebind', bindDatepickers);

  function initializeDatePicker($datePickerTrigger, $datePickerWrapper, options) {
    var optionsHash = {
      startDate: options.startDate,
      endDate: options.endDate,
      ranges: options.ranges,
      maxDate: options.maxDate,
      minDate: options.minDate,
      today: options.today,
      parentEl: $datePickerWrapper,
      locale: {
        customRangeLabel: options.customLabel,
        cancelLabel: ''
      },
      opens: options.opens,
      singleDatePicker: options.singleDatePicker
    };
    $datePickerTrigger.daterangepicker(optionsHash);
    addUpdateEventTrigger($datePickerTrigger);
    $datePickerTrigger.daterangepicker(optionsHash); // reinitialize the datepicker with the prototype changes made by `addUpdateEventTrigger`

    // Append the daterangepicker's start and end inputs to our own div for design purposes, then attach its event handlers
    var $datePickerStartInput = $datePickerWrapper.find('.daterangepicker_start_input');
    var $datePickerEndInput = $datePickerWrapper.find('.daterangepicker_end_input');
    $datePickerWrapper.find('.daterangepicker').prepend('<div class="datepicker_input_field"><div class="daterangepicker_start_input_wrapper"></div><div class="daterangepicker_end_input_wrapper"></div></div>');
    $datePickerEndInput.prependTo($('.daterangepicker_end_input_wrapper'));
    $datePickerStartInput.prependTo($('.daterangepicker_start_input_wrapper'));
    $([$datePickerEndInput, $datePickerStartInput]).each(function(){this.on('change', function(e) {
      snapToValidDate(e, $datePickerTrigger.data('daterangepicker'), options);
      $datePickerTrigger.data('daterangepicker').inputsChanged(e)});})
    $datePickerWrapper.find('.calendar, .ranges').off('mouseenter mouseleave'); // daterangepicker binds these unwanted events

    $datePickerWrapper.find('.daterangepicker .ranges').insertBefore($datePickerWrapper.find('.calendar.first'));
    $datePickerWrapper.find('.range_inputs').html($datePickerWrapper.find('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons
    $($datePickerWrapper.find('.ranges li')[options.defaultPreset]).click(); // default to "Last Month" when first opening
    if (options.singleDatePicker) {
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

  // Choosing a preset label shouldn't close the datepicker until the apply button is pressed
  function datePickerSelectionHandler($datePickerTrigger, $datePickerWrapper, presets){
    $datePickerWrapper.find('.ranges ul li').each(function(index, label) {
      var $label = $(label);
      $(label).on('click', function(event){
        event.stopPropagation();
        if (!$label.hasClass('disabled')) {
          $('.ranges ul li').removeClass('active');
          $label.addClass('active');
          if (presets[index]) {
            var preset = presets[index];
            if (!preset.is_custom) {
              if (preset.start_date) {
                $datePickerTrigger.data('daterangepicker').setStartDate(preset.start_date);
              };
              if (preset.end_date) {
                $datePickerTrigger.data('daterangepicker').setEndDate(preset.end_date);
              };
            };
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
  };

  function filterDates(filter, filterOptions) {
    var monthMoment = moment($('.calendar.first .month').text(), 'MMM YYYY');
    var lastDayOfMonth = monthMoment.endOf('month').date();
    switch (filter) {
      case filterOptions['end_of_month']:
        disableAllExceptEndOfMonth(lastDayOfMonth);
        break;
      case filterOptions['end_of_quarter']:
        // disable all dates except 3/31, 6/30, 9/30, 12/31
        var month = monthMoment.month();
        if (month === 2 || month === 5 || month === 8 || month === 11) {
          disableAllExceptEndOfMonth(lastDayOfMonth);
        } else {
          $('.calendar.first td.available').removeClass('available').addClass('off disabled');
        };
        break;
    };
  };

  function disableAllExceptEndOfMonth(day) {
    $('.calendar.first td.available').each(function(i){
      var $node = $(this);
      if ($node.text() != day) {
        $node.removeClass('available');
        $node.addClass('off disabled');
      };
    });
  };

  // monkeypatch DateRangePicker to trigger event when calendar is updated
  function addUpdateEventTrigger(picker) {
    var picker = $(picker).data('daterangepicker');
    var pickerPrototype = Object.getPrototypeOf(picker);
    var updateCalendarsOld = pickerPrototype.updateCalendars;
    if (!updateCalendarsOld.fhlbModified) {
      pickerPrototype.updateCalendars = function () {
        var oldResults = updateCalendarsOld.apply(this);
        this.element.trigger('showCalendar.daterangepicker', this);
        return oldResults;
      };
      pickerPrototype.updateCalendars.fhlbModified = true;
    };
  };

  function disablePresets($picker, filter, filterOptions, today) {
    var picker = $picker.data('daterangepicker');
    var today = moment(today);
    var endOfMonth = moment(today).endOf('month'); // clone so that `endOf` does not mutate original `date`
    switch (filter) {
      case filterOptions['end_of_month']:
        if (today !== endOfMonth) {
          $(picker.container.find('.ranges li')[0]).addClass('disabled'); // 'Today'
        };
        break;
      case filterOptions['end_of_quarter']:
        $(picker.container.find('.ranges li')[0]).addClass('disabled'); // 'Today'
        $(picker.container.find('.ranges li')[1]).addClass('disabled'); // 'End of {month}'
        break;
    };
  };

  function snapToValidDate(e, picker, options){
    //  snap to maxDate or minDate if date is out of range
    var maxDate = moment(options.maxDate);
    var minDate = moment(options.minDate);
    var today = moment(options.today);
    var thisMonth = moment().month();
    var $el = $(e.target);
    var date = moment($el.val());
    if (date > maxDate || date < minDate) {
      date = date > maxDate ? maxDate : minDate;
      options.singleDatePicker ? picker.setEndDate(date.format('MM/DD/YYYY')) : null;
      $el.val(date.format('MM/DD/YYYY'));
    } else if (options.singleDatePicker) {
      picker.setEndDate(date.format('MM/DD/YYYY'));
      $el.val(date.format('MM/DD/YYYY'));
    };

    // apply filters if necessary
    if (options.singleDatePicker && options.filter !== undefined && options.filterOptions !== undefined) {
      var inputMonth = date.month();
      var endOfMonth = moment(date).endOf('month'); // clone so that `endOf` does not mutate original `date`
      switch (options.filter) {
        // Snap to end of month
        case options.filterOptions['end_of_month']:
          if (!date.isSame(endOfMonth, 'day') && inputMonth >= thisMonth) {
            picker.setEndDate((date.subtract(1, 'month')).endOf('month'));
          } else {
            picker.setEndDate(date.endOf('month').format('MM/DD/YYYY'));
          };
          $el.val(date.format('MM/DD/YYYY')); // uses the mutated value of `date` set in the if/else statement above
          break;
        // Snap to end of quarter
        case options.filterOptions['end_of_quarter']:
          var endOfQuarter;
          var endOfLastQuarter;
          var setQuarter

          if (inputMonth <= 2) {
            endOfQuarter = moment(date.year()+'/3/31');
            endOfLastQuarter = moment((date.year() - 1)+'/12/31');
          } else if (inputMonth <= 5) {
            endOfQuarter = moment(date.year()+'/6/30');
            endOfLastQuarter = moment(date.year()+'/3/31');
          } else if (inputMonth <= 8) {
            endOfQuarter = moment(date.year()+'/9/30');
            endOfLastQuarter = moment(date.year()+'/6/30');
          } else if (inputMonth <= 12) {
            endOfQuarter = moment(date.year()+'/12/31');
            endOfLastQuarter = moment(date.year()+'/9/30');
          };

          setQuarter = endOfQuarter > today ? endOfLastQuarter : endOfQuarter;
          picker.setEndDate(setQuarter);
          $el.val(setQuarter.format('MM/DD/YYYY'));
          break;
      };
    };
  };

});

