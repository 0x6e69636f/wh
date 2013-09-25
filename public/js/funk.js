var load_left_content = function(url){
  $('#left').load(url, function () {
    $('#file_upload_form').ajaxForm(function(){
      $('#left').load('/show/Page/files');
    });
  });
};

