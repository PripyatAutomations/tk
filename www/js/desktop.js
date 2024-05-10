"use strict";
/*
 * Here we provide a web interface to a radio running RadOS (or maybe just one
 * that uses rigctl? ;)
 *
 * This code is definitely buggy and ugly. Feel free to change that
 */
var Connected = false;

////////////////////////////////
// Use localStorage for state //
////////////////////////////////
var Stash = localStorage;
var Session = sessionStorage;
var Windows;

// xxx:
var $trying_toast;

// Some placeholder settings
var Settings = {
   AutoSelectTimeout: 10,
   BandplanRegion: 2,
   Callsign: '*NOCALL*',
   Host: null,
   Radio: null,
   RadioConfig: null,
   View: 'main',
   WindowMode: 'windowed'
};

// Initialize Settings from localStorage, if available
if (Stash.getItem("Settings/Data") !== null) {
   let sd = Stash.getItem("Settings/Data");
   let sd_len = sd.length;

   if (sd_len > 0 && sd !== "undefined") {
      Settings = JSON.parse(Stash.getItem("Settings/Data"));
      Settings.Radio = null;
      Settings.View = 'main'
   } else
      console.log("[core] Ignoring invalid saved settings");
}

// Load saved window positions/sizes
// XXX: We should create an ID based on screen size and DPI, so that big/small screen layouts don't do wonky things...
if (Stash.getItem("Windows/Data") !== null) {
   let data = Stash.getItem("Windows/Data");

   if (data !== "undefined")
      Windows = JSON.parse(data);
}

///////////////////
// View Handling //
///////////////////
function ShowView(view) {
   if (view === "main") {
      SetBackButton('off');
   } else if (Settings.view !== undefined && Settings.view !== null) {
      SetBackButton(Settings.view);
   } else {
      SetBackButton('main');
   }
   
   // save the requested view, in case page reload is required
   Settings.View = view;

   // Refresh the title bar
   UpdateTitlebar();

   // Determine windowing mode
   if (Settings.WindowMode === undefined || Settings.WindowMode === "tabbed") {
      // Nothing yet
   } else if (Settings.WindowMode == "windowed") {
      // Hide all the active views...
      $('div.activeWindow').each(function() {
         // ... except the requested one (avoid flicker if already open)
         if ($(this).attr('id') != 'win_' + view) {
            $(this).remove();
            console.log("[ui] Closing window:" + $(this).attr('id'));
         }
      });
   }

   // Display the view
   let $html = "";
   let $sv_key = "VIEW_" + view;
   let $stashed_view = stash_fetch($sv_key);

   // Is it already loaded?
   if ($stashed_view !== undefined) {
      $html = $stashed_view;
   } else {
      // Fetch the view and stash it
      // XXX: Add a better list of these, so we can know types (smf or html)
      stash_remote($sv_key, "/views/" + view + ".hbs", 600, true, function(data) {
          if (data !== null) {
             $hh_templates[view] = Handlebars.compile($data)
             $html = Handlebars.compile($data);
          } else
             alert('I can\'t seem to find the view ' + view + ' right, now try again soon!');
      });
      
      // XXX: Add event hook to Check online state here if still KeepAlived modified-check & re-render the view
   }
   let $myDiv = jQuery('<div>', {
       id: 'wind_' + view,
       class: 'activeWindow',
       title: 'Window:' + view
   });

   // Add our new HTML to it
   $myDiv.append($html);
   $myDiv.appendTo('body');
}

function UpdateTitlebar() {
   // Do we have an Auth Cookie? If so we're probably still logged in
   let ac = Session.getItem('AuthCookie');

   if (ac !== 'null' && ac !== 'undefined' && ac.length > 0) {
      // if we aren't showing the radio choser, include the radio ID selected
      if (is_vis('div#main_menu')) {
         document.title = '[' + Settings.Callsign + '] netrig Remote online';
      } else if (typeof Settings.ActiveRadio !== 'undefined') {
         document.title = '[' + Settings.Callsign + '@' + Settings.Host + '/' + Settings.ActiveRadio + '] netrig Remote online';
      } else {
         document.title = '[' + Settings.Callsign + '@' + Settings.Host + '] netrig Remote online';
      }
   } else
      document.title = 'netrig Remote::Login';
}

function deleteAllCookies() {
    let cookies = document.cookie.split(";");

    for (var i = 0; i < cookies.length; i++) {
        let cookie = cookies[i];
        let eqPos = cookie.indexOf("=");
        let name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
        document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT";
    }
}

function TotalCleanup() {
   // dont bother cleaning up, just send API message etc
   logout(false);

   // Leave no clutter behind...
   ////////
   Stash.clear();		// Stash is just our shorter name for localStorage
   sessionStorage.clear();
   deleteAllCookies();
}

// Create a 24-hour time string, zero padded, with seconds
function ClockTime(now) {
   let hr = now.getHours();
   let min = now.getMinutes();
   let sec = now.getSeconds();
   let p_h = (hr < 10 ? "0" : "") + hr;
   let p_m = (min < 10 ? "0" : "") + min;
   let p_s = (sec < 10 ? "0" : "") + sec;
   let out = p_h + ":" + p_m + ":" + p_s;

   return out;
}

// Is selector visible?
function is_vis(selector) { if ($(selector).is(':visible')) { return true; } else { return false; } }

////////////////
// Login Bits //
////////////////
function logged_in() {
   SaveWorkspaceState();
   UpdateTitlebar();
   $('div#Login').fadeOut('fast');
   $('div#LoginModal').fadeOut('fast');
   $('div#logout').fadeIn('fast');

   // Hide the trying to login message, if present...
   if ($trying_toast !== undefined) {
      toastr.clear($trying_toast);
   }
   toastr.success("Successfully logged in as " + Settings.Callsign + "!", 'Login');

   console.log("[init]: setting timer for autoconnect in 3 seconds...");
   setTimeout(function() { 
      // startup the hamlib over websocket connection
      init_rigctl();

      // bring up the audio session
      init_webrtc();
   }, 3000);

   // Display the main menu
   ShowView('main');
}

function try_login(user, pass) {
   $('div#Login').fadeOut("slow");
   $trying_toast = toastr.info("Trying to login as " + $('input#callsign').val() + "...");

   // Send it via ajax to server and deal with the response
   let rc = $.ajax({
       url: '/cgi-bin/login.pl',
       cache: false,
       type: "POST",
       dataType: 'json',
       data: $('form#login').serialize(),
       success: function(result) {
          console.log("[login] API call returned: ", result);

          if (result.status === "OK") {
             Settings.Callsign = result.callsign.toUpperCase();
             // Save our authentication cookie to use for future requests
             Session.setItem('logged_in', result.callsign);
             Session.setItem('AuthCookie', result.token);
             Session.setItem('sip_user', result.sip_user);
             Session.setItem('sip_pass', result.sip_pass);
             Session.setItem('sip_host', result.hostname);
             Settings.Host = result.host;
             logged_in();
          } else {
             // Hide the trying to login message, if present...
             toastr.clear($trying_toast);

             // Determine the login failure cause and display an appropriate error
             if (result.Message)
                toastr.error("Login failed: " + result.status + ":" + result.Messsage);
             else
                toastr.error("Login failed: Unknown error. Contact radio admin for assistance.");
             $('div#Login').fadeIn("fast");
          }
       },
       error: function(xhr, resp, data) {
          console.log("[login] xhrRequestError: resp=" + resp + ", data=" + data)
          $('div#Login').fadeIn("fast");
          toastr.error("[login] Error connecting to login server. Try again in a minute.");
       }
   });
}

function logout(cleanup) {
   SaveWorkspaceState();
   Session.removeItem('AuthCookie');
   Session.removeItem('sip_user');
   Session.removeItem('sip_pass');
   Settings.Callsign = '*NOCALL*';
   Settings.View = null;
   Settings.ActiveRadio = 'none';
   Settings.RadioConfig = null;
   toastr.info('Reloading the page...');
   window.location.reload(false); 
}

// Save the location and status of the workspace to localstorage
function SaveWorkspaceState() {
  // Save all Settings
  stash_data("Settings", JSON.stringify(Settings), 0);
  // Save window locations & status
  if (Windows !== undefined)
     stash_data("Windows", JSON.stringify(Windows), 0);
}

function SetBackButton(target) {
   if (target === 'off') {
     $('div#goBack').attr('target', '');
     $('div#goBack').fadeOut('fast');
   } else {
     $('div#goBack').attr('target', target);
     $('div#goBack').fadeIn('fast');
   }
}

function HistoryManagerInit() {
   window.addEventListener("popstate", function(e) {
      // URL location
      let location = document.location;

      // state
      let state = e.state;
      
      // return to last state
      if (state.view == "EMAILCONTENT") {
         // stuff
      }
   });
}

function menu_redraw($state) {
   var last_val = $('button#menu').attr('value');
   $('button#menu').attr('value', $state);

   if ($state == true) {
      console.log("Opening menu");
      // XXX: regenerate the menu....
      // redraw it...
      $('div#menu').show('slow');
   } else if ($state == false) {
      console.log("Closing menu");
      $('div#menu').hide('slow');
   } else {
      alert("menu is broken");
   }
}

// guest account cannot have a password...
function ClearPasswordInput() {
   if ($('input#callsign').val() === "guest") {
      $('input#password').val('');
   }
}

function update_chromahash() {
   $('input#callsign').chromaHash({
      bars: 3, minimum: 3,
      rgbStepSize: 64,
      salt: 'abaa13a5f069225107869fb9cbf280d9'
   });
   $('input[type=password]').chromaHash({
      bars: 3, minimum: 3,
      rgbStepSize: 64,
      salt: '96555de4ddfa1e1005aac5989dd0b10e'
   });
}

//////////////////
// Core Startup //
//////////////////
// WebSocketInterface
var wsin;

$(document).ready(function() {
   HistoryManagerInit();

   // Hide the loading screen, as if we've made it this far the page is running...
   $('div#loadingModal').fadeOut('slow', function() { $('div#loading').hide(0); });

   // XXX: Open our websocket connection
   // wsin = OpenWSInterface();

   // XXX: Confirm our connection to the server before hiding offline message
   $('div#offline').hide('fast');

   // Configure toastr notifications
   toastr.options.showDuration = 10;
   toastr.options.closeButton = true;
   toastr.options.escapeHtml = true;
   toastr.options.closeMethod = 'fadeOut';
   toastr.options.closeDuration = 300;
   toastr.options.closeEasing = 'swing';
   toastr.options.progressBar = true;

   // Are we logged in?
   let ac = Session.getItem('AuthCookie');

   // If the user clicks anywhere outside the select box, then close all select boxes:
   document.addEventListener("click", closeAllSelect);

   if (ac !== null && ac !== undefined && ac.length > 0) {
      // Hide the login dialog if it has somehow reappeared
      if (is_vis('div#LoginModal')) $('div#LoginModal').fadeOut('fast', function() { $('div#Login').hide(0); });

      // Show the logout button, if it's been lost
      if (!is_vis('div#logout')) $('div#logout').fadeIn('fast');

      if (Settings.View === undefined || Settings.View === null || Settings.View === 'main') {
         ShowView('main');
      } else {
         ShowView(Settings.View);
      }
   } else {
      // We aren't logged in, so try to resolve that
      $('div#Login').fadeIn('fast', function() { $('div#LoginModal').fadeIn('fast'); });
   }
 
   /////////////////////
   // Login form bits //
   /////////////////////
   // Add color bars to login fields to help users know they're typing their credentials correctly
   // -- Make sure they get updated if autofill happens...
   setTimeout(function() { 
      $('input:-webkit-autofill, input:autofill').each(function() {
         var elem = $(this);
         if ($(elem).val() !== "") {
            $(elem).change();
         }
      })
   }, 1000);
   update_chromahash();
   // Handle login form input
   $('form#login').submit(function(e) {
      // Don't submit through POST
      e.preventDefault();

      // guest login won't have a password, just in case autofill adds one
      if ($('input#callsign').val() === "guest") {
         $('input#password').val('');
      }

      // Attempt login
      try_login($('input#callsign').val().toUpperCase, $('input#password').val());
      return false;
   });

   // Bind handlers to the password input to prevent entry for guest users
   $('input#password').bind('keyup', ClearPasswordInput);
   $('input#password').bind('blur', ClearPasswordInput);


   // Handle guest logins by clearing password and logging in
   $('a#guestlogin').click(function() {
      $('input#callsign').val('guest');
      $('input#password').val('');

      // Fire event for Chroma Hash updates
      $('input#callsign, input#password').change();
      // Then submit the form
      $('form#login').submit();
   });

   $('input#callsign').blur(function() {
       // Clear password field if guest username entered
      if ($(this).val() === "guest") {
          ClearPasswordInput();
      }
   });

   ////////////////////
   // Confirm Logout //
   ////////////////////
   $('div#logout').click(function(e) {
      e.preventDefault();
      var targetUrl = $(this).attr("href");

      $("#logout_confirm").dialog({
         autoOpen: true,
         modal: true,
         buttons : {
          "Confirm" : function() {
             logout(true);
          },
          "Cancel" : function() {
            $(this).dialog("close");
          }
        }
      });
   });

   $('div#goBack').click(function(e) {
      if ($(this).attr('target') !== undefined && $(this).attr('target').length > 0) {
         let target = $(this).attr('target');

         console.log('[ui] goBack button clicked, opening target: ' + target);
         SaveWorkspaceState();
         ShowView(target);
      } else if ($(this).attr('href') !== undefined && $(this).attr('href').length > 0) {
         let targetUrl = $(this).attr("href");
         console.log('[ui] goBack button clicked, opening href: ' + targetUrl);
         SaveWorkspaceState();
         window.location.href = targetUrl;
      }
   });

   // Add support for <FREQUENCY> tag
   gui_frequency_tag_init();

   // Is the user logged in?
   var $logged_in = Session.getItem('logged_in');
   var $sess_tok = Session.getItem('AuthCookie');
   if (($logged_in !== undefined && $logged_in != null) &&
       ($sess_tok !== undefined && $sess_tok != null)) {
       logged_in();
       console.log("logged_in: " + $logged_in + " / " + $sess_tok);
   } else {
       console.log("Please login to continue!");
   }
});

// based on https://www.w3schools.com/howto/howto_custom_select.asp
// A function that will close all select boxes in the document,
// except the current select box:
function closeAllSelect(elmnt) {
   let x, y, i, xl, yl, arrNo = [];
   x = document.getElementsByClassName("select-items");
   y = document.getElementsByClassName("select-selected");
   xl = x.length;
   yl = y.length;

   for (i = 0; i < yl; i++) {
      if (elmnt == y[i]) {
        arrNo.push(i)
      } else {
        y[i].classList.remove("select-arrow-active");
      }
   }

   for (i = 0; i < xl; i++) {
      if (arrNo.indexOf(i)) {
        x[i].classList.add("select-hide");
      }
   }
}

function init_rigctl() {
   //////////////////////
   // rigctl websocket //
   //////////////////////
   // create a ws/wss url from current http url for the websocket connection...
   var loc = window.location, new_uri;
   if (loc.protocol === "https:") {
       new_uri = "wss:";
   } else {
       new_uri = "ws:";
   }
   new_uri += "//" + loc.host;
   new_uri += "/rigctl/ws";
   const rigctl_ws = new WebSocket(new_uri, [
      "protocolOne",
      "protocolTwo",
   ]);

   rigctl_ws.onopen = (event) => {
      rigctl_ws.send("CONNECT");
   };

   rigctl_ws.onmessage = (event) => {
      console.log("rigctl status: ", event.data);
   };
   console.log("[rigctl] Connected!");
   toastr.info("rigctl connection established to radio0");
   return rigctl_ws;
}

/*
 * Here we manage our WebRTC audio channels (inbound and outbound)
 *
 * Ideally, these channels should be error tolerant and reconnect automatically (someday? ;)
 */
var sip_ua;

function init_webrtc() {
  var loc = window.location, pbx_uri;
  if (loc.protocol === "https:") {
      pbx_uri = "wss:";
  } else {
      pbx_uri = "ws:";
  }
  pbx_uri += "//" + loc.host;
  pbx_uri += "/pbx/ws";

  var socket = new JsSIP.WebSocketInterface(pbx_uri);
  var ssip_user = Session.getItem("sip_user");
  var ssip_host = Session.getItem("sip_host");
  var ssip_pass = Session.getItem("sip_pass");
  var sip_user = "sip:" + ssip_user + "@" + ssip_host;
  var configuration = {
    sockets  : [ socket ],
    uri      : sip_user,
    password : ssip_pass
  };

  sip_ua = new JsSIP.UA(configuration);
  sip_ua.on('connected', function(e) {
      console.log("[webrtc] Connected to PBX!");
      toastr.info("pbx connected for radio0");
  });
  sip_ua.start();

  // Register callbacks to desired call events
  var eventHandlers = {
    'progress': function(e) {
      console.log('call is in progress');
    },
    'failed': function(e) {
      console.log('call failed with cause: '+ e.data.cause);
    },
    'ended': function(e) {
      console.log('call ended with cause: '+ e.data.cause);
    },
    'confirmed': function(e) {
      console.log('call confirmed');
    }
  };

  var options = {
    'eventHandlers'    : eventHandlers,
    'mediaConstraints' : { 'audio': true, 'video': true }
  };

//  var session = sip_ua.call('sip:bob@example.com', options);
}
