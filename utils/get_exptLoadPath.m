 function [exptPath] = get_exptLoadPath(exptName,varargin)

if nargin < 1, exptName = []; end

nesstComputers = {'WHITTAKER', 'PERTWEE', 'TENNANT', 'DAVISON', 'BAKER', 'MCCOY', 'MCGANN', 'CHLPR-CSJZ3M3' 'CHLPR-GMVD6J3'}; 
bjorndahlComputers = {'P-CBJORN'}; 

if ispc
    % Adjustment for using at NeSST Lab
    computerName = getenv('COMPUTERNAME');
    if contains(computerName, 'LEWIS221') || contains(computerName, 'CLARK6E') || ismember(computerName, nesstComputers)
        username = getenv('USERNAME'); 
        if strcmp(computerName, 'WHITTAKER')
            % Dumb workaround for Whittaker
            basePath = ['D:\Users\' username '\OneDrive - University of Missouri\nesstlab\experiments\']; 
        else
            basePath = ['C:\Users\' username '\OneDrive - University of Missouri\nesstlab\experiments\']; 
        end
    elseif ismember(computerName, bjorndahlComputers)
        basePath = 'C:\Users\Public\Documents\experiments\'; % This needs to change when Christina gets her server or whatever set up 
    else
        basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\';
    end    
    
elseif ismac
    basePath = '/Volumes/smng/experiments/';
    if ~isfolder(basePath)
        basePath = '/Volumes/wc/experiments/';
    end
elseif isunix
    basePath = '/mnt/smng/experiments/'; %% placeholder
else
    basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\'; %% placeholder
end

exptPath = fullfile(basePath,exptName,varargin{:});
