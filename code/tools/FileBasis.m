function [geoVec,basis] = FileBasis(fileFullPath,basisParams)

% TODO - make "p" as the 3nd input instead of "basisParams"
p = GetParams_LSD();
if nargin < 2
    basisParams = GetBasisParams(p);
end

assert(ischar(fileFullPath))
assert(exist(fileFullPath,'file')==2)

[basisFile filename]  = GetPrecalcFilename(fileFullPath,'basis');

if ~p.recomputeBasis && ValidateFileContents(basisFile,basisParams)
    fprintf('loading basis for %s...',filename)
    l = load(basisFile);
    basis  = l.basis;
    geoVec = l.geoVec;
    
else
    lboData = FileLBO(fileFullPath);
    fprintf('calculating basis for %s...',filename)
    [geoVec,basis] = CalcBasis(lboData.evecs,lboData.evals,basisParams);
    save(basisFile, 'geoVec', 'basis', 'basisParams')

end
fprintf('Done.\n')


function isOk = ValidateFileContents(filePath,basisParams)
isOk = true;

if exist(filePath,'file')~=2
    isOk = false;
    return
end

fileVars = who('-file',filePath);
if ~any(strcmp(fileVars,'basisParams'))
    isOk = false;
    return
end

fileData = load(filePath,'basisParams');

if ~isequalwithequalnans(fileData.basisParams , basisParams)
    isOk = false;
    return
end
