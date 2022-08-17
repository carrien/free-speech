

manipObject$ = "Manipulation mop_longsplice"


startCodaTrans = 0.187648
endCodaTrans = 0.218190

warpPoint1 = startCodaTrans + 0.001
warpPoint2 = endCodaTrans - 0.001


codaTransDur = warpPoint2 - warpPoint1

desiredTransDur = 0.050


editor 'manipObject$'

	Add duration point at: startCodaTrans, 1
	Add duration point at: endCodaTrans, 1
	
	Add duration point at: warpPoint1, desiredTransDur/codaTransDur
	Add duration point at: warpPoint2, desiredTransDur/codaTransDur

	newSynth = Publish resynthesis



endeditor

	select (newSynth)
	Rename: "mop_longsplice_longtrans"
