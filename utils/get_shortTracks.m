function [shortTracks] = get_shortTracks(dataPath,durThresh)
%GET_SHORTTRACKS  Get list of trials with short formant tracks.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(durThresh), durThresh = .1; end

load(fullfile(dataPath,'dataVals.mat'));
durs = [dataVals.dur];
shortTrackInds = find(durs < durThresh);
shortTracks = [dataVals(shortTrackInds).token];

end

