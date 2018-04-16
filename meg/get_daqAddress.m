function [address] = get_daqAddress(type)
%GET_DAQADDRESS  Returns DAQ address for sending and receiving triggers.

switch type
    case 'trigger'
        address = hex2dec('C050');
    case 'button'
        address = hex2dec('C051');
    otherwise
        error('Known address types are ''trigger'' and ''button''.')
end
