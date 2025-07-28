// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;

var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn

// Runs on object init
function initialize(){
	// Face the same direction as the user
	if (self.getOwner().isFacingLeft()) {
		self.faceLeft();
	}
	
	// Reposition relative to the user
	Common.repositionToEntityEcb(self.getOwner(), self.flipX(SPAWN_X_DISTANCE), -SPAWN_HEIGHT);

	// Add fade in effect
	Common.startFadeIn();
}

function update(){
	// Behavior for each state
	if (self.inState(STATE_IDLE)) {
		if (self.finalFramePlayed()) {
			// Bounce into air, activate gravity, and switch to jump state
			self.unattachFromFloor();
			self.setYVelocity(-20);
			self.updateGameObjectStats({ gravity: 1 });
			self.toState(STATE_JUMP); 
		}
	} else if (self.inState(STATE_JUMP)) {
		// Wait until assist starts to fall
		if (self.getYVelocity() >= 0) {
			// Move to fall state
			self.toState(STATE_FALL); 
		}
	} else if (self.inState(STATE_FALL)) {
		// Wait until assist lands
		if (self.isOnFloor()) {
			// Fire two projectiles and switch to slam state
			var proj1 = match.createProjectile(self.getResource().getContent("assisttemplateProjectile"), self);
			var proj2 = match.createProjectile(self.getResource().getContent("assisttemplateProjectile"), self);
			proj2.flip(); // Flip the other projectile the opposite way
			self.toState(STATE_SLAM); 
		}
	} else if (self.inState(STATE_SLAM)) {
		if (self.finalFramePlayed()) {
			// Move to outro state and start fading away
			self.toState(STATE_OUTRO); 
			Common.startFadeOut();
		}
	} else if (self.inState(STATE_OUTRO)) {
		if (Common.fadeOutComplete() && self.finalFramePlayed()) {
			// Destroy
			self.destroy();
		}
	}
}
function onTeardown(){
}
