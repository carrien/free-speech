function [bSave] = savecheck(savefile,ftype)
%SAVECHECK  Checks for existence of file and confirms before overwriting.

if nargin < 2, ftype = 'file'; end

if exist(savefile, ftype)
    % setup for question box
    dlgOpts.Default = 'Cancel';
    dlgOpts.Interpreter = 'tex';
    [path, name, extension] = fileparts(savefile);
    path = strrep(path, '\', '/');
    colored_nameExt = sprintf('%s%s%s%s', '\color{blue}', name, extension, '\color{black}');

    % uses TeX formatting to change color and font size. See questdlg
    % documentation for help.
    messg = sprintf('%sThere is already a %s named %s here:\n\n%s\n\nDo you want to overwrite %s?', ...
        '\fontsize{10}', ftype, colored_nameExt, path, colored_nameExt);

    % present the question box
    response = questdlg(messg,'File exists','Overwrite','Cancel', dlgOpts);

    switch response
        case 'Overwrite'
            bSave = 1;
        case 'Cancel'
            bSave = 0;
    end

else % file doesn't exist; nothing to overwrite; safe to save
    bSave = 1;

end


end %EOF
