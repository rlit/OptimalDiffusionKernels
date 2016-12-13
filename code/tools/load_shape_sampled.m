function shape = load_shape_sampled(filename)
[p,n] = fileparts(filename);
filename_sampled = fullfile(p,[n '.mat']);
shape = load_shape(GetPrecalcFilename(filename_sampled,'sampled'));
% add scaling factor