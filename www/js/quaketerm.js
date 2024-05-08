$(document).ready(function() {
   $(window).scroll(function() {
      $('.tilda').each(function() {
         $(this).css({top: $('body').prop('scrollTop')});
      });
   });

   String.prototype.strip = function(char) {
       return this.replace(new RegExp("^" + char + "*"), '').
           replace(new RegExp(char + "*$"), '');
   }

   $.extend_if_has = function(desc, source, array) {
       for (var i=array.length;i--;) {
           if (typeof source[array[i]] != 'undefined') {
               desc[array[i]] = source[array[i]];
           }
       }
       return desc;
   };

   (function($) {
       $.fn.tilda = function(eval, options) {
           if ($('body').data('tilda')) {
               return $('body').data('tilda').terminal;
           }
           this.addClass('tilda');
           options = options || {};
           eval = eval || function(command, term) {
               term.echo("you don't set eval for tilda");
           };
           var settings = {
               prompt: 'tk> ',
               name: 'telekinesis',
               height: 200,
               enabled: false,
               greetings: 'Welcome to telekinesis!\nHere you can do basic commands, such as help.',
               keypress: function(e) {
                   // ` or ~
                   if ((e.which == 96 || e.which == 126)) {
                      return false;
                   }
               }
           };
           if (options) {
               $.extend(settings, options);
           }
           this.append('<div class="td"></div>');
           var self = this;
           self.terminal = this.find('.td').terminal(eval, settings);
           var focus = false;
           $(document.documentElement).keypress(function(e) {
               // ` or ~
               if ((e.which == 96 || e.which == 126)) {
                   self.slideToggle('fast');
                   self.terminal.focus(focus = !focus);
                   self.terminal.attr({
                       scrollTop: self.terminal.attr("scrollHeight")
                   });
               }
           });
           $('body').data('tilda', this);
           this.hide();
           return self;
       };
   })(jQuery);

   $('#tilda').tilda(function(command, terminal) {
       terminal.echo('you type command "' + command + '"');
   });
});
