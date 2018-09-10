/**
 * Created by mikejones on 12/07/2017.
 */

var dashboard = {
    init: function () {
        // messages should fade ...
        $('div.alert').fadeOut(5000, function () {
        });
    }
};

dashboard.init();


var text = {
    init: function () {

        if ($('#mpese-text-panel').length === 1) {
            $('#mpese-details-panel').hide();
            console.log('Yup');
        }

            $('ul#mpese-text-nav > li > a').off('click')
            $('ul#mpese-text-nav > li > a').on('click', function (e) {
                e.preventDefault();

                var $active_tab = $(this).parent().attr('id');
                var $tmp = $active_tab.split("-");
                var $active_panel = $tmp[0].concat("-", $tmp[1], "-panel");

                // loop through tabs
                $tabs = $("#mpese-text-nav > li");
                for (var i = 0; i < $tabs.length; i++) {
                    if ($($tabs[i]).attr('id') === $active_tab) {
                        $($tabs[i]).addClass('active');
                    } else {
                        $($tabs[i]).removeClass('active');
                    }
                }

                // loop through panels
                $panels = $("div[data-panel]");
                for (var i = 0; i < $panels.length; i++) {
                    if ($($panels[i]).attr('id') === $active_panel) {
                        $($panels[i]).show();
                    } else {
                        $($panels[i]).hide();
                    }
                }
            });
        }

}



var image_viewer = {

    tiles: function(image_list) {

        var tiles = [];

        var images = image_list.split(";");

        for (var i = 0; i < images.length; i++) {
            var tmp = images[i].split('.');
            var tile = '/images' + tmp[0] + '.dzi';
            tiles.push(tile)
        }

        return tiles;
    },

    init: function() {

        $('span.mpese-photo').off('click');

        var image_list = $('#mss-images').data('images');

        if (image_list !== undefined) {
             var tiles = this.tiles(image_list);

            var viewer = OpenSeadragon({
                id: "openseadragon",
                prefixUrl: "/resources/openseadragon/images/",
                tileSources: tiles,
                sequenceMode: true,
                showRotationControl: true,
                gestureSettingsTouch: {
                    pinchRotate: true
                }
            });

            $('span.mpese-photo').on('click', function(event) {
                var page = $.inArray($(this).parent().data('facs'), image_list.split(';'));

                if (page !== -1) {
                    viewer.goToPage(page);
                }
            });

        }



    }

}


var facsimile_viewer = {

    /**
     * Make a call to get a list if images from the server. From that, we get the
     * .dzi names so that they can be passed to the OpenSeaDragon server.
     */
    call: function(type, id) {
        $.get("/modules/images.xql", {type: type, id: id}, function(data) {

            // parse the results
            var json = JSON.parse(data);

            // hold the tiles
            var tiles = []

            // create a list of dzi files
            if (typeof json !== "undefined") {
                for (var i = 0; i < json.results.images.length; i++) {
                    console.log("*** " + json.results.images[i])
                    var tmp = json.results.images[i].split('.');
                    var tile = '/images' + tmp[0] + '.dzi';
                    tiles.push(tile)
                }
            }

            // initiate the viewer
            var viewer = OpenSeadragon({
                id: "openseadragon",
                prefixUrl: "/resources/openseadragon/images/",
                tileSources: tiles,
                sequenceMode: true,
                showRotationControl: true,
                gestureSettingsTouch: {
                    pinchRotate: true
                }
            });

            $('span.mpese-photo').on('click', function(event) {

                var selected = $(this).parent().data('facs').replace('.jpg', '.dzi');
                var page = $.inArray('/images' + selected, tiles);

                if (page !== -1) {
                    viewer.goToPage(page);
                }
            });

        });
    },

    init: function() {

        // extract data from the page
        var doc_type = $('#facsimile').data('doc-type');
        var doc_id = $('#facsimile').data('doc-id');

        // call the service and process ...
        if (doc_type && doc_id) {
            this.call(doc_type, doc_id)
        }
    }

};