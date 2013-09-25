var ACTIVE_DIR = '';
var ACTIVE_FILE = '';

var set_active_dir = function (dir) {
  if (dir != null) {
    // console.log("Setting Dir " + dir + " as Active Dir");
    ACTIVE_DIR = dir;
    $('#file_list_block').load('/show/File/list', {dir: dir}, function () {
      init_file_list_block_content();
    });
  }
};

var set_active_file = function (file_id) {
  if (file_id != null) {
    ACTIVE_FILE = file_id;
    load_file_preview();
    load_file_messages();
  }
};

var remove_file = function (file_id, success_cb) {
  $.ajax({
    url:'/do/File/remove',
    data:{
      file_id:file_id,
      removed:1
    },
    success:function(data,status){
      if(ACTIVE_FILE == file_id){
        set_active_file('');
      }
      set_active_dir(ACTIVE_DIR);
    }
  })
}

var init = function () {

  $('.date_input').datepicker().css('z-index', 1000);

  $('#people_page_link').on('click', function () {
    $('#center').load('/show/page/people', function () {
      init_people_page_content();
    });
  });

  $('#content').on('click', '.dir_link', function (e) {
    var back_link = ACTIVE_DIR;
    set_active_dir($(this).attr('href'));
    $('#dir_back_link').attr('href', back_link);
    e.preventDefault();
  });

  $('#content').on('click', '.file_link', function (e) {
    e.preventDefault();
    set_active_file($(this).attr('href'));
  });

  $('#content').on('click','.file_delete_icon_link', function(e){
    e.preventDefault();
    var link = $(this);
    remove_file(link.attr('href'), function(){
      link.parent('.file_list_element').get( 0 ).delete();
    });
  });


  $('#content').on('click', '.sound', function (e) {
    $('#audio').attr('src', '/do/file/get?id=' + $(this).attr('href'));
    $('#audio').get(0).play();
    e.preventDefault();
  });



  /*
   $('#content').on('click', '.sound', function (e) {
   var src= $(this).attr('href');
   $('#audio').append(
   '<source src="/do/file/get?id='+src+'" type="audio/mpeg" />'
   );
   $('#audio').get(0).play();
   console.log($('#audio'));
   e.preventDefault();
   });*/

  set_active_dir('');

  $('.menu_list_item a').on('click', function (e) {
      set_active_dir('');
      e.preventDefault();
    }
  );
};


var init_people_page_content = function () {
  $('#people_search_form').ajaxForm({
    success: function (list) {

      $('#people_search_result_block').html(list);

      $('.user_name_link').on('click', function(e){
        load_user_profile($(this).attr('href'), '#right');
        e.preventDefault();
      });

      $('.user_send_friend_request_link').on('click', function(e){
        send_friend_request($(this).attr('href'));
        e.preventDefault();
      });
    }
  });
};

var init_file_list_block_content = function () {

  $('#file_uploader_parent').attr('value', ACTIVE_DIR);
  $('#file_upload_form').ajaxForm({
    success: function () {
      load_file_list();
    }
  });

  $('#new_dir_parent').attr('value', ACTIVE_DIR);
  $('#new_dir_form').ajaxForm({
    success: function () {
      load_file_list();
    }
  });


};

var init_file_block_content = function () {

};

var load_file_preview = function () {
  $('#center').load('/show/file/preview?id=' + ACTIVE_FILE);
};

var load_file_list = function () {
  $('#file_list_block').load('/show/File/list', {dir: ACTIVE_DIR});
};

var load_file_messages = function () {
  $('#right').load('/show/file/message_list?id=' + ACTIVE_FILE, function () {
    $('#new_file_message_form').ajaxForm({
      success: function () {
        load_file_messages();
      }
    });
  });
};

var load_user_profile = function (user_id, block) {
  $(block).load('/show/people/user_profile?id='+user_id);
};

var send_friend_request = function(user_id){
  $.ajax({
    url:'/do/Friendship/send_request',
    data:{user_id:user_id},
    success:function(data){
      if(data.success){
        alert('Request Sent!')
      }else{
        alert(data.msg);
      }
    }
  })
}







