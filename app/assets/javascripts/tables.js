$(function() {
  $('.report-table[data-sortable]').DataTable({
    paging: false,
    info: false,
    searching: false,
    order: [],
    columnDefs: [
      {
        targets: 'report-column-nosort',
        orderable: false
      }
    ]
  })
}); 