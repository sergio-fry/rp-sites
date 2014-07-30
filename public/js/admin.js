$(function() {
  $(".site").each(function() {
    var site = $(this);
    var id = site.data("id");

    var button = $("<a href='#'>удалить</a>");

    button.click(function() {
      if(confirm("Точно хотите удалить?")) {
        $.ajax("/sites/" + id, { 
          type: "DELETE" 
        }).then(function() { window.location.reload() });
      }

      return false;
    });

    var edit_button = $("<a href='/sites/"+id+"/edit'>редактировать</a>");

    site.append(" ", edit_button);
    site.append(" ", button);
  });


  var NewSiteForm = Backbone.View.extend({
    events: {
      "submit form": "onSubmit"
    },

    template: _.template("<form method='post' action='/sites'><input type='text' name='domain' /><input type='submit' /></form>"),

    render: function() {
      this.$el.html(this.template());

      return this.$el;
    },

    onSubmit: function() {
      $.ajax("/sites", { 
        type: "POST",
        data: this.$el.find("form").serialize(),
      }).then(function() { window.location.reload() });

      return false;
    }

  });

  var new_site_form = new NewSiteForm();

  $("body").append(new_site_form.render());

});
