(function() {
  "use strict";
  App.Comments = {
    add_comment: function(parent_id, response_html) {
      $(response_html).insertAfter($("#js-comment-form-" + parent_id));
      this.update_comments_count();
    },
    replace_comment: function(comment_id, response_html) {
      $("#" + comment_id).replaceWith(response_html);
      App.Users.initializeAvatar();
      this.update_comments_count();
    },
    update_comments_count: function() {
      $(".js-comments-count").each(function() {
        var new_val;
        new_val = $(this).text().trim().replace(/\d+/, function(match) {
          return parseInt(match, 10) + 1;
        });
        $(this).text(new_val);
      });
    },
    display_error: function(field_with_errors, error_html) {
      $(error_html).insertAfter($("" + field_with_errors));
    },
    reset_and_hide_form: function(id) {
      var form_container, input;
      form_container = $("#js-comment-form-" + id);
      input = form_container.find("form textarea");
      input.val("");
      form_container.hide();
    },
    reset_form: function(id) {
      var input;
      input = $("#js-comment-form-" + id + " form textarea");
      input.val("");
    },
    toggle_form: function(id) {
      $("#js-comment-form-" + id).toggle();
    },
    toggle_arrow: function(id) {
      $("span#" + id + "_arrow").toggleClass("fa-minus-square").toggleClass("fa-plus-square");
    },
    initialize: function() {
      $("body").on("click", ".js-add-comment-link", function() {
        App.Comments.toggle_form($(this).data().id);
        return false;
      });

      $("body").on("click", ".js-toggle-children", function() {
        var children_container_id;
        children_container_id = ($(this).data().id) + "_children";
        $("#" + children_container_id).toggle("slow");
        App.Comments.toggle_arrow(children_container_id);
        $(this).children(".js-child-toggle").toggle();
        return false;
      });
    }
  };
}).call(this);
