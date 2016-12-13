function RunTest(p,trainRes,testName)

% - 
%
startup
if nargin < 1 
    p = GetParams_LSD();
end

if nargin < 2
p.descMaxDim = 64;
p.oldDescDim = p.descMaxDim;

%     p.alphaVals  = 2.^(-5:.5:-4  -2:.5:-1);
    p.alphaVals  = 2.^( -3:.5:-2);
%     p.alphaVals  = 2.^( -2.5:.25:-1.25);
%     p.alphaVals  = [alphaVals 1-alphaVals];

    trainRes = RunTraining(p);
    
end

if nargin < 3
    testName = datestr(now,'yyyy-mm-dd_HH-MM-SS_');
end

for c = 1:numel(p.pathDataTest)
    allPerf{c} = BenchDescs(trainRes,p,c); %#ok<AGROW>
end

saveDir = fullfile(p.pathData,'perf_plots',testName);
MakeDir(saveDir)
save(fullfile(saveDir,'trainRes.mat'),'trainRes','p')
PlotPerfCurves([allPerf{:}],saveDir);


function SavePlot(f,fileName)
t = tempname;
saveas(f, t, 'png');  movefile([t '.png'],[fileName '.png']); 
saveas(f, t, 'fig');  movefile([t '.fig'],[fileName '.fig']); 
saveas(f, t, 'epsc'); movefile([t '.eps'],[fileName '.eps']); 

function PlotPerfCurves(allPerf,saveDir)
nOptVals = numel(allPerf(1).alpha);

clrs = {'r','g','b','m','c'};
if nOptVals>numel(clrs)
clrs = num2cell( jet(nOptVals),2);
end

f.Cmc  = figure('visible','off');hold on
f.RocP = figure('visible','off');hold on;set(gca,'XScale','log')
f.RocN = figure('visible','off');hold on;set(gca,'XScale','log')

tmp = [allPerf.Wks];
AddToPlots(f,tmp,'-','WKS','k')

tmp = [allPerf.Hks];
AddToPlots(f,tmp,'--','HKS','k')


catCov = vertcat(allPerf.optCov);
catMmp = vertcat(allPerf.optMmp);
for ii = 1:nOptVals
    AddToPlots(f,catCov(:,ii),'-' ,sprintf('OPT Cov \\alpha=%.3f',allPerf(1).alpha(ii)),clrs{ii})
    AddToPlots(f,catMmp(:,ii),'--',sprintf('OPT Mmp \\alpha=%.3f',allPerf(1).alpha(ii)),clrs{ii})
end

figure(f.Cmc);
xlabel('% of best matches')
ylabel('Hit rate (%)')
% legend show location best 

warning off MATLAB:Axes:NegativeDataInLogAxis

figure(f.RocP);
xlabel FP
ylabel TP
xlim(10.^([-3 0]))
ylim([0 1])
% legend show location best

figure(f.RocN);
xlabel FN
ylabel TN
xlim(10.^([-3 0]))
ylim([0 1])
% legend show location best

warning on MATLAB:Axes:NegativeDataInLogAxis

for plotName = fieldnames(f)';
    n = plotName{1};
    SavePlot(f.(n),fullfile(saveDir,n))
end

function AddToPlots(f,data,styl,name,clr)
linewidth = 2;

if isempty([data.dPos]),return;end
    
nVert = [data.nVert];
assert(all(nVert(1) == nVert))
cmcY = 100*mean([data.cmc],2);
cmcX = 100*(1:numel(cmcY))/nVert(1);
set(0,'currentFigure',f.Cmc);
plot(cmcX,cmcY,styl,'displayname',name,'color',clr,'linewidth',linewidth);% return

% return

[eer,~,~,~,~,~,~,fp,fn] = calculate_rates([data.dPos], [data.dNeg]);
rocName = sprintf('%s -eer=%.2f%%',name,100*eer);

set(0,'currentFigure',f.RocP);
semilogx(fp,1-fn,styl,'displayname',rocName,'color',clr,'linewidth',linewidth);

set(0,'currentFigure',f.RocN);
semilogx(fn,1-fp,styl,'displayname',rocName,'color',clr,'linewidth',linewidth);
