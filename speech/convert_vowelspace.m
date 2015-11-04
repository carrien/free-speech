function [ ] = convert_vowelspace(vowelspace_file)
%CONVERT_VOWELSPACE Convert vowelspace files to new version.

load(vowelspace_file)
if ~exist('hid_trials','var') || ~exist('head_trials','var') || ~exist('had_trials','var')
    error('File does not contain hid_, head_, and had_trials.')
end

trials4saystring.hid = hid_trials;
trials4saystring.head = head_trials;
trials4saystring.had = had_trials;

clear hid_trials head_trials had_trials;
save(vowelspace_file,'vowelspace','trials4saystring');