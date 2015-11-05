function [bSave] = savecheck(savefile,ftype)
%SAVECHECK  Checks for existence of file and confirms before overwriting.

if nargin < 2, ftype = 'file'; end

if exist(savefile, ftype)
    messg = sprintf('The %s %s exists.  Do you want to overwrite?',ftype,savefile);
    button = questdlg(messg,'File exists','Overwrite','Cancel','Cancel');
    
    switch button
        case 'Overwrite'
            bSave = 1;
        case 'Cancel'
            bSave = 0;
    end
    
else bSave = 1;
    
end