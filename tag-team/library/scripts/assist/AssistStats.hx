// Assist stats for Template Assist

// Define some states for our state machine
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;

{
	spriteContent: self.getResource().getContent("assisttemplate"),
	initialState: STATE_IDLE,
	stateTransitionMapOverrides: [
		STATE_IDLE => {
			animation: "idle"
		},
		STATE_JUMP => {
			animation: "jump"
		},
		STATE_FALL => {
			animation: "fall"
		},
		STATE_SLAM => {
			animation: "slam"
		},
		STATE_OUTRO => {
			animation: "outro"
		}
	],
	gravity: 0,
	terminalVelocity: 20,
	assistChargeValue:50
}
