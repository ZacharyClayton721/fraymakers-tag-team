
var player:Character = null;
var team:Array = [];
var teamMember:Character = null;
var activeMember:Character = null;
var TagState = {
    ACTIVE: "ACTIVE",
    STANDBY: "STANDBY",
    TAGGING_IN: "TAGGING_IN",
    TAGGING_OUT: "TAGGING_OUT",
    DISABLED: "DISABLED"
};
var teamStates = [];
var initialRun = false;
var hitFoe:Character = null;

// Timers
var disabledTimer = null;
var flyInTimer = null;
var flyOutTimer = null;
var assistAnimTimer = null;
var foeHitTimer = null;
var tagActionWait = null;

// Event Listeners
var taggedFoeHit = null;

// Timer Tracking Variables
var flyOutI = 0;
var assistAnimI = 0;

// Event Listeners
var flyInLand = null;

// Content Specific Things`
var baseCast = ['octodad','commandervideo','welltaro','thewatcher','orcane','fishbunjin'];
// Used to check if baseCast or not
// baseCast.indexOf(activeMember.getPlayerConfig().character.contentId) != -1

function initialize() {
    Engine.log('We here');
    player = self.getOwner();
}

function createTeamMembers() {
    for (c in match.getPlayers()) {
        if (player == c) {
            team.push(player);
        } else if (c.getTeam() == player.getTeam()) {
            team.push(c);
        }
    }
}

function setupTeam() {
    teamStates[0] = TagState.ACTIVE;
    teamStates[1] = TagState.STANDBY;

    team[1].setAlpha(0);
    camera.deleteTarget(team[1]);
    // Disable team member until needed
    disabledTimer = team[1].addTimer(1,0, function() {
        team[1].setState(CState.DISABLED);
    }, {persistent:true});
    
}

function getTeam() {
    return team;
}

function tagTeamMember() {
    Engine.log('We tagging');
    var activeIndex = getActiveMemberIndex();
    var standbyIndex = getStandbyMemberIndex();

    if (activeIndex == -1 || standbyIndex == -1) return;

    var active = team[activeIndex];
    var standby = team[standbyIndex];

    var hitboxFrame = null;

    teamStates[activeIndex] = TagState.TAGGING_OUT;
    teamStates[standbyIndex] = TagState.TAGGING_IN;

    standby.setAlpha(1);
    if (active.isFacingLeft()) standby.faceLeft(); else standby.faceRight();

    standby.removeTimer(disabledTimer);
    standby.toState(CState.JUMP_OUT);
    camera.addTarget(standby);
    standby.playAnimation('aerial_neutral');

    var offsetX = standby.isFacingLeft() ? 150 : -150;
    var velocityX = standby.isFacingLeft() ? -8 : 8;

    standby.setX(active.getX() + offsetX);
    standby.setY(active.getY() - 150);

    // Fly In
    flyInTimer = standby.addTimer(1, 30, function() {
        standby.setXVelocity(velocityX);
        standby.setYVelocity(8);

        var currentHitboxes = standby.getCollisionBoxes(CollisionBoxType.HIT);
        Engine.log(currentHitboxes);
        if (currentHitboxes != null) {
            if (hitboxFrame == null) {
                Engine.log('We here');
                hitboxFrame = standby.getCurrentFrame();
                hitboxes = currentHitboxes;
                for (i in 0...hitboxes.length) {
                    standby.updateHitboxStats(i, {
                        damage: 10,
                        angle: 75,
                        baseKnockback: 110,
                        knockbackGrowth: 0,
                        hitstun: 80,
                        directionalInfluence: false,
                        stackKnockback: false
                    });
                }
            }
            standby.playFrame(hitboxFrame);
        }
    }, { persistent: true });

    flyInLand = standby.addEventListener(GameObjectEvent.LAND, function() {
        standby.removeTimer(flyInTimer);
        standby.setYVelocity(0);
        standby.setXVelocity(0);
        standby.toState(CState.EMOTE);
        standby.playAnimation('emote');

        standby.addTimer(20, 1, function() {
            standby.updateAnimationStats({ interruptible: true });
            teamStates[standbyIndex] = TagState.ACTIVE;
        }, { persistent: true });

        standby.removeEventListener(GameObjectEvent.LAND, flyInLand);
    }, { persistent: true });

    tagOut(activeIndex);
}

function doHit(foe:Character, direction) {
    
    var hangTime = 80;
    var currentFrame = 0;
    var startY = foe.getY();
    var startX = foe.getX();
    var xDistance = 200;
    var yPeak = 200;

    foeHitTimer = foe.addTimer(1, hangTime, function() {
        var t = currentFrame / hangTime; // 0..1 normalized

        // Horizontal motion: linear
        var xOffset = xDistance * t;

        // Vertical motion: sinusoidal for smooth easing at the peak
        var yOffset = yPeak * Math.sin(Math.PI * t);

        // Apply positions
        if (direction == 'left') {
            foe.setX(startX - xOffset);
        } else {
            foe.setX(startX + xOffset);
        }
        
        foe.setY(startY - yOffset);

        currentFrame += 1;
    }, { persistent: true });

    hitFoe.addEventListener(GameObjectEvent.ENTER_HITSTOP, handleFoeFollowupHit, {persistent: true});
   
}

function handleFoeFollowupHit(event:GameObjectEvent) {
    hitFoe.removeTimer(foeHitTimer);
    hitFoe.removeEventListener(GameObjectEvent.ENTER_HITSTOP, handleFoeFollowupHit);
}

function getViewPort() {
    var vw_width = camera.getViewportWidth();
    var vw_height = camera.getViewportHeight();
    var vw_x = camera.getX() - vw_width/2;
    var vw_y = camera.getY() - vw_height/2;

    return new Rectangle(vw_x, vw_y, vw_width, vw_height);
}

function tagOut(activeIndex) {
    var member = team[activeIndex];
    member.updateGameObjectStats({ solid: false });
    member.toState(CState.UNINITIALIZED, 'assist_call');
    camera.deleteTarget(member);
    teamStates[activeIndex] = TagState.TAGGING_OUT;

    var assistAnimI = 0;

    assistAnimTimer = member.addTimer(1, 0, function() {
        if (member.finalFramePlayed()) {
            member.playFrame(member.getCurrentFrame());
        } else if (assistAnimI == 20) {
            member.playFrame(assistAnimI);
            member.toState(CState.UNINITIALIZED, 'jump_in');

            flyOutTimer = member.addTimer(1, 30, function() {
                var viewport = getViewPort();

                if (!viewport.contains(member.getX(), member.getY())) {
                    member.setAlpha(0);
                    member.toState(CState.DISABLED);
                    teamStates[activeIndex] = TagState.STANDBY; // back to standby
                }

                if (member.isFacingLeft()) {
                    member.setXVelocity(20);
                } else {
                    member.setXVelocity(-20);
                }
                member.setYVelocity(-10);
            }, { persistent: true });

            member.removeTimer(assistAnimTimer);
        }

        assistAnimI++;
    }, { persistent: true });
}

function switchTagVars() {
    var oldTeamMember= teamMember;
    var oldActiveMember = activeMember;
    activeMember = oldTeamMember;
    teamMember = oldActiveMember;
}

function getActiveMemberIndex() {
    for (i in 0...team.length) {
        if (teamStates[i] == TagState.ACTIVE) return i;
    }
    return -1;
}

function getStandbyMemberIndex() {
    for (i in 0...team.length) {
        if (teamStates[i] == TagState.STANDBY) return i;
    }
    return -1;
}

function getActiveMember() {
    var idx = getActiveMemberIndex();
    return idx != -1 ? team[idx] : null;
}

function getStandbyMember() {
    var idx = getStandbyMemberIndex();
    return idx != -1 ? team[idx] : null;
}

function isTagging(index) {
    var state = teamStates[index];
    return state == TagState.TAGGING_IN || state == TagState.TAGGING_OUT;
}

function isAnyTagging() {
    for (i in 0...teamStates.length) {
        if (isTagging(i)) return true;
    }
    return false;
}

function update() {

    if (initialRun == false) {
        createTeamMembers();
        setupTeam();

        initialRun = true;
    }

    if (initialRun == true) {
        if (isAnyTagging() == false) {
            var active = getActiveMember();
            if (active.getPressedControls().ACTION) {
                tagTeamMember();
            }
        }
    }

    player.setAssistCharge(0);
}

function onTeardown() {

}

self.exports.getTeam = getTeam;
self.exports.tagTeamMember = tagTeamMember;