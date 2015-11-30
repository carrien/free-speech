function [sess_trialset] = gen_sessionfile_trialset(sess,trialvec,filesuffix)
%GEN_SESSIONFILE_TRIALSET  Save a sessionfile with a subset of trials.
%   GEN_SESSIONFILE_TRIALSET(SESS,TRIALVEC,FILESUFFIX) loads the
%   sessionfile saved in SESS, keeps only the trials specified in TRIALVEC,
%   and saves a copy, appending the string FILESUFFIX to the filename. If
%   FILESUFFIX is not defined, the suffix will be generated from the
%   numbers in TRIALVEC.
%
%CN 2015

[filepath,filename,ext] = fileparts(sess);

if nargin < 3
    % if no suffix provided, use trialvec
    if length(trialvec)==1
        filesuffix = num2str(trialvec);
    elseif isequal(trialvec,trialvec(1):trialvec(end))
        filesuffix = sprintf('%d-%d',trialvec(1),trialvec(end));
    else
        filesuffix = '_trialset';
    end
end

% create new filename for sessionfile
sessname = sprintf('%s%s%s',filename,filesuffix,ext);
sess_trialset = fullfile(filepath,sessname);

bSave = savecheck(sess_trialset);
if bSave
    % load sessionfile and keep subset of trials
    nuts = load(sess);
    nuts.meg.data = nuts.meg.data(:,:,trialvec);
    % update sessionfile name
    nuts.sessionfile = sessname;
    
    % save
    save(sess_trialset,'-struct','nuts')
    fprintf('Sessionfile trial subset saved to %s.\n',sess_trialset)
else
    disp('Sessionfile trial subset not saved.')
end