function symLut = GetDatasetSym(folder,wildcard)

if ~isempty(strfind(folder,'tosca'))
    s = GetFirstShape(folder,wildcard);
    symLut = FindSymAlongAxis(s,1);

elseif ~isempty(strfind(folder,'scape')) || ~isempty(strfind(folder,'shrec'))
    s = GetFirstShape(folder,'*.mat');
    symLut = 1:numel(s.X);
    symLut(sign(s.X)~=sign(s.X(1))) = NaN;

else
    error('')
    %symLut = [];
    
end


function s = GetFirstShape(folder,wildcard)
files      = dir(fullfile(folder,wildcard));
firstFile  = fullfile(folder ,files(1).name);
s          = load_shape_sampled(firstFile);