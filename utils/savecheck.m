function [bSave] = savecheck(savefile,ftype)
%SAVECHECK  Checks for existence of file and confirms before overwriting.

if nargin < 2, ftype = 'file'; end

if exist(savefile, ftype)
    % setup for question box
    dlgOpts.Default = 'Cancel';
    dlgOpts.Interpreter = 'tex';
    [path, name, extension] = fileparts(savefile);
    path = strrep(path, '\', '/');

    % escape tex special characters
    path = addTexEscapeChars(path);
    name = addTexEscapeChars(name);
    extension = addTexEscapeChars(extension);

    colored_nameExt = sprintf('%s%s%s%s', '\color{blue}', name, extension, '\color{black}');

    % To fix issue with `textwrap` in `questdlg` where TeX commands can be
    % split across lines after 75 characters, proactively add some newlines
    if length(path) > 75
        new_path = '';
        charCount = 0; % Counter to track characters since last newline

        for i = 1:length(path)
            new_path = [new_path, path(i)]; %#ok<AGROW> Append character
            charCount = charCount + 1;

            % If forward slash and near-ish the 75th character, add newline
            if path(i) == '/' && charCount > 52
                new_path = [new_path, newline]; %#ok<AGROW> Append newline
                charCount = 0; % Reset character counter
            end
        end
        path = new_path;
    end

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


    function text = addTexEscapeChars(text) % escape characters that would otherwise be considered tex commands
    specialChars = {'#' '$' '%' '&' '_' '{' '}'};
    for char = specialChars
        text = strrep(text, char{1}, sprintf('%s%s', '\', char{1}));
    end

    end


end %EOF
