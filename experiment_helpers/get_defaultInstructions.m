function [instruct] = get_defaultInstructions()
%GET_DEFAULTINSTRUCTIONS  Return default experiment instructions

instruct.introtxt = {'Read each word out loud as it appears.' '' 'Press the space bar to continue when ready.'};
instruct.readytxt = 'Get ready to SPEAK.';
instruct.breaktxt = 'Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the space bar to continue.';
instruct.thankstxt = 'Thank you!\n\n\n\nPlease wait.';
instruct.waittxt = 'Please wait.';
instruct.txtparams.Color = 'white';
instruct.txtparams.FontSize = 45;
instruct.txtparams.HorizontalAlignment = 'Center';

end
