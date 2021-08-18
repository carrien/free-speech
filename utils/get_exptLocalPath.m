function [exptPath] = get_exptLocalPath(exptName,varargin)
%GET_EXPTLOCALPATH Return path to experiment folder on the local machine
%   GET_EXPTLOCALPATH(EXPTNAME,VARARGIN)
%       Returns the path to an experiment's (specified with EXPTNAME 
%       argument) local directory in the shared/public documents folder. If
%       no EXPTNAME is provided, returns the path to the computers
%       'experiments' folder. Can use VARARGIN to specify subfolders. 
%
%       Currently accounts for Mac vs PC distinction, and Lab PC vs iEEG
%       Cart PC.

if nargin < 1, exptName = []; end

if ispc
        %Handle iEEG cart machine 
        if strcmp(getenv('COMPUTERNAME'), 'DESKTOP-JM96JC7') %Saalmann Lab PC
            basePath = get_exptSavePathIEEG;
        else
            basePath = 'C:\Users\Public\Documents\experiments\';
        end
        
elseif ismac
    basePath = '/Users/Shared/Documents/experiments';
elseif isunix
    error('Unix not supported currently!')
end

exptPath = fullfile(basePath,exptName,varargin{:});