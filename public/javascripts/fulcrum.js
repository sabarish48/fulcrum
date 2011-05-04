$(function() {
  $('#add_story').click(function() {
    window.Project.stories.add([{
      title: "New story", events: [], editing: true
    }]);
  });

  $('div.sortable').sortable({
    handle: '.story-title', opacity: 0.6,

    update: function(ev, ui) {
      ui.item.trigger("sortupdate", ev, ui);
    }

  });

  $('#backlog').sortable('option', 'connectWith', '#chilly_bin');
  $('#chilly_bin').sortable('option', 'connectWith', '#backlog');
});