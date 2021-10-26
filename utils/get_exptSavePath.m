function [exptPath] = get_exptSavePath(exptName,varargin)
%GET_EXPTSAVEPATH Return path to experiment folder on the local machine
%   GET_EXPTSAVEPATH(EXPTNAME,VARARGIN)
%       Returns the path to an experiment's (specified with EXPTNAME 
%       argument) local directory in the shared/public documents folder. If
%       no EXPTNAME is provided, returns the path to the computers
%       'experiments' folder. Can use VARARGIN to specify subfolders. 
%
%       Currently accounts for Mac vs PC distinction, and Lab PC / iEEG
%       Cart PC / Waisman MRI room PC.

if nargin < 1, exptName = []; end

if ispc
    
    switch getenv('COMPUTERNAME')
        
        %These will need to change in the future if these PC names change. 
        case 'DESKTOP-JM96JC7' %Saalmann Cart PC name
            basePath = 'C:\Users\Saalmann Lab\Documents\experiments\Niziolek\experiments';
        
        case 'CAFFEINE' %MRI Room Experiment Running PC name
            basePath = 'C:\My Experiments\';
        
        otherwise % Assume lab PC
            basePath = 'C:\Users\Public\Documents\experiments\';
     
    end
        
elseif ismac
    
    basePath = '/Users/Shared/Documents/experiments';

elseif isunix
    
    error('Unix not supported currently!')

end

%Construct the experiment path with the basepath, experiment name, and
%other arguments. This will be returned by the function. 
exptPath = fullfile(basePath,exptName,varargin{:});

end