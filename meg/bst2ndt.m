function [ ] = bst2ndt(exptName,snum,type)
%BST2NDT  Copy/convert Brainstorm epochs for the Neural Decoding Toolbox.
%   BST2NDT(EXPTNAME,SNUM,TYPE) -- TYPE can be "speak", "listen",
%   "speak_cvp", or "listen_cvp".

load(fullfile(getAcoustSubjPath(exptName,snum,'meg'),'expt'));  % Load expt info

switch type                                                     % Get trial groupings of interest
    case 'speak'
        eventInfo = get_eventInfo_vowel(getAcoustSubjPath(exptName,snum,'meg'),'speak');
        foldername = 'speak123';
    case 'speak_cvp'
        eventInfo = get_eventInfo_cvp(getAcoustSubjPath(exptName,snum,'meg'),'speak');
        foldername = 'speakcp';
    case 'listen'
        eventInfo = get_eventInfo_vowel(getAcoustSubjPath(exptName,snum,'meg'),'listen');
        foldername = 'listen123';
    case 'listen_cvp'
        eventInfo = get_eventInfo_cvp(getAcoustSubjPath(exptName,snum,'meg'),'listen');
        foldername = 'listencp';
end

%try                                                             % Get events:
%    eventFiles = get_bstEvents(exptName,snum);                  % load
%catch                                                           % or generate if needed
    eventFiles = save_bstEvents(get_bstRawFiles(exptName,snum),getMegSubjPath(exptName,snum));
%end
allevents = merge_events(eventFiles);                           % Merge into one file

trialinds = match_events2trialnums(expt,allevents,eventInfo);   % Trial match
bstTrialFolders = get_bstTrialFolders(exptName,snum,type);

newDataPath = fullfile('/projectnb/skiran/aphSISnb/ndtdata/',sprintf('s%02d',snum),foldername); % Set path for copying

gen_bstRenamedTrials(bstTrialFolders,trialinds,newDataPath);     % Make the copy

end
