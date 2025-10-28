
var player:Character = null;
var team:Array = [];
var teamMember:Character = null;
var activeMember:Character = null;
var initialRun = false;

// Timers
var disabledTimer = null;
var flyInTimer = null;
var flyOutTimer = null;
var assistAnimTimer = null;
var foeHitTimer = null;

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
    activeMember = team[0];
    teamMember = team[1];

    //teamMember.setAlpha(0);
    camera.deleteTarget(teamMember);
    // Disable team member until needed
    disabledTimer = teamMember.addTimer(1,0, function() {
        teamMember.setState(CState.DISABLED);
    }, {persistent:true});
    
}

function getTeam() {
    return team;
}

function tagTeamMember() {

    // Make sure teamMember faces the same direction on tag-in
    if (activeMember.isFacingLeft()) {
        teamMember.faceLeft();
    } else {
        teamMember.faceRight();
    }
    teamMember.removeTimer(disabledTimer);
    // teamMember.setState(CState.AERIAL_NEUTRAL);
    teamMember.toState(CState.JUMP_OUT);
    camera.addTarget(teamMember);
    teamMember.playAnimation('aerial_neutral');

    var hitboxFrame = null;
    
    var offsetX = teamMember.isFacingLeft() ? 150 : -150;
    var velocityX = teamMember.isFacingLeft() ? -8 : 8;

    teamMember.setX(activeMember.getX() + offsetX);
    teamMember.setY(activeMember.getY() - 150);

    flyInTimer = teamMember.addTimer(1, 30, function() {
        teamMember.setXVelocity(velocityX);
        teamMember.setYVelocity(8);

        var currentHitboxes = teamMember.getCollisionBoxes(CollisionBoxType.HIT);
        if (currentHitboxes != null) {
            if (hitboxFrame == null) {
                hitboxFrame = teamMember.getCurrentFrame();
                hitboxes = currentHitboxes;
                for (i in 0...hitboxes.length) {
                    teamMember.updateHitboxStats(i, {
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
            teamMember.playFrame(hitboxFrame);
        }
    }, {persistent: true});

    teamMember.addEventListener(GameObjectEvent.HIT_DEALT, function(event:GameObjectEvent) {
        var foe = event.data.foe;
        if (teamMember.isFacingLeft()) {
            doHit(event.data.foe, 'left');  
        } else {
            doHit(event.data.foe, 'right'); 
        }
        // foe.updateCharacterStats({gravity:.8,weight: 80});
    });

    flyInLand = teamMember.addEventListener(GameObjectEvent.LAND,function() {
        teamMember.removeTimer(flyInTimer);
        teamMember.setYVelocity(0);
        teamMember.setXVelocity(0);
        teamMember.toState(CState.EMOTE);
        teamMember.playAnimation('assist_call');

        teamMember.removeEventListener(GameObjectEvent.LAND, flyInLand);
    }, {persistent: true});

    tagOut();


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

    foe.addEventListener(GameObjectEvent.HIT_RECEIVED, function (event:GameObjectEvent) {
        foe.removeTimer(foeHitTimer);
        foe.setKnockback(event.foe.getKnockback());
    }, {persistent:true});
}


function getViewPort() {
    var vw_width = camera.getViewportWidth();
    var vw_height = camera.getViewportHeight();
    var vw_x = camera.getX() - vw_width/2;
    var vw_y = camera.getY() - vw_height/2;

    return new Rectangle(vw_x, vw_y, vw_width, vw_height);
}

function tagOut() {
    activeMember.updateGameObjectStats({solid:false});
    activeMember.toState(CState.UNINITIALIZED,'assist_call');
    camera.deleteTarget(activeMember);
    assistAnimI = 0;
    assistAnimTimer = activeMember.addTimer(1,0,function() {

        if (activeMember.finalFramePlayed()) {
            activeMember.playFrame(activeMember.getCurrentFrame());
        } else if (assistAnimI == 20) {

            activeMember.playFrame(assistAnimI);
            activeMember.toState(CState.UNINITIALIZED,'jump_in');
            flyOutTimer = activeMember.addTimer(1,30, function() {

                var viewport = getViewPort();

                if (!viewport.contains(activeMember.getX(), activeMember.getY())) {
                    activeMember.setAlpha(0);
                    activeMember.toState(CState.DISABLED);
                }
                if (activeMember.isFacingLeft()) {
                    activeMember.setXVelocity(20);
                } else {
                    activeMember.setXVelocity(-20);
                }
                activeMember.setYVelocity(-10);
            }, {persistent: true});
            activeMember.removeTimer(assistAnimTimer);

        } 

        assistAnimI ++;

        
    }, {persistent: true});
}

function update() {

    if (initialRun == false) {
        createTeamMembers();
        setupTeam();

        initialRun = true;
    }

}

function onTeardown() {

}

self.exports.getTeam = getTeam;
self.exports.tagTeamMember = tagTeamMember;