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
      $.each(data.result.files, function (index, file) {
        // TODO: Redraw table with new data as part of MEM-1591
      });
    },
    always: function(e, data) {
      dropZone.removeClass('file-uploading');
      progressBar.css('width', '0%');
      jqXHR = false;
    }
  });

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