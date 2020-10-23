function [ ] = run_duration_practice(outputdir,expt,h_fig)
%RUN_DURATION_PRACTICE  Run test trials for practicing duration feedback.

expt.nblocks = 1;
expt.ntrials_per_block = 10;
expt.ntrials = expt.nblocks * expt.ntrials_per_block;

run_speechprod_audapter(outputdir,expt,h_fig)