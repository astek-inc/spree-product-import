var DYW = DYW || {

    status_success: 'OK',

    delete_import: function(href, id) {
        if (!confirm('Are you sure?')) {
            $('#'+id).blur();
            return;
        }

        window.scrollTo(0, 0);
        $('#status').html('<div class="alert alert-info alert-progress"><div class="spinner">Please wait...</div><div class="progress-message">Please wait...</div></div>');

        var source = new EventSource(href);
        source.addEventListener('update', function(e){

            response = JSON.parse(e.data);
            if (response.status == DYW.status_success) {
                $('#'+id).closest('tr').remove();
                $('#status').html('<div class="alert alert-success">The import and product data has been deleted.</div>');
                window.setTimeout('$("#status div").hide("slow")', 3000);
            } else {
                $('#status').html('<div class="alert alert-warning">An error occurred: '+response.message+'</div>');
            }

            source.close();
            $('#'+id).blur();

        });
    },

};

$(function(){
    $('.btn-delete-import').click(function(event){
        event.preventDefault();
        DYW.delete_import(this.href, this.id);
    });
});


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
