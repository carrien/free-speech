function [eventFiles] = get_bstEvents(exptName,sid)
%GET_BSTEVENTS  Returns filenames for saved Brainstorm event markers.

dataPath = getMegSubjPath(exptName,sid);

d = dir(fullfile(dataPath,sprintf('events_%s*',lower(exptName))));
z = d(end); d(end) = []; d = [z; d]; % reorder to put unsuffixed file first
eventFiles = fullfile(dataPath,{d.name});
