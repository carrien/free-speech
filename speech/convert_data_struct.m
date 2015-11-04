function [ ] = convert_data_struct(exptName,snum,subdir)
%CONVERT_DATA_STRUCT  Convert old (audioGUI) data to new (fusp) format.
%   CONVERT_DATA_STRUCT(EXPTNAME,SNUM,SUBDIR) loads the data.mat struct
%   corresponding to subject SNUM in experiment EXPTNAME and saves a backup
%   copy ('data_oldformat.mat') before renaming the parameter subfields
%   (e.g., sr --> fs; nLPC --> nlpc).

if nargin < 3, subdir = []; end

% load data
datafile = fullfile(getAcoustSubjPath(exptName,snum,subdir),'data.mat');
load(datafile,'data');

% check if data has already been converted
if isfield(data(1).params,'fs')
    fprintf('Data struct already converted to new format (params field ''fs'' exists). No new files saved.\n')
    return
else
    fprintf('Data struct contains old fieldnames and will be converted.\n')
end

% save old format as backup
oldformatfile = fullfile(getAcoustSubjPath(exptName,snum,subdir),'data_oldformat.mat');
save(oldformatfile,'data');
fprintf('Backup saved as data_oldformat.mat.\n')

% rename fields
params = [data.params];
params = rename_struct_field(params,'sr','fs');
params = rename_struct_field(params,'nLPC','nlpc');
[data.params] = deal(params);

% save new format
save(datafile,'data');
fprintf('New format saved as data.mat.\n')