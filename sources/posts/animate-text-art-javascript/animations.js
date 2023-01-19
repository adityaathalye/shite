const EL_ROW = "div";
const EL_CELL = "span";
const EMPTY_CHARACTER = "\u00A0";
// Hold references to running animation IDs, so we can cancel them all at will.
const LIVE_ANIMATIONS_IDS_SET = new Set();

const loadingDDW = [
    {"x": 0, "y": 0, "text": "=", "color": "", "tags": [], "group": ""},
    {"x": 1, "y": 0, "text": ".", "color": "", "tags": [], "group": ""},
    {"x": 2, "y": 0, "text": "+", "color": "", "tags": [], "group": ""},
    {"x": 3, "y": 0, "text": "-", "color": "", "tags": [], "group": ""}
];

const gliderDDW = [
    {"id": "0", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"id": "1", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"id": "2", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"id": "3", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"id": "4", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 4, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 4, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 4, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 4, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 1, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 1, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 1, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 4, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 4, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 4, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 4, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 1, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 1, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 1, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 2, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 2, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 2, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 1, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 1, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 1, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 2, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 2, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 2, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 1, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 1, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 1, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 2, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 2, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 2, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 2, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 3, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 3, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 3, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 3, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 2, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 3, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 4, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 2, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 3, "y": 1, "text": "■", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 1, "text": "■", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 4, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 3, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 4, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 3, "y": 1, "text": "■", "color": "", "tags": [], "group": "", "frame": "2"},
    {"x": 2, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 4, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 3, "y": 4, "text": "■", "color": "", "tags": [], "group": "", "frame": "3"},
    {"x": 2, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 3, "y": 4, "text": "■", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 4, "text": "■", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 3, "text": "■", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 4, "y": 2, "text": "■", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"},
    {"x": 1, "y": 1, "text": " ", "color": "", "tags": [], "group": "", "frame": "4"}
];

const blinkDDW = [
    {"id": "0", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 100},
    {"id": "1", "type": "frame", "text": "", "color": "", "tags": [], "group": "", "duration_ms": 200},
    {"x": 1, "y": 1, "text": "0", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 1, "y": 1, "text": "=", "color": "", "tags": [], "group": "", "frame": "1"},
    {"x": 2, "y": 1, "text": "0", "color": "", "tags": [], "group": "", "frame": "0"},
    {"x": 2, "y": 1, "text": "=", "color": "", "tags": [], "group": "", "frame": "1"}
];

function randInt(a, b) {
    return Math.floor(Math.random()*(b-a)+a);
}

function getDdwFrames(ddwDataArray) {
    return ddwDataArray.filter((ddwObject) => ddwObject.type == "frame");
};

function getDdwChars(ddwDataArray) {
    return ddwDataArray.filter((ddwObject) => ddwObject.type != "frame");
};

function paintEmptyCanvas(canvasContext, canvasSize = {x: 24, y: 3}) {
    let df = document.createDocumentFragment();
    let pre = document.createElement("pre");
    for (y = 0; y < canvasSize.y; y++) {
        // Make a new row
        var elRow = document.createElement(EL_ROW);
        elRow.dataset.rowindex = y;
        elRow.style = "font-size: 2em; height: 1ch; padding: 0.05em;";
        // Populate row with blank characters
        for (x = 0; x < canvasSize.x; x++) {
            var elChar = document.createElement(EL_CELL);
            elChar.dataset.x = x;
            elChar.dataset.y = y;
            elChar.innerHTML = `${EMPTY_CHARACTER}`;
            elChar.style = "width: 1ch; display: inline-block; padding: 0.05em;";
            elRow.appendChild(elChar);
        }
        // Populate grid with newly-made row
        pre.appendChild(elRow);
    }

    canvasContext.appendChild(df.appendChild(pre));
};

function paintTextArtPiece(
    ddwCharArray,
    xCanvasOffset = 0, yCanvasOffset = 0,
    canvasContext = document.getElementById("art")) {
    for (const char of ddwCharArray) {
        el = canvasContext.querySelector(
            `${EL_CELL}[data-y='${char.y + yCanvasOffset}'][data-x='${char.x + xCanvasOffset}']`
        );
        if(el) {
            el.dataset.frame = char.frame? char.frame : "";
            el.innerHTML = `${char.text}`;
        }
    }
};

function animateLoading(artContext, xCanvasOffset, yCanvasOffset) {
    for (const char of loadingDDW) {
        let charElement = artContext.querySelector(`${EL_CELL}[data-y='${char.y + yCanvasOffset}'][data-x='${char.x + xCanvasOffset}']`);
        if(charElement) {
            charElement.animate(
                // rotation
                { transform: ['rotate(0deg)', 'rotate(90deg)', 'rotate(135deg)', 'rotate(360deg)'] }
                , {
                    duration: 1000,
                    iterations: Infinity
                });
        };
    };
};

function animateBlink(blinkOnChars, blinkOffChars) {
    let millisBetweenTwitches = randInt(2000, 3000);
    let artContext = document.getElementById("blink-demo");
    setTimeout(() => {
        let twitchMillis = randInt(100, 500);
        paintTextArtPiece(blinkOffChars, 0, 0, artContext);
        setTimeout(() => paintTextArtPiece(blinkOnChars, 0, 0, artContext), twitchMillis);
        // the next twitch...
        animateBlink(blinkOnChars, blinkOffChars);
    }, millisBetweenTwitches);
};

function FrameCounter(numFrames) {
    this.num_frames = numFrames;
    this.current_frame = 0;
    this.getFrame = () => {
        let frame = this.current_frame;
        frame < numFrames ? this.current_frame += 1 : this.current_frame = 0;
        return frame;
    };
};

function stopAllLiveAnimations(setOfLiveAnimationIds = LIVE_ANIMATIONS_IDS_SET) {
    setOfLiveAnimationIds.forEach((intervalID) => clearInterval(intervalID));
}

const gliderAnimationChars = getDdwChars(gliderDDW);
const gliderAnimationSequence = getDdwFrames(gliderDDW)
      .sort((fa, fb) => fb.id < fa.id)
      .map((frame) => gliderAnimationChars
           .filter((char) => char.frame == `${frame.id}`));
console.log(gliderAnimationSequence);

function paintGlider(frameCounter) {
    let artContext = document.getElementById("glider-demo");
    let frameNumber = frameCounter.getFrame();
    let frame = gliderAnimationSequence[frameNumber];
    paintTextArtPiece(frame, 0, 0, artContext);
}

function demoLoading() {
    let artContext = document.getElementById("loading-demo");
    paintEmptyCanvas(artContext);
    paintTextArtPiece(loadingDDW, 1, 1, artContext);
    animateLoading(artContext, 1, 1);
};

function demoGlider() {
    let artContext = document.getElementById("glider-demo");
    paintEmptyCanvas(artContext, {x: 24, y: 6});
    paintGlider(new FrameCounter(4));
    let animationID = setInterval(paintGlider, 500, new FrameCounter(4));
    LIVE_ANIMATIONS_IDS_SET.add(animationID);
}

function demoBlink() {
    let artContext = document.getElementById("blink-demo");
    paintEmptyCanvas(artContext);
    animateBlink(getDdwChars(blinkDDW).filter((c) => c.frame == "0"),
                 getDdwChars(blinkDDW).filter((c) => c.frame == "1"));
};
