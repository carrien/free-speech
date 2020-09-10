# Reference Guide to modelExpt

This is a companion to the model experiment which can be found by calling  `open run_modelExpt_expt`.  Read the User's Guide there.

Concepts in this reference guide appear in alphabetical order. Most information here is nice to know, but not super duper important.

## Audapter
Audapter is a software package which our experiments frequently use for real-time audio perturbations. Audapter runs in Matlab via a [[MEX file]], and it has its own user guide, which you can find by Googling "manual of Audapter" (in quotes). Audapter has a large number of settings and is somewhat complex. For the purposes of modelExpt, this guide will simply briefly describe what Audapter does, rather than how to configure it.

In real time, Audapter is able to receive a speech signal, determine the formants of that signal, change the formants in a specified way, and output the "perturbed" speech signal. We use [[OST and PCF files]] to specify how Audapter should change a speech signal. Audapter can also modify the speech signal in the time domain, rather than the formant, or "spatial", domain. Formant perturbations rely on settings like `pertf1`, `pertAmp`, and `pertPhi`, which you can see being used in `run_vsaAdapt_audapter`---our experiments typically modify F1 and sometimes F2. As an example of time perturbation, `run_timeAdapt_expt` is a somewhat complex example, but the only one we have currently. The Audapter guide also has some demos.


## Conditions
Our adaptation experiments have a general "narrative" for our participant: Things start out normal, then they get weird, then they go back to normal. (Compensation experiments are more like: Some trials are normal and some are weird.) ModelExpt is an adaptation experiment, so it has these conditions:
- Baseline: No perturbation on all trials
- Ramp: Increasing amounts of perturbation from one trial to the next
- Hold: Max amount of perturbation on all trials
- Washout: No perturbation on all trials

This procedure is often experimentally helpful for a few reason:
1. During baseline, people get used to the task, and we get, well, a baseline reading of how they normally speak.
2. With a ramp, we see how people respond at various degrees of perturbation. Maybe people don't react at all until we're at 50% perturbation, or they start reacting right away.
3. With a ramp, sometimes people don't notice the change because it's progressive.
4. A hold phase gives us lots of data at the max perturbation amount.
5. A sudden change back to the washout shows us how people have adapted (learned over time). The first 1 to 3 trials of washout are particularly useful since people haven't "re-learned" how to go back to normal yet.

For any experiment you make, be aware of this experimental design; think about what combination of conditions is needed to answer your research question.


## Counterbalancing
All pts (participants) in modelExpt will go through the experiment once without perturbation ('normal') and once with perturbation ('perturbed'). However, we want to have an equal number of people do the normal runthrough first and the perturbed runthrough first. We also want to randomly assign which one a pt does first. Counterbalancing is the process of randomly and evenly assigning pts to a number of groups.

Many of our experiments use counterbalancing in one way or another. `timeAdapt`, for example,  is more complex than `modelExpt` because it counterbalances word order and deals with multiple populations -- people with cerebellar ataxia and people without. Check out the counterbalancing sections of `timeAdapt` or `dipSwitch` if you need something more complex than what's in `modelExpt`.

## Debugging
Debugging is the process of finding and correcting errors in your code. To begin with, you might just try running your code and seeing if it works. Matlab has great functionality for when you want your debugging to be faster or more efficient. [This YouTube video](https://www.youtube.com/watch?v=PdNY9n8lV1Y) is an excellent showcase of some of that functionality.

## Editing
If you want to edit `run_modelExpt_expt` or `run_modelExpt_audapter` **and you want to save your changes**, here's how to do that safely. 

 1. Open up the folder containing those files. It's probably `C:\Users\Public\Documents\software\current-studies\modelExpt`
 2. Make another folder called practice_[your initials]
 3. Copy and paste the files you want to edit into your new folder.
 4. Change the name of the copied **files** to have your initials at the end. For example, `run_modelExpt_expt_cwn`.
 5. Open the files in Matlab. Change the function name in line 1 of the code to also include your initials.

Alternatively, **if you don't care about saving your changes**, you can just make changes in `run_modelExpt_expt`, then when you're done for the day trash your changes using Git. Do this by navigating to the modelExpt folder in git, then entering `git checkout -- [name of function you changed]`. 

## Headers
Headers are the comments right at the beginning of a function. They're also what show up if you execute  `help [function]` . As a convention, function calls should describe:

 - The function's purpose, in 1-2 sentences.
 - Any input and output arguments. What they accomplish, what data type they are.
 
 Pretty straightforward. For experiment headers, it's helpful to have a few more details, such as:
 - Tools used (Audapter/Pscyhtoolbox)
 - Experiment type (adaptation/compensation)
- General experimental design (two sessions 1 week apart/all in one sitting)
- The experimental variable (perturbing F1/dilating voice onset time)
- Population of test subjects (controls/patients with cerebellar ataxia)

Writing good headers is often an afterthought---literally! But they can be effective aids for other people to understand your code. If you find a function with a bad header (or no header) and you can't grok what it's even *trying* to do, just Slack someone in the lab and we'll help you out (and add a header). It's not your fault someone else didn't document their work!

## Jitter
We often don't want participants to get into a perfect rhythm of speaking when doing our experiments. We want them, to some degree, to actually be responding to the prompt. To do this, we add randomness to how long each trial is, or how much time there is between trials. That randomness is called jitter. For modelExpt, you can look in _audapter to see how we use the `expt.timing.interstimjitter` variable.

## MEX file
A MEX file (so-called because it ends in the `.mex` extension) is a bundle of code which was written in the programming language of C or C++ and has been compiled for use in Matlab. Both [[Audapter]] and [[Psychtoolbox]] use MEX files to interface with Matlab.

Because Audapter and Psychtoolbox aren't written in Matlab code, it means you can't easily look at the source code. For example, if you `open AudapterIO` and see what it calls, it calls a function called `Audapter`. But if you try to `open Audapter`, it doesn't exist.

Why make MEX files instead of just writing Matlab code? Relative to C++, Matlab executes code slowly. Audapter needs to make lots of calculations every couple milliseconds about the speech signal it's receiving, and then do more calculations to change that signal. That speed is *necessary* for real-time audio perturbations to sound anything like natural speech. By using MEX files, we can run our experiments in Matlab (which is easy to learn, read, and debug) while still getting the speed of C++.

A downside of MEX files is that if we want to change how Audapter or Psychtoolbox actually works, we have to edit the C++ code and recompile it. This is time-consuming and challenging, so we normally just leave them alone, even though they have bugs.

## OST and PCF files

Online Status Tracking (ost) and Perturbation Configuration (pcf) files are how [[Audapter]] decides when to make a perturbation, both in the spectral and temporal domain.

OST files use **heuristics** such as `INTENSITY_FALL` and `NEG_INTENSITY_SLOPE_STRETCH_SPAN`---they examine the audio signal and look for certain features. Is the intensity (volume) increasing? What's the ratio between the high frequency noise and low frequency noise? Using these heuristics as building blocks, you can make Audapter place certain landmarks (OST events) while a person is speaking. For example, we know that when someone starts talking, there will be a rise in intensity, so we can have Audapter place an OST event there. If someone says /s/, there will be more high frequency noise, so that can be an OST event. And then if someone stops talking, the intensity will fall. Making OST files which perfectly track even a two-syllable word can be tricky, but open `C:\Users\Public\Documents\software\current-studies\timeAdapt\capperMaster.ost` in Matlab to see an example from timeAdapt.

PCF files are a companion of OST files. They contain settings for initiating time perturbations ("time warping") and one method of formant perturbations. They rely on the landmarks/OST events placed by the OST file.

More information on configuring OST and PCF files are in the [[Audapter]] manual.

## Psychtoolbox
Psychtoolbox is an open-source software package with many tools for conducting Psychology and Psycholinguistics experiments. It interfaces with Matlab via a [[MEX file]].

Psychtoolbox can present words, images, and audio at very precise times. Any of our experiments that use animations or that need to react near-instantaneously to participant input (like `dipSwitch`) use Psychtoolbox. If you see a call to `Screen`, `PsychImaging`, or `PsychPortAudio`, that's Psychtoolbox.

## Randomness
Many of Matlab's randomness functions, such as `rand`, are seeded. That means they use the same method of generating a "random" number each time. This ends up meaning that each time you restart Matlab, you get the same order of "random" numbers. We want to avoid that.

One of the best methods of getting "good" randomness is to randomize the seed. This can be done with `rng('shuffle')`, which looks at the current time (down to the millisecond) to generate a number, then seeds the randomness based on that number. Now that the seed is randomized, we can safely use functions which rely on seeding, like `rand` and `randperm`.

## Sister Functions
Most of our experiments are split into two major functions: one whose name ends in _expt and another whose name ends in _audapter or _ptb. Generally, the _expt function sets up the `expt.mat` file, and the _audapter file actually performs the experiments and creates a `data.mat` file.

Why the split? Sometimes we'll make the _audapter function general enough that it can work for multiple experiments, just by having different _expt functions call into it. That saves us time by not programming multiple _audapter functions that do virtually the same thing. Also, it's just nice to compartmentalize code when you can.

## TODO
As you're programming, you may decide, "I need to fix this, but it's not that important right now". Adding a comment that starts with `% TODO` can be a great way to keep track of things! There's several in modelExpt! Then, when you have time, you can just ctrl+F through your function to look for TODOs.
