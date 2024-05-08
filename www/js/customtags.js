function update_customtags() {
   ///////////////////////////////
   // Implement viewref 'links' //
   ///////////////////////////////
   $('viewref').prop("onclick", null).attr("onclick", null);
   $('viewref').on('click', function() {
      var view = $(this).attr('name');
      var url = $(this).attr('url');
      new_window(view, url, view);
      show_window(view, view);
   });
}

////////////////////////////
// Make TEXT fields nicer //
////////////////////////////
function gui_frequency_tag_redraw(instance, editing = false) {
      let myHtml = null;

      // Clear out the inner HTML
      $(tag).html('');

      // First click goes into editing mode, second click toggles back to display mode
      if ($(tag).attr('editing') === true) {
         $(tag).attr('editing', false);
         myHtml =
            '<span class="frequency_display">' +
            '</span>';
      } else {
        $(tag).attr('editing', true);
         myHtml =
            '<span class="frequency_edit">' +
            '</span>';
      }
      // Replace the HTML with our newly rendered HTML
      $(tag).html(myHtml);
}

// Attach events, etc to the FREQUENCY tag
function gui_frequency_tag_init() {
   console.log("Adding FREQUENCY tag (widget) support to browser...");
   // IE is stupid...
   document.createElement('frequency');

   $('frequency').on('click', function(e){
      // Stop sending the event downward
      e.preventDefault();
      console.log('FREQUENCY#' + $(this).attr('id') + ' clicked');

      // Save our value
      let myVal = $(this).val();

      // Redraw the element
      gui_frequency_tag_redraw($(this));
   });

   $('frequency').on('blur', function(e) {
      $(this).attr('editing', false);

      if ($.trim(this.value) == '') {  
         this.value = (this.defaultValue ? this.defaultValue : '');
      } else {
         // XXX:
         alert('[blur] new frequency: ' + this.value);
      }
      gui_frequency_tag_redraw($(this));
   });

   $('frequency').on('keypress', function(e) {
      if (e.keyCode == '13') {
         $(this).attr('editing', false);

         if ($.trim(this.value) == ''){  
           this.value = (this.defaultValue ? this.defaultValue : '');  
         } else {
           // XXX:
         alert('[keypress] new frequency: ' + this.value);
         }
      }
      gui_frequency_tag_redraw($(this));
   });
   console.log("[frequency] Tag added!");
}

$(document).on('load', function() {
   update_customtags();
});
