$(document).ready(function() {
  //EMAIL FORM AJAX HANDLERS
  $(function(){
     $('#contact_form').submit(function(e){
      e.preventDefault();
      var form      = $(this);
      var post_url  = form.attr('action');
      var post_data = form.serialize();
      $('#messages small').html('Please Wait...');
      $.ajax({
        type: 'POST',
        url: post_url,
        data: post_data,
        dataType: 'json',
        success: function(msg) {
          console.log(msg);
          $('#messages small').fadeOut(500);
          setTimeout(function() {
            $('#messages small').html(msg.bigcom_url).fadeIn(500);
          }, 500);
          if (msg.errors.length > 0) {
            setTimeout(function() {
              $('#messages small').html(msg.errors).fadeIn(500)
            },500);
          }
        }
      }).fail(function(e){
        $('#messages small').fadeOut(500);
        setTimeout(function() {
          $('#messages small').html('Not a valid URL format').fadeIn(500);
        }, 500);
      });
    });
  });
});
