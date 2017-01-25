function labelClassForState(state) {
    switch (state) {
        case 'pending':
            labelClass = 'label-warning';
            break;

        case 'imported':
            labelClass = 'label-success';
            break;

        case 'error':
            labelClass = 'label-error';
            break;
    }
    return labelClass;
}

function update_row(item) {
    row = $('#product_import_items_data tr[data-product-import-id="'+item.id+'"]');
    row.find('td.product_id').html(item.product_id);
    row.find('td.state span').html(item.state).removeClass('label-warning label-error').addClass(labelClassForState(item.state));
    if (item.state == 'error') {
        row.find('td.state span').attr('title', item.state_message).tooltip();
    }
    row.find('td.publish_state span').html(item.publish_state);
    if (item.publish_state == 'published') {
        row.find('td.publish_state span').removeClass('label-warning').addClass('label-success');
    }
    if (item.state == 'imported') {
        row.find('td.actions').html('<a name="View" class="btn btn-primary btn-sm icon-link with-tip action-eye-open no-text" target="_blank" href="/products/'+item.product_id+'"><span class="icon icon-eye-open"></span> </a> <a target="_blank" data-action="edit" class="btn btn-primary btn-sm icon-link with-tip action-edit no-text" title="Edit" href="/admin/products/'+item.product_id+'/edit"><span class="icon icon-edit"></span> </a>');
    }
}

function import_products() {
    var source = new EventSource('import');
    source.addEventListener('update', function(e){
        if (e.data.match(/^END/)) {
            source.close();
            import_status = e.data.split(':')[1]
            if (import_status == 'complete') {
                $('#btn-import').hide();
                $('div[data-hook="buttons"] span.or').hide();
                $('div[data-hook="buttons"] a.btn-default').html('<span class="icon icon-remove"></span> Back');
            } else {
                $('#btn-import').blur();
            }
            return;
        }
        item = JSON.parse(e.data);
        update_row(item)
    });
}

$(function(){
    $('#btn-import').click(function(event){
        event.preventDefault();
        import_products();
    });
});

$(function() {
    $('td.state span.label-error').tooltip();
})
