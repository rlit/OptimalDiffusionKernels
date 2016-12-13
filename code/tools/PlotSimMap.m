function PlotSimMap(shape,idx,desc,descName,descAtIdx)
p = GetParams_LSD();
if ~exist('descAtIdx','var')
    descAtIdx = desc(:,idx);
end
%%

dif = bsxfun(@minus,desc,descAtIdx);
descDist   = sqrt(sum(dif.^2,1))';

fPlot = figure('color','w','renderer','zbuffer','units','pixels','position',[100 100 550 550]);
PlotShape(shape,descDist)
view(0,0)

hold on
plot3(...
    shape.X(idx),...
    shape.Y(idx),...
    shape.Z(idx),...
    'ok','MarkerFaceColor','w',...
    'MarkerSize',7)
set(fPlot,'name',descName,'numberTitle','off')

set(gca,'clim',prctile(descDist,[0 p.maxPrctileToPlot]))
colorbar

%%
saveDir = fullfile(p.pathDataTest,'SimMaps');
MakeDir(saveDir)
nameStr = sprintf('%s_%s',descName,datestr(now,30));
nameStr = fullfile(saveDir,nameStr);

saveas(fPlot,[nameStr,'.png'])
saveas(fPlot,[nameStr,'.fig'])
%%
% shading interp