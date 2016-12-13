function lutOut = FilterLUT(lutIn,idxsToKeep)


maxIdx = max(cellfun(@max,lutIn));
[tf,loc] = ismember(1:maxIdx,idxsToKeep);

lutOut = cellfun(@(v){FixLutElement(v,tf',loc')},lutIn);


function out = FixLutElement(in,isValidIdx,newIdxVal)

inFilt = in(isValidIdx(in));
out = newIdxVal(inFilt);