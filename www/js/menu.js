"use strict";
/*
 * menu.js:
 *	Support for rendering menus from a JSON dataset
 *
 *	This is used to render main menu, configuration pages, and admin panel, etc.
 *
 * Features:
 *	Auto-timeout after selection
 *	JSON based menus
 *	Slightly caching (60 seconds) of remote menus to improve performance
 *	innerHtml is cached as well for performance
 */

///////////////////////////////////
// Template for new Menu objects //
///////////////////////////////////
var MenuView = {
   Name: null,

   // Use the generic view unless you have your own...
   template: 'views/menu.html',

   // Support for timeout-based auto-submission of the form
   auto_submit_last_state: '',
   auto_submit_time_left: 0,
   auto_submit_timer: null,

   // Store retrieved menu data
   remoteData: null,
   remoteDataLifetime: null,

   // Our most recently rendered HTML...
   innerHtml: null,

   /////////////
   // Methods //
   /////////////
   create: function(name) {
      // Create a blank, new Menu object to return
      let newMenu = Object.assign({ }, this);
      newMenu.Name = name;
      console.log('[menu] creating new menu ' + newMenu.Name);
      return newMenu;
   },

   store_data: function(data) {
       this.remoteData = data;
       this.remoteDataLifetime = Math.round((new Date()).getTime() / 1000) + 60;
       return this.remoteData;
   },

   fetch: function(Menu) {
      if (Menu.Name === undefined || Menu.Name === null) {
         alert('Menu.fetch() called with null/undefined menu name, this is a bug. Please report it');
         return false;
      }

      let ts = Math.round((new Date()).getTime() / 1000);
      let menu_url = 'data/menu_' + Menu.Name + '.json';

      console.log('[menu] fetch(' + Menu.Name + ') getting ' + menu_url + '...');

      let rc = $.ajax({
          url: menu_url,
          async: false,
          cache: false,
          type: 'GET',
          dataType: 'json',

          // Pass along our AuthCookie, in case this is a private instance
          data: JSON.stringify({ 'AuthCookie': Session.getItem('AuthCookie') }),
          success: function(result) {
             if (result.Status == 'FAILURE') {
                // Determine the failure cause and display an appropriate error
                if (result.Message)
                   toastr.error('menu_fetch(' + Menu.Name + ') failed: ' + result.Messsage);
                else
                   toastr.error('menu_fetch(' + Menu.Name + ') failed: Unknown error. Contact radio admin for assistance.');
                return false;
             } else {
                Menu.store_data(result);
                console.log('[menu] menu: ' + Menu.Name + ' server response: ', Menu.remoteData, " expires in ", Menu.remoteDataLifetime - ts, " seconds");
                $('div#main_menu').fadeIn('fast');
                return result;
             }
          },
          error: function(xhr, resp, data) {
             console.log('[menu] fetch(' + Menu.Name + 'ERROR: resp=' + resp + ', data=' + data)
             $('div#main_menu').fadeIn('fast');
             toastr.error('menu_fetch(' + Menu.Name + ') Error connecting to remote server. Try again in a minute.');
             return false;
          }
      });
   },

   show: function(Menu) {
      let ts = Math.round((new Date()).getTime() / 1000);

      // Fetch json if missing or stale...
      if (this.remoteData == undefined || this.remoteData === null || this.remoteDataLifetime <= ts) {
         // clear the innerHtml, so that it's regenerated below...
         alert("Invalid call sequence");
         Menu.innerHtml = null;
         Menu.fetch(Menu);
      }

      // only regenerate from json if necessary (see above)
      if (Menu.innerHtml === null) {
         // XXX: We should copy div#menu_template and modify it
         // XXX: Then show() and hide() as needed...
         // Start our innerHtml...
         let $html = '<div id="menu_' + this.Name + '"><table>';

         // Walk the menu data, emitting HTML as we go
         $.each(Menu.remoteData.Menu, function(index, value) {
            // Is this entry disabled?
            let disabled = '';

            if (Menu.remoteData.Menu[index].Disabled == true)
               disabled = ' disabled';

            // create the radioConfig section of Settings...
            if (index.match(/^radio[0-9]+/) != null) {
//               Settings.RadioConfig[index] = Menu.remoteData.Menu[index];
            } else {
               console.log("skipping index " + index);
            }

            $html = $html +
               '<tr><td><input type="radio" name="menu_choice" value="' + index + '" id="menu_choice_' + index + '"' + disabled + '>' +
               '<label for="menu_choice_' + index + '">' + index +
               '</label></input></td><td>' + Menu.remoteData.Menu[index].ShortDescription +
               '</td></tr>';
         });
         $html = $html + '</table></div>';
         Menu.innerHtml = $html;
         console.log('[menu] parsing menu ' + Menu.Name + ' generated ' + $html.length + ' bytes of HTML:' + $html);
      }

      UpdateTitlebar('menu/' + Menu.Name);

      // Main menu doesn't have a back button...
      if (Menu.Name.match(/^main/))
         SetBackButton('off');
      else
         SetBackButton('on');

      // remove old instances, if they exist
      $('div#menu_' + Menu.Name).remove();
      // Show it...
      $('div#menu_items').append(Menu.innerHtml).show();

      // Bind events and apply jquery
      menu_init_gui(Menu);
   },

   hide: function(Menu) {
      $('div.menu_' + Menu.Name).remove();
      Menu.innerHtml = null;
   }
}

/*
 * Hook up the eventing stuff
 */
// XXX: This needs a bit of work to match up with the above...
function menu_init_gui(Menu) {
   //////////////////
   // menu timeout //
   //////////////////
   $("input[name='menu_choice']").change(function(x) {
      let new_val = $("input[name='menu_choice']:checked").val();
      console.log('[menu] ' + Menu.Name + ' got selection: ' + new_val + ' starting auto-select timeout...');
      Menu.auto_submit_last_state = new_val;

      // Only allow one timer to be going
      if (Menu.auto_submit_timer !== null) {
         clearInterval(Menu.auto_submit_timer);
         Menu.auto_submit_timer = null;
      }

      Menu.auto_submit_time_left = Settings.AutoSelectTimeout;

      // create the periodic timer, which will tick until we stop it...
      Menu.auto_submit_timer = window.setInterval(function() {
         // Time remaining? Update the counter
         if (Menu.auto_submit_time_left-- > 1) {
            // Update the countdown display
            $('span#auto_submit_radio').html(Menu.auto_submit_last_state);
            $('span#auto_submit_time_left').html(Menu.auto_submit_time_left);
         } else { // auto select timeout has ended
            $('span#auto_submit_countdown').fadeOut('fast');
            let cur_val = $("input[name='menu_choice']:checked").val();

            // Has the state changed since last user selection?
            if (cur_val === Menu.auto_submit_last_state) {
               console.log('[main_menu] ' + Menu.Name + 'auto select timeout - chosing ' + cur_val + ' automatically!');

               // Clear the timer, if it got saved...
               if (Menu.auto_submit_timer !== null) {
                  clearInterval(Menu.auto_submit_timer);
                  Menu.auto_submit_timer = null;
                  $('span#auto_submit_countdown').fadeOut('fast');
               }

               // Submit the form
               $('form#main_menu').submit();
            }
         }
      }, 1000);

      // display the countdown block
      $('span#auto_submit_radio').html(Menu.auto_submit_last_state);
      $('span#auto_submit_time_left').html(Menu.auto_submit_time_left);
      $('span#auto_submit_countdown').fadeIn('slow');
   });

   $('input[type=reset]').click(function() {
      // Clear the timer
      if (Menu.auto_submit_timer !== null) {
         clearInterval(Menu.auto_submit_timer);
         Menu.auto_submit_timer = null;
         $('span#auto_submit_countdown').fadeOut('fast');
      }
   });

   // user has made a choice and clicked submit
   $('form#main_menu').submit(function(e) {
      // stop form submission, since this isn't a real form...
      e.preventDefault();

      // Confirm a selection has been made
      let new_val = $("input[name='menu_choice']:checked").val();

      // Clear auto-submit timer, if it exists...
      if (Menu.auto_submit_timer !== null) {
         clearInterval(Menu.auto_submit_timer);
         Menu.auto_submit_timer = null;
         $('span#auto_submit_countdown').fadeOut('fast');
      }

      // XXX: Confirm user is allowed to access this menu item
      // if (!has_privilege(Menu.item().privileges_needed)) {
      //    alert('You do not have privileges to do that!');
      //   return false;
      // }

      console.log('[menu] ' + Menu.Name + ' - User selected item ' + new_val + ', loading view!');

      // XXX: Here we should validate the result before it's returned below
      // Save radio configuration
      Settings.ActiveRadio = new_val;

      // Does this radio have a default view set?
      if (Menu.remoteData.Menu[new_val].View !== undefined) {
         let view = Menu.remoteData.Menu[new_val].View;
         ShowView(view);
         radio_init(new_val);
      } else {
         // XXX: Present RadioViewChoser
         alert('No default view is configured for radio ' + new_val + ', so we cannot display it!');
      }
      return false;
   });
}
