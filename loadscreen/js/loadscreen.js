var intervalId;
var loadState = {}

const loadPhases = {
    INIT_CORE: ['Init Core'],
    INIT_BEFORE_MAP_LOADED: ['Before Map Loaded'],
    MAP: ['MAP'],
    INIT_AFTER_MAP_LOADED: ['After Map Loaded'],
    INIT_SESSION: ['Session']
};

var messages = [
    "Grab the enemy's package and capture it.",
    "You can spawn by pressing SHIFT.",
    "Cycle through teams by using your left and right mouse button."
];

var currentIndex = 0;

document.querySelector('.log-line-msg').style.display = 'none';

const handlers = {
    startInitFunction(data) {
        if (loadState[data.type] === undefined) {
            loadState[data.type] = { count: 0, processed: 0 };
            if (!intervalId) {
                intervalId = setInterval(updateProgressBars, 100);
            }
        }
    },

    startInitFunctionOrder(data) {
        if(loadState[data.type] !== undefined) {
            loadState[data.type].count += data.count;
        }
    },

    initFunctionInvoked(data) {
        if(loadState[data.type] !== undefined) {
            loadState[data.type].processed++;
        }

        logMessage({ message: `Invoked: ${data.type} ${data.name}!` });
    },

    startDataFileEntries(data) {
        loadState["MAP"] = {};
        loadState["MAP"].count = data.count;
        loadState["MAP"].processed = 0;
    },

    performMapLoadFunction(data) {
        loadState["MAP"].processed++;
    },

    onLogLine(data) {
        logMessage(data);
    }
};

window.addEventListener('message', function (e) {
    (handlers[e.data.eventName] || function () { })(e.data);
});

function logMessage(data) {
    const logLineMsg = document.querySelector('.log-line-msg');
    logLineMsg.style.display = 'block';
    const newMessage = document.createElement('div');
    newMessage.textContent = data.message;
    newMessage.classList.add('message');
    logLineMsg.appendChild(newMessage);
    logLineMsg.scrollTop = logLineMsg.scrollHeight;
}

function updateProgressBars() {
    for (const phaseName in loadPhases) {
        if (loadState[phaseName] != null){
            console.log(`${phaseName}, Processed: ${loadState[phaseName].processed}, Total: ${loadState[phaseName].count}`);
            updateProgressBar(phaseName, loadState[phaseName].processed, loadState[phaseName].count);
        }
    }
}

function updateProgressBar(type, idx, count) {
    const progressBarName = type.replace(/_/g, '-').toLowerCase();
    const progressBar = document.querySelector(`.${progressBarName}`);
    const progressBarWidth = ((idx / count) * 100).toFixed(2);
    progressBar.style.width = `${progressBarWidth}%`;
    
    var parentOfProgressBar = progressBar.parentNode;
    var spanElement = parentOfProgressBar.querySelector("span");
    if (!spanElement) {
        spanElement = document.createElement("span");
        parentOfProgressBar.appendChild(spanElement);
    }
    spanElement.textContent = `${loadPhases[type]} (${progressBarWidth}%)` || '';
}

function displayRandomHintMessage() {
    var messageTipElement = document.querySelector('.message-tip');
    messageTipElement.style.opacity = 0;
    
    setTimeout(function() {
        messageTipElement.textContent = messages[currentIndex]; 
        messageTipElement.style.opacity = 1;
    }, 500);

    currentIndex = (currentIndex + 1) % messages.length;
}

function displayHintMessage(intervalInSeconds) {
    displayRandomHintMessage();
    setInterval(displayRandomHintMessage, intervalInSeconds * 1000);
}

displayHintMessage(2);
