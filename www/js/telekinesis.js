//////////////////////////////////////////////////////////
// www/js/telekinesis.js: Core network/UI functionality //
//
// Here we deal with:
//	* Fetch assets
//	* Connect websocket
//	* Authentication
//	* Basic WebUI
//////////////////////////////////////////////////////////

// global state
var gState = {
   active_rig: null,
   online: true,
   loaded: false,
   logged_in: false,
   menu_open: false,
   server: null,
   user: null
};

var $trying_toast;


function toggle_online(force) {
    // if not specified, use inverse of current value
    if (typeof force === 'undefined') {
        force = !gState.online;
    }
    gState.online = force;

    console.log("[" + gState.online + "] state forced by button");
    var si = $('#s_online');

    // Add or remove the CSS class accordingly for each element
    si.each(function() {
        if (force) {
            $(this).addClass('online');
        } else {
            $(this).removeClass('online');
        }
    });

    update_status();
}

function update_status() {
   if (gState.online) {
      var $rig = gState.active_rig;
      var $user = gState.user;

      if ($user !== null) {
         $user = $user + '@';
      } else {
         $user = '';
      }

      if ($rig !== null) {
         $rig = '/' + $rig;
      } else {
         $rig = '';
      }

      document.title = "Telekinesis connected " + $user + gState.server + $rig;

      if (gState.logged_in) {
         $('#s_online').text('READY');
      } else {
         $('#s_online').text('ONLINE');
      }
   } else {
      document.title = "Telekinesis (re)connecting " + $user + gState.server;
      $('#s_online').text('OFFLINE');
   }
   $('.s_server').text('Server: ' + gState.server);
}

function hide_login() {
   $('div#login').hide('slow');
}

function do_login() {
   var $ok = false;
   var $reason = null;

   var $user = $('div#login input#callsign').val().trim();
   var $pass = $('div#login input#pass').val().trim();

   if ($user === "" || $pass === "") {
      console.log("You must specify a callsign and password!");
      toastr["error"]("You must specify a callsign and password!", "ERROR!");
      $('div#login input#callsign').focus();
      return;
   }

   // XXX: for testing! this doesn't actually login!
   if ($user === "TEST" && $pass === "test") {
      $ok = true;
   }

   if ($ok) {
      gState.user = $user;
      hide_login();
      console.log("Login as '" + $user + "' success!");
      toastr["success"]("Login to server " + gState.server + " succesful", "Login Success!");
   } else {
      console.log("Login failed! Reason: " + $reason);
      toastr["error"]("Login to server " + gState.server + " failed", "Login failed!");
   }
}

var $ch;

$(document).ready(function() {
   gState.loaded = true;

   // parse request URL and store it
   var host = window.location.hostname;
   var port = window.location.port;
   var protocol = window.location.protocol;

   toastr.options = {
     "closeButton": true,
     "debug": false,
     "newestOnTop": false,
     "progressBar": true,
     "positionClass": "toast-top-right",
     "preventDuplicates": false,
     "onclick": null,
     "showDuration": "300",
     "hideDuration": "1000",
     "timeOut": "5000",
     "extendedTimeOut": "1000",
     "showEasing": "swing",
     "hideEasing": "linear",
     "showMethod": "fadeIn",
     "hideMethod": "fadeOut"
   }

   if (port === '') {
       // Set the port based on the protocol
       if (protocol === 'http:') {
           port = '80';
       } else if (protocol === 'https:') {
           port = '443';
       }
   }
   toastr.info('Here you will see aftermath of my experiments....', 'Good luck!')

   gState.server = host + ":" + port;
   // set online mode and request connecting...
   toggle_online(true);

//////////////

   update_status();

//   $ch = $("input:password").chromaHash( { bars: 3, minimum: 2, salt: "8bec46d2ca8e82070ef6fdaf5d9c4bcb" });

   // Hide login dialog early, if already logged in
   if (gState.logged_in) {
      hide_login();
   }

   //////////////////////////
   // Handle Login Request //
   //////////////////////////
   $('#login_form').submit(function(e) {
       e.preventDefault();
       do_login();
   });

   //////////////////////////////////
   // Handle Online/Offline button //
   //////////////////////////////////
   $('#s_online').on('click', function() {
      alert('toggle online');
      toggle_online();
   });

   //////////////
   // temporary: test/nettest login links in login box
   $('span#login_test').click(function() {
      $('input#callsign').val('TEST');
      $('input#pass').val('test');
      do_login();
   });
   $('span#login_nettest').click(function() {
      $('input#callsign').val('NETTEST');
      $('input#pass').val('natasha');
      do_login();
   });

   $('input#callsign').keyup(function() {
      $(this).val( $(this).val().toUpperCase() );
   });

//   $('input#pass').keyup(function() {
//      XXX: Hide if less than 3 characters
//      if ($(this).val().length <= 3) {
//         // XXX: unattach $ch from $(input:password) entities
//      }
//   });

   //////////////////////////////////////////////////////
   // Handle tab/shift-tab to wrap around login dialog //
   //////////////////////////////////////////////////////
   // Attach keydown event handler to input[type=reset]
   $('input[type=reset]').on('keydown', function(e) {
     // Check if the Tab key is pressed
     if (e.which === 9 && !e.shiftKey) { // Tab key (without Shift)
        e.preventDefault();
        // Focus on the element with tabindex="1"
        $('[tabindex="1"]').focus();
     }
   });

   // Attach keydown event handler to input#callsign
   $('#callsign').on('keydown', function(e) {
      // Check if Shift+Tab is pressed
      if (e.which === 9 && e.shiftKey) { // Shift+Tab
         e.preventDefault();
         // Focus on the input[type=reset] element
         $('input[type=reset]').focus();
      }
   });

/*
   $(document).on('keypress', function(e) {
      console.log("keypress: ", e);
   });
   $(document).on('keydown', function(e) {
      console.log("keydown: ", e);
   });
   $(document).on('keyup', function(e) {
      console.log("keyup: ", e);
   });
*/

   $('#settings').click(function() {
      if (gState.menu_open) {
         console.log("menu hide");
         $('div#settings_menu').hide('slow');
      } else {
         console.log("menu show");
         $('div#settings_menu').show('slow');
      }
   });
});
