$(document).ready(function() {
    var ws = new WebSocket('ws://example.com'); // Replace 'ws://example.com' with your WebSocket server URL

    var previousSize = 0;
    var currentSize = 0;

    ws.onopen = function(event) {
        console.log('WebSocket connection established.');
    };

    ws.onmessage = function(event) {
        // Calculate the size of the received data
        currentSize += event.data.length;

        // Calculate the bitrate
        var timeInterval = 1000; // Time interval in milliseconds
        var bitrate = (currentSize - previousSize) * 8 / (timeInterval / 1000); // in bits per second
        console.log('Bitrate:', bitrate.toFixed(2), 'bps');

        // Reset previousSize for the next interval
        previousSize = currentSize;
    };

    ws.onclose = function(event) {
        console.log('WebSocket connection closed.');
    };
});
