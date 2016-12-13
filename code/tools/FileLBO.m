function [lboData] = FileLBO(fileFullPath,sampleIdxs)


assert(ischar(fileFullPath))
assert(exist(fileFullPath,'file')==2)

[lboFile filename] = GetPrecalcFilename(fileFullPath,'lbo');

p = GetParams_LSD();
if ~p.recomputeLbo && exist(lboFile,'file')==2
    % TODO - add test if params changded
    fprintf('loading LBO for %s...',filename)
    lboData = load(lboFile);
    
else
    % load shape from file
    shape = load_shape_sampled(fileFullPath);
    
    fprintf('calculating LBO for %s...',filename)
    % TODO - add params as input to CalcLBO
    [lboData.evecs lboData.evals lboData.area] = CalcLBO(shape);
    if nargin>1 && ~isempty(sampleIdxs)
        lboData.evecs = lboData.evecs(sampleIdxs,:);
    end

    save(lboFile,'-struct', 'lboData', 'evecs','evals','area')

end
fprintf('Done.\n')
