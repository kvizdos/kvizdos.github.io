$(document).ready(function() {
  $('#cat-all').click(
          function(){
              $(".plugin").show(250);
              $(".web").show(250);

              $("#success").hide();
              $("#success").show(250).delay(2000).queue(function(n) {
                $(this).hide(1000); n();
              });
          });
  $('#cat-websites').click(
          function(){
              $(".plugin").hide(250);
              $(".web").show(250);

              $("#success").hide();
              $("#success").show(250).delay(2000).queue(function(n) {
                $(this).hide(1000); n();
              });
          });
          $('#cat-plugins').click(
                  function(){
                      $(".plugin").show(250);
                      $(".web").hide(250);

                      $("#success").hide();
                      $("#success").show(250).delay(2000).queue(function(n) {
                        $(this).hide(1000); n();
                      });
                  });
});
