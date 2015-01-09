$(function() {
  $('.report-table[data-sortable]').each(function(ele) {
    var $this = $(this);
    $this.DataTable({
        paging: false,
        info: false,
        searching: false,
        order: $this.data('default-sort') || [[0, 'asc']],
        columnDefs: [
          {
            targets: 'report-column-nosort',
            orderable: false
          }
        ]
      })
  });
}); 