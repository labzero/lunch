$(function () {
  var jqXHR = false;
  var dropZone = $('[data-dropzone]');
  var resultsContainer = $('[data-results-container]');
  var progressBar = $('.file-upload-progress .inner-gauge-section');
  $('#fileupload').fileupload({
    dataType: 'json',
    dropZone: dropZone,
    add: function(e, data) {
      if (jqXHR) {
        return false;
      } else {
        toggleUploadError($(e.target).data('error-class'), false);
        dropZone.addClass('file-uploading');
        jqXHR = data.submit();
      };
    },
    progressall: function (e, data) {
      var progress = parseInt(data.loaded / data.total * 100, 10);
      progressBar.css(
        'width',
        progress + '%'
      );
    },
    done: function (e, data) {
      var $target = $(e.target);
      var resultsContainerClass = $target.data('results-container-class');
      var formName = $target.data('form-name');
      var inputName = $target.data('input-name');
      if (resultsContainerClass) {
        $('.' + resultsContainerClass).html(data.result.html);
      };
      if (formName && inputName) {
        $('form[name=' + formName + '] input[name=' + inputName + ']').attr('value', data.result.form_data);
      };
    },
    always: function(e, data) {
      dropZone.removeClass('file-uploading');
      progressBar.css('width', '0%');
      jqXHR = false;
    },
    fail: function(e, data) {
      toggleUploadError($(e.target).data('error-class'), true);
    }
  });

  function toggleUploadError(errorClass, active) {
    if (errorClass && active) {
      $('.' + errorClass).show();
    } else if (errorClass) {
      $('.' + errorClass).hide();
    };
  };

  $('[data-cancel-upload]').click(function (e) {
    jqXHR.abort();
  });

  $(document).bind('drop dragover', function (e) {
    e.preventDefault();
  });

  $(document).bind('dragover', function (e) {
    var timeout = window.dropZoneTimeout;
    if (!timeout) {
      dropZone.addClass('in');
    } else {
      clearTimeout(timeout);
    }
    var found = false,
      node = e.target;
    do {
      if (node === dropZone[0]) {
        found = true;
        break;
      }
      node = node.parentNode;
    } while (node != null);
    if (found) {
      dropZone.addClass('hover');
    } else {
      dropZone.removeClass('hover');
    }
    window.dropZoneTimeout = setTimeout(function () {
      window.dropZoneTimeout = null;
      dropZone.removeClass('hover');
    }, 100);
  });
});