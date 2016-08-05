$(function () {
  var jqXHR = false;
  var dropZone = $('[data-dropzone]');
  var progressBar = $('.file-upload-progress .inner-gauge-section');
  $('#fileupload').fileupload({
    dataType: 'json',
    dropZone: dropZone,
    add: function(e, data) {
      if (jqXHR) {
        return false;
      } else {
        toggleUploadError($(e.target).data('error-class'), false, null);
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
      var formName = $target.data('form-name');
      var inputName = $target.data('input-name');
      var resultsContainerClass = $target.data('results-container-class');
      if (data.result) {
        if (data.result.errors) {
          failUpload(e, data.result.errors); // For IE
        } else {
          if (resultsContainerClass) {
            $('.' + resultsContainerClass).html(data.result.html);
          };
          if (formName && inputName) {
            $('form[name=' + formName + '] input[name=' + inputName + ']').attr('value', data.result.form_data);
          };
        };
      };
    },
    always: function(e, data) {
      dropZone.removeClass('file-uploading');
      dropZone.hide();
      progressBar.css('width', '0%');
      jqXHR = false;
    },
    fail: function(e) {failUpload(e, null)}
  });

  function failUpload(e, errorMessage) {
    toggleUploadError($(e.target).data('error-class'), true, errorMessage);
  }

  function toggleUploadError(errorClass, active, errorMessage) {
    var $errorNode = errorClass ? $('.' + errorClass) : null;
    if ($errorNode && active) {
      errorMessage ? $errorNode.text(errorMessage) : null;
      $errorNode.show();
    } else if ($errorNode) {
      $errorNode.hide();
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