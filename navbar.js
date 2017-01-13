$(document).ready(function() {
  $('.container').fadeIn(1000);

  $('#navbutton').click(
          function(){
              $("#navbutton").hide(250);
              $("#navbar").show(250);
          });

  $('#exitbutton').click(
          function(){
              $("#navbutton").show(250);
              $("#navbar").hide(250);
          });

});
