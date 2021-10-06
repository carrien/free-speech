function refreshWorkingCopy(audFileLoc,audFileName,files2refresh)
% Copies the contents of the Master version of an OST/PCF file into a
% Working version of the associated file.
%
% Overwrites an existing working file if one exists;
%   creates a new file if none exists.
%
%       audFileLoc: location of the OST/PCF files. Your OST/PCF files must
%       be in current_studies, so audFileLoc is just the folder name. E.g.
%       'timeAdapt' 'timeAdapt2'. 
%       Default: 'experiment_helpers' (for varMod, adaptRetest, compRetest,
%       etc. that use run_measureFormants)
%       *** PREVIOUSLY KNOWN AS exptName. Change 9/11/2020 RK
% 
%       audFileName: name of the OST/PCF files (excluding Master/Working).
%       E.g. 'ata' 'aza' 'capper' 'measureFormants'
%       Default: 'measureFormants'
%       *** PREVIOUSLY KNOWN AS word. Change 9/11/2020 RK
%
%       files2refresh: Whether to copy the OST file, the PCF file, or both.
%       Use 'ost', 'pcf', or 'both'. 
%       Default: 'both'
%
% Last updated RK 2020/09/11

if nargin < 1 || isempty(audFileLoc), audFileLoc = 'experiment_helpers'; end
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end
if nargin < 3 || isempty(files2refresh), files2refresh = 'both'; end

if isfolder(audFileLoc)
    if contains('\',audFileDir) || contains('/',audFileDir)
        audFilePath = audFileLoc;
    else
        audFilePath = fullfile(get_gitPath, 'current-studies', audFileLoc);
    end
else
    audFilePath = fullfile(get_gitPath, 'current-studies', audFileLoc);
end
    
try  %current-studies repo
    if strcmp(files2refresh,'ost') || strcmp(files2refresh,'both')
       copyfile(fullfile(audFilePath, [audFileName 'Master.ost']), fullfile(audFilePath, [audFileName 'Working.ost']));
    end

    if strcmp(files2refresh,'pcf') || strcmp(files2refresh,'both')
        copyfile(fullfile(audFilePath, [audFileName 'Master.pcf']), fullfile(audFilePath,[audFileName 'Working.pcf']));
    end
catch %try free-speech repo
    audFilePath = fullfile(get_gitPath, 'free-speech', audFileLoc);
    
    if strcmp(files2refresh,'ost') || strcmp(files2refresh,'both')
       copyfile(fullfile(audFilePath, [audFileName 'Master.ost']), fullfile(audFilePath, [audFileName 'Working.ost']));
    end

    if strcmp(files2refresh,'pcf') || strcmp(files2refresh,'both')
        copyfile(fullfile(audFilePath, [audFileName 'Master.pcf']), fullfile(audFilePath,[audFileName 'Working.pcf']));
    end
end

end