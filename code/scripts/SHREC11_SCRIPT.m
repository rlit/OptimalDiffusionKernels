p = GetParams_LSD();

folder = fullfile(p.pathData ,'shrec11');

d = dir([folder  '\*.off']);

for ii = 1:numel(d)
    resName = [folder  '\' strrep( d(ii).name,'off','mat')];
    if exist(resName,'file')
%         continue
    end
    shape = load_shape([folder  '\' d(ii).name]);
    
    if isempty(strfind(d(ii).name,'null'))
        
        l = load([folder  '\corr\' strrep( d(ii).name,'off','corr.lut.mat')]);
        tree = ann('init', [null.X null.Y null.Z ]' );
        [lut, dist]   = ann('search', tree, l.lut', 1, 'eps', 0);
        ann('deinit', tree);
        assert(max(dist)==0)
        
        [~,perm] = sort(lut);
        shape.X = shape.X(perm);
        shape.Y = shape.Y(perm);
        shape.Z = shape.Z(perm);
        shape.TRIV = double(lut(shape.TRIV));
    else
        null = shape;
    end
    %     t       =  shape.X;
    %     shape.X =  shape.Z;
    %     shape.Y = -shape.Y;
    %     shape.Z = t;
    shape = ScaleShape(shape,1/1.13);
    
    
    save(resName,'shape')
end

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