(function($){


    $divs = $('.box, .box-title, input, p');
    modal = false;

    $('a').click(function(e){
        e.preventDefault();
        e.stopPropagation();
        if (!modal) {
            modal = true;
            $divs.hide().velocity('transition.bounceUpIn', { duration: 1000, stagger: 100 })
        }
    })

    $('.box-overlay').click(function(e){
        e.preventDefault();
        if (modal) {
            modal = false;
            $divs.velocity('transition.bounceDownOut', { duration: 1000, stagger: 100, backwards: true })
        };
    });

    $('.box').click(function(e){
        e.stopPropagation();
    })



})(jQuery);