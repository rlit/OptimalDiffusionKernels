function DownSampleDataset(folder,wildCard,maxShapeVertices)

d = dir(fullfile(folder,wildCard));
filename = @(i)fullfile(folder,d(i).name);

shape = load_shape(filename(1));

if numel(shape.X) > maxShapeVertices
    isRemesh = true;
    [shape,origIdx] = PerformRemesh(shape,maxShapeVertices);
    newTRIV = shape.TRIV;
    shape.origIdx = origIdx;
    
    % create sym lut
    
    filenameDownSampled = GetPrecalcFilename(filename(1),'sampled');
    save(filenameDownSampled,'shape')
    
else
    isRemesh = false;
    CopyLocal(filename(1))
    
end


for ii = 2:numel(d)
    if isRemesh
        shape = load_shape(filename(ii));
        shape = ApplyRemesh(shape,origIdx,newTRIV);
        shape.origIdx = origIdx;

        filenameDownSampled = GetPrecalcFilename(filename(ii),'sampled');
        save(filenameDownSampled,'shape')

    else
        CopyLocal(filename(ii))
    end
end

function CopyLocal(filename)
filenameDownSampled = GetPrecalcFilename(filename,'sampled');
[success, message] = copyfile(filename,filenameDownSampled);
assert(success,message)

function [shape_remeshed,origIdx] = PerformRemesh(shape,maxShapeVertices)
opt = struct('vertices',maxShapeVertices,'verbose',0,'placement',0,'faces',0);
shape_remeshed = remesh(shape,opt);

locs = @(s)[s.X s.Y s.Z]';
tree = ann('init', locs(shape) );
[origIdx d]   = ann('search', tree, locs(shape_remeshed), 1, 'eps', 0);
ann('deinit', tree);
%%
assert(max(d) < max(range(locs(shape)')) * eps('single')*10,...
    'new points cause error bigger than the one cause by conversion to single')
return
%% validate symmetry
% % isym_=isym(origIdx);
% locs = @(s,i)[s.X(i) s.Y(i) s.Z(i)]';
% tree = ann('init', locs(shape,origIdx) );
% [isym_ d]   = ann('search', tree, locs(shape,isym(origIdx)), 1, 'eps', 0);
% ann('deinit', tree);
% % max(isym_)
% hist(d,50)
% %%
% figure(34)
% clf
% PlotShape(shape_remeshed,1)
% hold on
% PlotPoints = @(idx,clr)plot3(...
%     shape_remeshed.X(idx),...
%     shape_remeshed.Y(idx),...
%     shape_remeshed.Z(idx),...
%     'ok','MarkerFaceColor',clr,...
%     'MarkerSize',5);
% idx = 10000;
% PlotPoints(idx,'b')
% PlotPoints(isym_(idx),'r')
% %%
% toSave.isym = isym_;
% save('0001.null.0.sym.mat','-struct', 'toSave', 'isym')
function shape_reduced = ApplyRemesh(shape,idxsToKeep,newTRIV)
shape_reduced.X    = shape.X(idxsToKeep);
shape_reduced.Y    = shape.Y(idxsToKeep);
shape_reduced.Z    = shape.Z(idxsToKeep);
shape_reduced.TRIV = newTRIV;
