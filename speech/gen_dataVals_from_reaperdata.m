function [ ] = gen_dataVals_from_reaperdata(exptName,snum,subdir)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3, subdir = []; end

dataPath = getAcoustSubjPath(exptName,snum,subdir);
load(fullfile(dataPath,'dataVals.mat'),'dataVals');
load(fullfile(dataPath,'reaperdata.mat'),'reaperdata');

minlength = 30;
reaperdata(1).onsetInd = []; % initialize struct fields
reaperdata(1).offsetInd = [];

for i=1:length(reaperdata)
    
    % find onset
    bVoiced = reaperdata(i).bVoiced;
    voicedInds = find(bVoiced);
    for vi=1:length(voicedInds)
        if length(bVoiced) >= voicedInds(vi)+minlength-1 && sum(bVoiced(voicedInds(vi):voicedInds(vi)+minlength-1)) == minlength
            reaperdata(i).onsetInd = voicedInds(vi); %#ok<*AGROW>
            break;
        end
    end
    
    if ~isempty(reaperdata(i).onsetInd) % if onset exists
        % find offset
        unvoicedInds = find(~bVoiced);
        unvoicedInds = unvoicedInds(unvoicedInds > reaperdata(i).onsetInd);
        if ~isempty(unvoicedInds)
            reaperdata(i).offsetInd = unvoicedInds(1)-2;
        else
            reaperdata(i).offsetInd = length(reaperdata(i).f0);
        end
        
        % set pitch track from onset to offset
        dataVals(i).f0 = reaperdata(i).f0(reaperdata(i).onsetInd:reaperdata(i).offsetInd);
        dataVals(i).pitch_taxis = reaperdata(i).taxis(reaperdata(i).onsetInd:reaperdata(i).offsetInd);
        dataVals(i).voiced_dur = reaperdata(i).taxis(reaperdata(i).offsetInd) - reaperdata(i).taxis(reaperdata(i).onsetInd);
        
    else % if no onset exists
        dataVals(i).f0 = [];
        dataVals(i).pitch_taxis = [];
        dataVals(i).bExcl = 1; % set trial to bad
    end
    
end

savefile = fullfile(dataPath,'dataVals_reaper.mat');
bSave = savecheck(savefile);
if bSave
    save(savefile,'dataVals');
end