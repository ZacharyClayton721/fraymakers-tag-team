// API Script for Assist Template Projectile

var LIFE_TIMER = 60 * 4; // max life of projectile

var life = self.makeInt(LIFE_TIMER);

function initialize(){
	// Set up wall hit event
	self.addEventListener(EntityEvent.COLLIDE_WALL, onWallHit, { persistent: true });

	// Set up horizontal reflection
	Common.enableReflectionListener({ mode: "X", replaceOwner: true });
}

function onWallHit(event) {
	self.destroy();
}

function update() {
	if (self.inState(PState.ACTIVE)) {
		// Give some horizontal speed
		self.setXSpeed(10);

		// Subtract 1 from life counter
		life.dec();
		// If life runs out, destroy
		if (life.get() <= 0) {
			self.destroy();
		}
	}
}
function onTeardown(){
}
