startup
p = GetParams_LSD();

p.pathDataTrain = {};
p.wildCardTrain = {};
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'michael*.mat';
p.pathDataTrain{end+1} = fullfile(p.pathData ,'tosca');
p.wildCardTrain{end+1} = 'victoria*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh05*.mat';
% p.pathDataTrain{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTrain{end+1}  = 'mesh02*.mat';
p.pathDataTest  = {};
p.wildCardTest  = {};
p.pathDataTest{end+1}  = fullfile(p.pathData ,'tosca');
p.wildCardTest{end+1}  = 'david*.mat';
% p.pathDataTest{end+1}  = fullfile(p.pathData ,'scape');
% p.wildCardTest{end+1}  = 'mesh0*.mat';
p.removeTrainFromTest = 1;

p.descMaxDim = 16;%ceil(p.nBasisVecs / 2);
p.oldDescDim = p.descMaxDim;

% p.normalizeGeoVecs = 0;

alphaVals  = 0:.02:.5;
%%
trainRes = RunTraining(p,alphaVals);
allPerf  = BenchDescs(trainRes,p);
data = vertcat(allPerf.optCov);

%%
res = struct([]);
for a = 1:numel(alphaVals)
    
    if isempty(trainRes(a).COV)
        continue
    end

    res(a).size  = size(trainRes(a).COV,1);
    res(a).alpha = alphaVals(a);
    [res(a).eer,res(a).fpr1,res(a).fpr01, ~,~,~, ~,~,~...
        ,       res(a).fnr1,res(a).fnr01] = calculate_rates([data(:,a).dPos], [data(:,a).dNeg]);
    fprintf('calculate_rates done on alpha=%.3f\n',alphaVals(a))
    
end

% save test_alpha

%%

figure(24434)
clf
hold on
plot([res.alpha],[res.fpr01],'g--','linewidth',2,'displayname','FP @ FN = 0.1%')
plot([res.alpha],[res.fpr1], 'g'  ,'linewidth',2,'displayname','FP @ FN = 1%')
plot([res.alpha],[res.fnr01],'r--','linewidth',2,'displayname','FN @ FP = 0.1%')
plot([res.alpha],[res.fnr1], 'r'  ,'linewidth',2,'displayname','FN @ FP = 1%')
% plot([res.alpha],[res.eer],'displayname','EER')
% plot([res.alpha],[res.size],'displayname','# of dims')
[AX,H1,H2] = plotyy([res.alpha],[res.eer],[res.alpha],[res.size]);
set(H1,'linewidth',2,'Color','b','displayname','EER')
set(H2,'linewidth',2,'Color','m','displayname','# of dimensions')
set(AX(1),'YColor','k')
set(AX(2),'YColor','m')

set(AX,'YTickMode','auto')
tmp = [res.alpha];
set(AX,'XLim', tmp([1 end]))
% ylim(AX(2), [0 100] )

xlabel('\alpha')
ylabel(AX(1),'Error rate')
ylabel(AX(2),'# of descriptor dimensions')
legend show location best

%%

