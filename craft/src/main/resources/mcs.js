// ==UserScript==
// @name         refresh
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  refresh pages
// @author       You
// @match        https://www.mcserverhost.com/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';

    setTimeout(function(){

        var timeTillDueElement = document.getElementById('time-till-due');

        if (timeTillDueElement) {
            var timeTillDueText = timeTillDueElement.textContent || timeTillDueElement.innerText;

            var timeParts = timeTillDueText.split(':');

            if (timeParts.length === 3) {
                var minutes = parseInt(timeParts[1], 10);

                console.log('Time till due:', timeTillDueText);

                if (minutes < 30) {
                    var renewButton = document.querySelector('.renew');

                    if (renewButton) {
                        renewButton.click();
                    }
                }
            }
        } else {
            console.log('time-till-due');
        }
    }, 1000 * 10);
    setTimeout(function() {
        location.reload();
    }, 1000 * 60 * 10);

})();
