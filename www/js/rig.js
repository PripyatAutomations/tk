"use strict";
/////////////////////////////////////////////////////
// This should contain stuff generic to all radios //
/////////////////////////////////////////////////////
// Set up things to a known state at "power on"
function SetInitialUIState() {
   let CurrentVFO = null;
   if (Settings.Callsign.toUpperCase() === "GUEST") {
      $('input#Settings_Callsign').val("*Listener*");

      // Set this for convenience of the GUI, to alert the user before waiting
      // for a round trip. Use has_privilege() on server instead to enforce
      Settings.ListenOnly = true;
   } else {
      $('input#Settings_Callsign').val(Settings.Callsign);
   }
   $('span#SettingsLoading').hide();

   // temporarily save the active VFO as RecallVFO will change it below...
   if (Settings.ActiveRadio !== undefined && Settings.ActiveRadio === null &&
      Settings.RadioConfig !== undefined && Settings.RadioConfig === null) {
      CurrentVFO = GetActiveRadio().ActiveVFO;
   } else
     CurrentVFO = 'A';

   // Update the VFO displays
   RecallVFO('A');
   RecallVFO('B');

   // Switch back to the active VFO from saved settings...
   SetActiveVFO(CurrentVFO);
}

// Update the status area of display
function UpdateStatus() {
   console.log("[ui] UpdateStatus.");
}

// Redraw the VFO knob and display(s)
function RefreshVFOs() {
   console.log("[ui] RefreshVFOs.");
}

// returns the Active radio structure or null, if not valid
function GetActiveRadio() {
   if (Settings.ActiveRadio === undefined || Settings.ActiveRadio === null) {
      console.log("[ui] wtf? Settings.ActiveConfig is null");
      return null;
   }

   if (Settings.RadioConfig === undefined || Settings.RadioConfig === null) {
      console.log("[ui] wtf? Settings.RadioConfig is null");
      return null;
   }

   return Settings.RadioConfig[Settings.ActiveRadio];
}

function RecallVFO(vfo) {
   let r = GetActiveRadio();

   if (r === null) {
      return null;
   }

   if (vfo === 'A') {
      $('select#CAT_band').val(r.VFO_A_Band);
      $('select#CAT_mode').val(r.VFO_A_Mode);
      $('select#CAT_step').val(r.VFO_A_Step);
      $('select#CAT_agc').val(r.VFO_A_AGC_Mode);
      $('input#vfo_freq_a').val(r.VFO_A_Freq);
   } else if (vfo === 'B') {
      $('select#CAT_band').val(r.VFO_B_Band);
      $('select#CAT_mode').val(r.VFO_B_Mode);
      $('select#CAT_step').val(r.VFO_B_Step);
      $('select#CAT_agc').val(r.VFO_B_AGC_Mode);
      $('input#vfo_freq_b').val(r.VFO_B_Freq);
   }

   r.ActiveVFO = vfo;
   RefreshVFOs();
}

function SetActiveVFO(vfo, edit = false) {
   let newVFO = vfo.toUpperCase().trim();
   console.log("[" + Settings.ActiveRadio + "] Activating VFO " + newVFO);

   if (newVFO === 'A') {
      $('div#VFO_B').removeClass('ActiveVFO');
      $('div#VFO_A').addClass('ActiveVFO');
      if (edit === true)
         $('div#VFO_A').find('frequency').click();
   } else if (newVFO === 'B') {
      $('div#VFO_A').removeClass('ActiveVFO');
      $('div#VFO_B').addClass('ActiveVFO');
      if (edit === true)
         $('div#VFO_B').find('frequency').click();
   } else
      alert("SetActiveVFO(" + vfo + ") is invalid VFO selection");

   if (GetActiveRadio() !== null) {
      GetActiveRadio().ActiveVFO = newVFO;
      RecallVFO(GetActiveRadio().ActiveVFO);
   } else
      console.log("GetActiveRadio() returns NULL");
}

function VFOSetAGC(str) {
   let val = str.toUpperCase();
   console.log("[" + Settings.ActiveRadio + "] Changing AGC setting to: " + val + " for VFO " + GetActiveRadio().ActiveVFO);

   // Set things per the selection
   $('span#stat_AGC').removeClass('stat_AGC_OFF stat_AGC_SLOW stat_AGC_MED stat_AGC_FAST');

   if (val === "OFF") {
      $('span#stat_AGC').addClass('stat_AGC_OFF');
   } else if (val === "SLOW") {
      $('span#stat_AGC').addClass('stat_AGC_SLOW');
   } else if (val === "MED") {
      $('span#stat_AGC').addClass('stat_AGC_MED');
   } else if (val === "FAST") {
      $('span#stat_AGC').addClass('stat_AGC_FAST');
   }

   // Change the AGC mode on the active VFO...
   if (Settings.ActiveVFO === 'A') {
      GetActiveRadio().VFO_A_AGC_Mode = val;
   } else if (Settings.ActiveVFO === 'B') {
      GetActiveRadio().VFO_B_AGC_Mode = val;
   } else
      alert('Unknown VFO ' + Settings.ActiveVFO + ' requested in VFOSetAGC()');
}

function Tabsets_Init() {
   $('span.Tab').click(function() {
      // Which tabset is this in?
      let myId = $(this).attr('id');
      let tabset = myId.substring(0, myId.lastIndexOf('_'));
      let viewport = myId.substr(myId.lastIndexOf('_') + 1);
      console.log("[ui] tabset_init: [tabset] " + tabset + " [viewport] " + viewport + " for (" + myId + ")");

      // Roll up any active tabs & clear their active status...
      $('div#' + tabset + ' .ActiveTab').each(function(idx, val) {
         let tmpId = $(val).attr('id');
         let tmpTabset = tmpId.substring(0, tmpId.lastIndexOf('_'));
         let tmpViewport = tmpId.substr(tmpId.lastIndexOf('_') + 1);

         if (val != $(this)) {
            console.log("[ui] Hiding window " + tmpTabset + "/" + tmpViewport);
            $(this).removeClass('ActiveTab');
            $('div#View_' + tmpViewport).slideUp();
         }
      });

      $(this).addClass('ActiveTab');
      console.log('[ui] TabStrip: Opening ' + viewport + ' in ' + tabset);
      $('div#View_' + viewport).slideDown();
   });
}

function Tab_CW_Init() {
   // Decoder Tab (Macros)
   $('input#CW_Macro_Add').click(function() {
      alert('Not yet implemented :(');
   });

   $('input#CW_Clear').click(function() {
      $('input#CW_Input').val('');
      $('input#CW_Input').focus();
   });

   $('input#CW_Macro_CQ').click(function() {
      $('input#CW_Input').val('CQ CQ CQ DE ' + Settings.CallSign);
      $('input#CW_Input').focus();
   });

   // Handle CW encoder
   $('form#Decoder').submit(function(event) {
      event.preventDefault();	// stop the browser from reloading the page on submit...
      // Send the request for CW TX to the PHP proxy for rigctl
      console.log("[CW] Submitting AJAX request to send CW: " + $(this).serialize());

      $.ajax({
         type: "POST",
         url: "/api/cw.php",
         data: $(this).serialize(),
         dataType: "json",
         encode: true
      }).done(function (data) {
         console.log("[CW] Got API response " + data);
      });
   });
}

function Radio_Settings_Init() {
   // VFO Switch
   $('div.VFO, input.VFO_input').click(function() {
      GetActiveRadio().ActiveVFO = this.id.slice(-1);
      SetActiveVFO(GetActiveRadio().ActiveVFO);
   });
   // Handle Band changes
   $("select#CAT_band").change(function() {
      let str = $(this).val().toUpperCase().trim();
      console.log("[" + Settings.ActiveRadio + "] Changing BAND to: " + str + " for VFO " + GetActiveRadio().ActiveVFO);

      if (GetActiveRadio().ActiveVFO === 'A')
         GetActiveRadio().VFO_A_Band = str;
      else if (GetActiveRadio().ActiveVFO === 'B')
         GetActiveRadio().VFO_B_Band = str;
   });

   // Handle Mode changes
   $("select#CAT_mode").change(function() {
      let str = $(this).val().toUpperCase().trim();
      console.log("[" + Settings.ActiveRadio + "] Changing MODE to: " + str + " for VFO " + GetActiveRadio().ActiveVFO);

      if (GetActiveRadio().ActiveVFO === 'A')
         GetActiveRadio().VFO_A_Mode = str;
      else if (GetActiveRadio().ActiveVFO === 'B')
         GetActiveRadio().VFO_B_Mode = str;
   });

   // Handle Step changes
   $("select#CAT_step").change(function() {
      let str = $(this).val().toUpperCase().trim();
      console.log("[" + Settings.ActiveRadio + "] Changing STEP to: " + str + " for VFO " + GetActiveRadio().ActiveVFO);

      if (GetActiveRadio().ActiveVFO === 'A')
         GetActiveRadio().VFO_A_Step = str;
      else if (GetActiveRadio().ActiveVFO === 'B')
         GetActiveRadio().VFO_B_Step = str;
   });

   // Handle AGC mode changes
   $("select#CAT_agc").change(function() {
      let str = $(this).val().toUpperCase().trim();
      VFOSetAGC(str);
   });

   function gui_update_vfo_freq(e) {
      // Which VFO is being changed?
      let str = $(this).attr('id').trim().slice(-1).toUpperCase();

      if (str === 'A') {
         GetActiveRadio().VFO_A_Freq = $(this).val();
      } else if (str === 'B') {
         GetActiveRadio().VFO_B_Freq = $(this).val();
      } else {
         alert("invalid VFO " + str + " selected");
      }
      console.log("Tuned VFO " + str + " to " + $(this).val());
   }
   $('input.VFO_input').change(gui_update_vfo_freq);

   $('div.VFO_Freq').click(function(e) {
      e.preventDefault();
      let myInput = $(this).find('input.VFO_input');

      if (myInput !== undefined) {
         let myVfo = myInput.attr('id').trim().slice(-1).toUpperCase();
         SetActiveVFO(myVfo, false);
      } else
         console.log("hmm..couldn't find a VFO_input inside the DIV");
   });
   $('form#CAT').submit(function(event) {
      event.preventDefault();	// stop the browser from reloading the page on submit...
      // Send the request for CAT change to the PHP proxy for rigctl
      console.log("[CAT] Submitting AJAX request: " + $(this).serialize());

      $.ajax({
         type: "POST",
         url: "/api/cat/",
         data: $(this).serialize(),
         dataType: "json",
         encode: true
      }).done(function (data) {
         console.log("Got data " + data);
      });
   });
}

function radio_init(radio) {
   console.log("radio_init: Initializing radio " + radio);

   var radio_init_timer = window.setTimeout(function() {
      let div = $('.radio_win');
            if (div.is(':visible')) {
               Radio_Settings_Init();
               SetInitialUIState();
               Tabsets_Init();
               Tab_CW_Init();
            }
   }, 750);
}

/////////////////////////////////////////////////////
////////
// from https://www.w3schools.com/howto/howto_custom_select.asp
// XXX: Clean this up into jquery way, so it can be much smaller
// XXX - NamespacePollution, Structure, ExampleCode
var x, i, j, l, ll, selElmnt, a, b, c;

/* Look for any elements with the class "custom-select": */
x = document.getElementsByClassName("custom-select");
l = x.length;

for (i = 0; i < l; i++) {
   selElmnt = x[i].getElementsByTagName("select")[0];
   ll = selElmnt.length;

   /* For each element, create a new DIV that will act as the selected item: */
   a = document.createElement("DIV");
   a.setAttribute("class", "select-selected");
   a.innerHTML = selElmnt.options[selElmnt.selectedIndex].innerHTML;
   x[i].appendChild(a);

   /* For each element, create a new DIV that will contain the option list: */
   b = document.createElement("DIV");
   b.setAttribute("class", "select-items select-hide");

   for (j = 1; j < ll; j++) {
     /* For each option in the original select element,
     create a new DIV that will act as an option item: */
     c = document.createElement("DIV");
     c.innerHTML = selElmnt.options[j].innerHTML;
     c.addEventListener("click", function(e) {
        /* When an item is clicked, update the original select box,
        and the selected item: */
        var y, i, k, s, h, sl, yl;
        s = this.parentNode.parentNode.getElementsByTagName("select")[0];
        sl = s.length;
        h = this.parentNode.previousSibling;

        for (i = 0; i < sl; i++) {
          if (s.options[i].innerHTML == this.innerHTML) {
             s.selectedIndex = i;
             h.innerHTML = this.innerHTML;
             y = this.parentNode.getElementsByClassName("same-as-selected");
             yl = y.length;
             for (k = 0; k < yl; k++) {
                y[k].removeAttribute("class");
             }
             this.setAttribute("class", "same-as-selected");
             break;
          }
        }
        h.click();
     });
     b.appendChild(c);
   }

   x[i].appendChild(b);

   a.addEventListener("click", function(e) {
      /* When the select box is clicked, close any other select boxes,
      and open/close the current select box: */
      e.stopPropagation();
      closeAllSelect(this);
      this.nextSibling.classList.toggle("select-hide");
      this.classList.toggle("select-arrow-active");
   });
}
