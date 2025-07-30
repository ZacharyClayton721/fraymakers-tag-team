
var player:Character = null;
var team:Array = [];
var teamMember:Character = null;
var activeMember:Character = null;
var initialRun = false;

// Timers
var disabledTimer = null;
var flyInTimer = null;

// Event Listeners
var flyInLand = null;

function initialize() {
    Engine.log('We here');
    player = self.getOwner();
}

function createTeamMembers() {
    for (c in match.getPlayers()) {
        Engine.log(c);
        if (player.getUid() == c.getUid()) {
            Engine.log('This me');
            team.push(player);
        } else {
            if (c.getTeam() == player.getTeam()) {
                Engine.log('Teammate found');
                team.push(c);
            }
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
                        angle: 90,
                        baseKnockback: 105,
                        knockbackGrowth: 0,
                        hitstun: 60,
                        directionalInfluence: false
                    });
                }
            }
            teamMember.playFrame(hitboxFrame);
        }
    }, {persistent: true});

    flyInLand = teamMember.addEventListener(GameObjectEvent.LAND,function() {
        teamMember.removeTimer(flyInTimer);
        teamMember.setYVelocity(0);
        teamMember.setXVelocity(0);
        teamMember.toState(CState.EMOTE);
        teamMember.playAnimation('emote');

        teamMember.removeEventListener(GameObjectEvent.LAND, flyInLand);
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