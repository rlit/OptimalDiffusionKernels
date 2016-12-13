function startup

p = GetParams_LSD();

assert(all(cellfun(@isdir,p.pathDataTest)) ,'not all test folders exit')
assert(all(cellfun(@isdir,p.pathDataTrain)),'not all training folders exit')

addpath(         p.pathCode)
addpath(fullfile(p.pathCode,'common'))
addpath(fullfile(p.pathCode,'algo'))
addpath(fullfile(p.pathCode,'tools'))
addpath(fullfile(p.pathCode,'3rd_party'))
addpath(fullfile(p.pathCode,'3rd_party','ply_io'))

