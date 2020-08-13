function asciiVals = sendStringToTLL(string)
% Converts a string into ascii values, sends each to the TTL system
% 
% Conversion from string to ascii and back can be done like this:
% >> str = 'this is a test';
% >> asciiVals = double(str);
% >> newStr = char(asciiVals)


if ~isa(string,'cell')
    string = {string};
end

string = [string{:}];

ttl = ttlInterfaceClass.getTTLInterface;
asciiVals = ttl.sendStringAsEvent(string);