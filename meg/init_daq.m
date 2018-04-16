function [obj,address] = init_daq()
%INIT_DAQ  Initialize DAQ device at MCW MEG.

obj = io64();                           % create object handle
status = io64(obj);                     %#ok<NASGU> % auto-install kernal I/O driver
address = get_daqAddress('trigger');    % get address for sending triggers
trigger_meg_mcw(obj,address,0);         % send a 0
