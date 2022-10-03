function [] = set_subjOstParams(trackingFileLoc, trackingFileName, paramsStruct, origCalc)
% Small function for resetting OST working based on lines.
%
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% NOTE: This function has a wrapper: set_subjOstParams_auto. You should
% probably be calling the wrapper from your function, rather than calling
% this directly. If you want to set the OST file to something other than
% the most recent/most precise version of the OST settings, then you should
% continue to use this function.
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% 
% dataPath: where the expt file is
% Updated 2021/5/24 to take care of third parameter
% 
% Updated 6/22/2021 to deal with taking parameters from data files that do not have trackingFileName, etc. Makes more
% parallel to set_ost. Note that if you are doing it via data you should only feed in one trial at a time, e.g. paramsStruct
% would be data(1), not just data 
% 
% Inputs: 
% 1. trackingFileLoc: folder where the tracking file is located
% 2. trackingFileName: name of the tracking file
% 3. paramsStruct: the structure that will have either subjOstParams or calcSubjOstParams in it
% 4. origCalc: 'orig' if you want to use subjOstParams, 'calc' if you want to use calcSubjOstParams (i.e. params that you set
% after the experiment is over) 
% 
% 


dbstop if error

%% Defaults

if nargin < 1 || isempty(trackingFileLoc), trackingFileLoc = 'experiment_helpers'; end
if nargin < 2 || isempty(trackingFileName), trackingFileName = 'measureFormants'; end
% assume expt for the load in, instead of data 
if nargin < 3 || isempty(paramsStruct)
    load(fullfile(pwd,'expt.mat'), 'expt');
    paramsStruct = expt;
end
if nargin < 4 || isempty(origCalc), origCalc = 'orig'; end

%%

switch origCalc
    case 'orig'
        ostField2Use = 'subjOstParams'; 
    case 'calc'
        ostField2Use = 'calcSubjOstParams';         
end

if isempty(paramsStruct.(ostField2Use))
    warning('The field %s is empty; no changes will be made', ostField2Use)
end


% if isfield(expt,'trackingFileLoc')
%     trackingFileLoc = expt.trackingFileLoc; 
% elseif isfield(expt,'trackingFileDir')
%     trackingFileLoc = expt.trackingFileDir; 
% else
%     trackingFileLoc = expt.name; 
% end

% if isfield(expt,'trackingFileName')
%     trackingFileName = expt.trackingFileName; 
% elseif isfield(expt,'dummyWord')
%     trackingFileName = expt.dummyWord;
% else 
%     trackingFileName = 'measureFormants'; 
% end

% for structure where you may store different OST file information in one expt (e.g. taimComp?) 
if isfield(paramsStruct.(ostField2Use), trackingFileName)
    for o = 1:length(paramsStruct.(ostField2Use).(trackingFileName))
        ostDescript = paramsStruct.(ostField2Use).(trackingFileName){o};
        try
            set_ost(trackingFileLoc, trackingFileName, ostDescript{1},ostDescript{2},ostDescript{3},ostDescript{4},ostDescript{5}); % Updated to handle third parameter
        catch
            set_ost(trackingFileLoc, trackingFileName, ostDescript{1},ostDescript{2},ostDescript{3},ostDescript{4});
        end
    end
else
    for o = 1:length(paramsStruct.(ostField2Use))
        ostDescript = paramsStruct.(ostField2Use){o};
        try
            set_ost(trackingFileLoc, trackingFileName, ostDescript{1},ostDescript{2},ostDescript{3},ostDescript{4},ostDescript{5}); % Updated to handle third parameter
        catch
            set_ost(trackingFileLoc, trackingFileName, ostDescript{1},ostDescript{2},ostDescript{3},ostDescript{4});
        end
    end
end

end