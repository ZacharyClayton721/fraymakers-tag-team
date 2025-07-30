// API Script for Template Assist

// Set up same states as AssistStats (by excluding "var", these variables will be accessible on timeline scripts!)
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;

var SPAWN_X_DISTANCE = 0; // How far in front of player to spawn
var SPAWN_HEIGHT = 0; // How high up from player to spawn
var controller = null;

// Runs on object init
function initialize(){
	controller = self.getOwner().getAssistController().exports;
}

function update(){
	controller.tagTeamMember();
	self.destroy();
}
function onTeardown(){
}
