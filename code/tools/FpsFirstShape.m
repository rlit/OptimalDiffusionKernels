function fpsData = FpsFirstShape(folder,wildcard,nFpsSamples,useSym,saveAllDistances)
files = dir(fullfile(folder,wildcard));
fileName = fullfile(folder ,files(1).name);

if nargin >3 && isequal(useSym,1)
    symLut = GetDatasetSym(folder,wildcard);
else
    symLut  = [];
end

if ~exist('saveAllDistances','var')
    saveAllDistances = 0;
end

fpsData = FileFPS(fileName,nFpsSamples,symLut,saveAllDistances);
