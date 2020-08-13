function isValid = checkFIDValidity(fid)
% Function that uses brute force approach to check and see whether or not a
% passed fid (see fopen) is valid or not.
isValid = false;
try %#ok<TRYNC>
    ftell(fid);
    isValid = true;
end