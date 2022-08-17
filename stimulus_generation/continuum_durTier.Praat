### Takes a manipulation object and makes vowel duration steps from 90 - 220 ms. 

# Lazy saving

# UI to choose save directory, duration range, and step size
form Choose directory to save files and step information
	comment Where would you like to save the new files? 
	text saveDir M:\experiments\cerebDurJND\bus-buzz_continuum\

	comment What would you like to prefix the soundfiles names with? 
	text wordTag buSZ_

	comment How long (in ms) do you want the shortest duration to be? 
	integer firstStep 100

	comment How long (in ms) do you want the longest duration to be?
	integer lastStep 250

	comment How big (in ms) should the step size be between durations? 
	integer stepSize 20

endform

# Generate the vector of continuum steps 
nitems = ((lastStep - firstStep)/stepSize) + 1
for i from 1 to nitems
	durArray [i] = firstStep + (stepSize * (i - 1))
endfor

# Get the original sound file
pauseScript: "Select the sound file you would like to manipulate" 
selectedSound = selected ("Sound") 
selectObject (selectedSound)
soundName$ = selected$ ()
Save as WAV file: saveDir$ + wordTag$ + "originalToken.wav"

# Get the points where you would like to make/not make alterations
View & Edit
editor: soundName$
	pause Select the BEGINNING of the segment you would like to alter (duration will not be altered before this)
	startOriginalInterval = Get cursor

	pause Select the END of the segment you would like to alter (duration will not be altered after this)
	endOriginalInterval = Get cursor

	pause Select the point where you would like warping to start (e.g., after an onset formant transition)
	startWarp = Get cursor

	pause Select the point where you would like the warping to end (e.g., before a coda formant transition)
	endWarp = Get cursor

endeditor

# Durations that won't be changed
onsetTransitionDur = startWarp - startOriginalInterval
codaTransitionDur = endOriginalInterval - endWarp

# To make plateaus instead of slopes of duration, put specified points all at 1. Then actually warp on the insides
warpPoint1 = startWarp + 0.0001
warpPoint2 = endWarp - 0.0001

# This is how much vowel you have on hand to manipulate
baseDuration = warpPoint2 - warpPoint1
unchangeableDuration = onsetTransitionDur + codaTransitionDur

# Create the manipulation object and generate continuum
manipObject = To Manipulation: 0.01, 75, 350
manipObjectName$ = selected$ ()
selectObject (manipObject)
View & Edit

pause Manipulation OK?

for i from 1 to nitems
editor 'manipObjectName$'
	# New duration tier 
	New duration

	# Establish non-warped areas
	Add duration point at: startOriginalInterval, 1
	Add duration point at: startWarp, 1	
	Add duration point at: endWarp, 1
	Add duration point at: endOriginalInterval, 1
		
	# Get desired duration in s
	desiredVowelDuration = durArray [i]/1000
	theMiddleShouldBe = desiredVowelDuration - unchangeableDuration
	# value of dur point at warp points
	ratioManipToReal =  theMiddleShouldBe / baseDuration

	# Set warp points
	Add duration point at: warpPoint1, ratioManipToReal
	Add duration point at: warpPoint2, ratioManipToReal

	newSynth = Publish resynthesis
endeditor
	
	stringedNumber$ = string$ (durArray [i]); 
	if round(durArray [i]) != durArray [i] 
		stringedNumber$ = replace$(stringedNumber$, ".", "x", 0)
	endif 

	newName$ = wordTag$ + stringedNumber$ + "ms"
	fileName$ = newName$ + ".wav"

	select (newSynth)	
	Rename: newName$
	# Scale peak: 0.99
	Save as WAV file: saveDir$ + fileName$	

endfor

selectObject (manipObject)
Save as text file without Sound: saveDir$ + wordTag$ + "manipObject.Manipulation"


