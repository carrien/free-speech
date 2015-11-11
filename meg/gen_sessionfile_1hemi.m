function [sess_1hemi] = gen_sessionfile_1hemi(sess,hemi)
%GEN_SESSIONFILE_1HEMI  Save a sessionfile with sensors from a single hemi.
%   GEN_SESSIONFILE_1HEMI(sess,hemi) loads the sessionfile saved in SESS,
%   removes all channels not in the hemisphere specified by HEMI, and saves
%   a copy, appending HEMI to the filename. HEMI can be 'lh' for the left
%   hemisphere, 'rh' for the right hemisphere, or 'both' to generate both
%   left and right hemispheres separately.
%
%   The resulting sessionfile(s) can be used by gen_sessionfile_nuttf,
%   which recalculates the lead field given the selected sensors.
%
%CN 2015

switch hemi
    case 'lh'
        prefix2toss = 'MR';
    case 'rh'
        prefix2toss = 'ML';
    case 'both'
        gen_sessionfile_1hemi(sess,'lh');
        gen_sessionfile_1hemi(sess,'rh');
        return
    otherwise
        error('Hemi must be ''lh'', ''rh'', or ''both''.')
end

% create new filename by appending hemi
[filepath,filename,ext] = fileparts(sess);
sessname_1hemi = sprintf('%s_%s%s',filename,hemi,ext);
sess_1hemi = fullfile(filepath,sessname_1hemi);

bSave = savecheck(sess_1hemi);
if bSave
    % load sessionfile and remove undesired channels from goodchannels
    nuts = load(sess);
    inds2toss = strncmp(prefix2toss,nuts.meg.sensor_labels,2);
    nuts.meg.goodchannels = setdiff(nuts.meg.goodchannels,find(inds2toss));
    % update sessionfile name
    nuts.sessionfile = sessname_1hemi;
    
    % save
    save(sess_1hemi,'-struct','nuts')
    fprintf('Single-hemi sessionfile saved to %s.\n',sess_1hemi)
else
    disp('Single-hemi sessionfile not saved.')
end