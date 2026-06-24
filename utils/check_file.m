function check_file(fileName)
% Code written by Shanqing Cai. Originally from github.com/shanqing-cai/commonmcode

if ~isfile(fileName)
    error('Failed to find file: %s', fileName);
end

return
