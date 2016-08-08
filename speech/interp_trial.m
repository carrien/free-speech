function [ ] = interp_trial(dataPath,trialnum,startind,endind)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if isempty(dataPath), dataPath = fullfile(cd,'trials'); end

trialfile = fullfile(dataPath,sprintf('%d.mat',trialnum));
load(trialfile);

figure; plot(sigmat.ftrack')

a = startind;
b = endind;
intrp = interp1([1 b-a+1],[sigmat.ftrack(2,a) sigmat.ftrack(2,b)],2:b-a);
sigmat.ftrack(2,a+1:b-1) = intrp;
save(trialfile,'sigmat','trialparams')

figure; plot(sigmat.ftrack')