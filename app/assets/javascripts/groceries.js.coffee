$ ->
  if grocery_id?
    $grocery_table = $('#grocery-table').dataTable
      responsive: false
      ajax: "/groceries/" + grocery_id + "/items/?with_id=true"
      "columnDefs": [
        { "width": "5%", "targets": 4 },
        { "visible": false, "targets": 0 },
      ]

    $('.main').on 'click', '.remove', ->
      row = $(@).parents('tr')
      row_id = $grocery_table.fnGetPosition($(@).parents('tr')[0]);
      item_id = $grocery_table.fnGetData(row)[0];
      $.ajax
        method: "POST"
        url: "/groceries/" + grocery_id + "/remove_item?item_id=" + item_id
        success: ->
          $grocery_table.api().row(row).remove().draw()
