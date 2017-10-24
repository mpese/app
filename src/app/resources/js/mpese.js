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

text.init()