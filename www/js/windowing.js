/*
 * Support some basic windowing in two modes:
 *
 *  Tiling - Multiple windows allowed on screen in grid layout
 *  Tabbed - Show only one window a time, with a tab-strip to quickly switch
 * Overlap - 'unmanaged' mode (until we add the other two)
 */
var $wm = {
   mode: 'overlap',
   max_windows: 10		// limit how windows in overlap way?
};
var $wins = new Array();

var winddate = new Date();
var $win_start = Math.round(winddate.getTime() / 1000);

// Window object we duplicate
const $rpWindow = {
   // Metadata
   description: null,
   name: 'untitled',
   id: null,
   template: null,

   // Window position and size
   height: 0,
   width: 0,
   x_pos: 0,
   y_pos: 0
};

String.prototype.hashCode = function() {
  var hash = 0,
    i, chr;
  if (this.length === 0) return hash;
  for (i = 0; i < this.length; i++) {
    chr = this.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
}

function generate_window_uuid($name) {
   var $fullval = $name + "/" + $win_start;
   var uuid = $fullval.hashCode();
   console.log("Generated new window uuid for window: " + $name + " = " + uuid);
   return uuid;
}

function show_window($name, $style) {
   // Does the window already exist?
   var $win = find_window($name);

   if ($win != undefined && $win != null) {
      console.log("Showing hidden window: " + $name + "(" + $style + ")");
      $win.show();
   } else
      return null;
}

function new_window($name, $url, $style) {
   // clone the default window object
   $win = Object.create($rpWindow);
   $win.name = $name;
   $win.id = generate_window_uuid($name);

   // XXX: Here we need to check compiled cache
   // XXX: Then check Stash and compile into cache
   // XXX: Nope? We'll have to fetch it from http and cache
   var $newDiv = template_fetch($name, '/views/' + $name + '.hbs', null, null);
   console.log("Showing new window: " + $name + "(" + $style + ")");
   if (typeof $newDiv === undefined || $newDiv == null) {
      console.log("Requested window " + $name + " can't be serviced by any active view. Trying to fetch it...");
//      $newDiv = template_fetch($name, '/views/' + $name + '.hbs', null, null);

     // XXX
      if (typeof $newDiv === undefined || $newDiv == null) {
         alert("The application cannot continue. The view named " + $name + " can't be found.");
         return false;
      }
   }
   var html = $newDiv();

   var $newwin;

   // XXX: Create a new window with the object
   if ($style == "main") {
      // 'main' is special
      $newwin = '<div class="main">' + html + '</div>';
   } else if ($style == "modal") {
      // modal windows 
      $newwin = '<div class="modal window">' + html + '</div>';
   } else {
      $newwin = '<div class="window">' + html + '</div>';
   }
   $('div#content').append($newwin);
   update_customtags();
}

function hide_window($name) {
   var $win = find_window($name);
   $.each($win, function() { $($(this).id).hide('fast');  });
}

// Returns an array of one or more windows
function find_window($name = null) {
   if ($name == null || $name == '*') {
      var $windows = 0;
      // Return an array of all windows
      $('div#win_*').each(function(index) {
         $wins.push($(this));
         $windows++;
      });

      if ($windows == 0)
         return $wins;
   } else {
      $('div#win_' + $name).each(function(index) {
         $wins.push($(this));
         $windows++;
      });
      if ($wins != undefined && $wins != null && $wins.length > 0)
         return $wins;
   }
   return null;
}

function close_window($name) {
   var $win = find_window($name);

//   if ($win != undefined && $win != null) {
      // Window found
      var mydiv = "div#" + $name;
      $(mydiv).hide();
      // XXX: Call destructor
      // XXX: Discard the DOM element and it's children
//   }
}

//////////////////////
// Window Placement //
//////////////////////

// Try to fit a window without overlaps
function rearrange_windows($name, $new_width, $new_height, $preferred_x, $preferred_y) {
}

// Move a window around the grid (tiling) layout
function move_window($name, $new_x, $new_y) {
   // XXX: Is there a window here already?
   // - Yes? Try to figure out rearranging to fit our window
   // -- No? Move our window
}

// Resize the window in grid (tiling) layout
function resize_window($name, $new_width, $new_height) {
   // Does this cause overlap?
   // - Yes? Try to re-arrange
   // -- No? Resize the window
}
