function [ ] = gen_sessionfile_nuttf(sess,hemi,voxelsize)
%GEN_SESSIONFILE_NUTTF  Create sessionfile for nutmeg TF analysis.
%   GEN_SESSIONFILE_NUTTF(SESS,HEMI) loads the sessionfile saved in
%   SESSIONFILE, removes all channels not in the hemisphere specified by
%   HEMI, and saves a copy, appending HEMI to the filename. HEMI can be
%   'lh' for the left hemisphere, 'rh' for the right hemisphere, or 'both'
%   to generate both left and right hemispheres separately.
%
%CN 2015

global nuts
nut_defaults;

if nargin < 3 || isempty(voxelsize), voxelsize = 5; end

switch hemi
    case 'lh'
    case 'rh'
    case 'both'
        gen_sessionfile_nuttf(sess,'lh',voxelsize);
        gen_sessionfile_nuttf(sess,'rh',voxelsize);
        return
    otherwise
        error('Hemi must be ''lh'', ''rh'', or ''both''.')
end

% Generate single-hemi sessionfile
[filepath,filename,ext] = fileparts(sess);
sessname_1hemi = sprintf('%s_%s%s',filename,hemi,ext);
sess_1hemi = fullfile(filepath,sessname_1hemi);
if ~exist(sess_1hemi,'file')
    gen_1hemi_sessionfile(sess,hemi);
else
    fprintf('Single-hemi sessionfile found. Using %s...\n',sess_1hemi)
end

% Parse sess for voi path
megdataInd = strfind(sess,'megdata/s');
subjPath = sess(1:megdataInd+length('megdata/s0'));
voifile = fullfile(subjPath,sprintf('voi_%s.mat',hemi));

% Add VOI
sessname_voi = sprintf('%s_%s_%s%s',filename,hemi,'voi',ext);
sess_voi = fullfile(filepath,sessname_voi);
bSave = savecheck(sess_voi);
if bSave
    % load sessionfile and VOIvoxels
    nuts = load(sess_1hemi);
    voivox = load(voifile);
    % set VOI
    nuts = rmfield(nuts,'voxels');
    nuts.VOIvoxels = voivox.VOIvoxels;
    nuts.voxels = nut_make_voxels(unique(nuts.voxelsize));
    % obtain new lead field with VOI
    %[nuts.Lp,nuts.voxels]=nut_compute_lead_field(nuts.voxelsize,nuts.VOIvoxels);
    [nuts,~,voxels] = nut_obtain_lead_field(nuts,voxelsize,3); % assume lfcomp = 3;
    % update sessionfile name
    nuts.sessionfile = sessname_voi;
    
    % save
    save(sess_voi,'-struct','nuts')
    fprintf('VOI sessionfile saved to %s.\n',sess_voi)
else
    disp('VOI sessionfile not saved.')
end