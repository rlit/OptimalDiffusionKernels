p = GetParams_LSD();

foldeOut = fullfile(p.pathData ,'shrec07');
foldeIn = fullfile(foldeOut ,'off');
foldeDel = fullfile(foldeOut ,'removed shapes');

d = dir([foldeIn  '\*.off']);

for ii = 1:numel(d)
    t=tic;
    resName = [foldeOut  '\' strrep( d(ii).name,'off','mat')];
    if exist(resName,'file')
        l = load(resName);
        sampName = GetPrecalcFilename(resName,'sampled');
        if exist(sampName,'file') || numel(l.shape.X) <= p.maxShapeVertices
            continue
        end
        opt = struct('vertices',p.maxShapeVertices,'verbose',0,'placement',0,'faces',0);
        shape = remesh(l.shape,opt);
        
        locs = @(s)[s.X s.Y s.Z]';
        tree = ann('init', locs(l.shape) );
        [shape.origIdx d_]   = ann('search', tree, locs(shape), 1, 'eps', 0);
        ann('deinit', tree);
        assert(max(d_) < max(range(locs(l.shape)')) * eps('single')*10,...
            'new points cause error bigger than the one cause by conversion to single')

        save(sampName,'shape')
        fprintf('%d/%d - remesh %13s - took %.1f \n',ii ,numel(d),d(ii).name,toc(t))
        continue
    end
    try
        
    shape = load_shape([foldeIn  '\' d(ii).name]);
    
    if numel(shape.X) < p.maxShapeVertices
        continue
    end
        
    [~, evals] = CalcLBO(shape,p);
    shape = ScaleShape(shape,sqrt(evals(end)/.12));
    
    save(resName,'shape')
    catch
        try
            movefile([foldeIn  '\' d(ii).name],[foldeDel  '\' d(ii).name])
        catch
            d(ii).name
        end
    end
    fprintf('%d/%d - %20s - took %.1f \n',ii ,numel(d),d(ii).name,toc(t))
    
end

%%
return
%%
d = dir([folder  '\*.mat']);

pngDir = fullfile(folder,'PNGs');
if ~isdir(pngDir), mkdir(pngDir),end

fPlot = figure('color','w','renderer','zbuffer','units','pixels','position',[100 100 550 550]);
colormap(0.9*[1 .95 0.85])

for ii = 1:numel(d)
    
    pngName = [pngDir  '\' strrep( d(ii).name,'mat','png')];
    if exist(pngName,'file')
        %continue
    end
    l = load([folder  '\' d(ii).name]);
    
    clf(fPlot)
    a = axes('parent',fPlot,'units','normalized','position',[0 0 1 1]);

    
    PlotShape(l.shape)
    %PlotShape(RotateShape(l.shape,0,-pi/2,pi/2))
    view(3)
    light;
    lighting phong;
    camlight head;
    
    saveas(fPlot,pngName)
    continue

    % render
    pngName = [pngDir  '\' strrep( d(ii).name,'mat','png')];
    fRender = myaa(6);
    saveas(fRender,pngName)
    close(fRender)

end
%%
close all
return
%%
figure(34)
clf
PlotShape(shape,1)
hold on
PlotPoints = @(idx,clr)plot3(...
    shape.X(idx),...
    shape.Y(idx),...
    shape.Z(idx),...
    'ok','MarkerFaceColor',clr,...
    'MarkerSize',5);
%[~,idx] = max(shape.Z);
idx = lut(7106);
PlotPoints(idx,'b')
