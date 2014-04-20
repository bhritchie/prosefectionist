// Generated by CoffeeScript 1.6.3
(function() {
  var commentform, postid;

  postid = $('#postidinput').val();

  commentform = "<form id=\"leavecomment\" action=\"/inpagecomment/" + postid + "\" method=\"post\">";

  if (document.getElementById('postadmininput')) {
    commentform += "<input id=\"postadmininput\" type=\"hidden\" name=\"admin\" value=\"true\"><input type=\"hidden\" id=\"namefield\" name=\"name\" value=\"admin\"><p><label id=\"commentlabel\" for=\"commentfield\">Commenting as admin:</label></p>";
  } else {
    commentform += "<input id=\"postadmininput\" type=\"hidden\" name=\"admin\" value=\"false\"><p><label id=\"namelabel\" for=\"namefield\">Name (required):</label></p><p><input id=\"namefield\" type=\"text\" name=\"name\"></p><p><label id=\"commentlabel\" for=\"commentfield\">Comment (required):</label></p>";
  }

  commentform += "<p><textarea id=\"commentfield\" rows=\"5\" cols=\"52\" name=\"comment\"></textarea></p><p><input id=\"commentsubmit\" type=\"submit\" name=\"Save\" value=\"Save Comment\"></p></form>";

  $('#commentform').html(commentform);

  $('#commentsubmit').click(function(event) {
    event.preventDefault();
    if (!$('#namefield').val()) {
      $('#namelabel').addClass('validationalert');
    } else {
      $('#namelabel').removeClass('validationalert');
    }
    if (!$('#commentfield').val()) {
      $('#commentlabel').addClass('validationalert');
    } else {
      $('#commentlabel').removeClass('validationalert');
    }
    if (!$('#namefield').val() || !$('#commentfield').val()) {
      return false;
    } else {
      this.disabled = true;
      $('.newcomment').removeClass('newcomment');
      $.post(this.form.action, $(this.form).serialize(), function(data) {
        $('#comments').append("<div class=\"comment hidden\"><p class=\"commenter newcomment\">" + data.name + " at " + data.time + " on " + data.day + ":</p><p class=\"commentbody newcomment\">" + data.comment + "</p></div>");
        return $('.comment.hidden').fadeIn('slow', function() {
          return $(this).removeClass('hidden');
        });
      });
      $('#namefield').val('');
      $('#commentfield').val('');
      return this.disabled = false;
    }
  });

}).call(this);
