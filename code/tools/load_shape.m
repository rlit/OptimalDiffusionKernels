function shape = load_shape(filename)

if ~exist(filename,'file')
    error('load_shape:file_not_found','file "%s" not found',filename)
end

[dummy, dummy, ext] = fileparts(filename); %#ok<ASGLU>

switch ext
    case '.off'
        shape = load_off(filename);
%     case '.obj'
%         shape = load_obj(filename);
    case '.ply'
        shape = load_ply(filename);
    case '.mat'
        shape = load_mat(filename);
    otherwise
        error('unspported extention')
end

function shape = load_off(input_file_name)
try
    shape = loadoff(input_file_name);
catch %#ok<CTCH>
    [node,elem] = readoff(input_file_name);
    shape.TRIV = elem;
    shape.X = node(:,1);
    shape.Y = node(:,2);
    shape.Z = node(:,3);
end

function shape = load_obj(input_file_name)
[ node_num, face_num, normal_num, order_max ] = obj_size ( input_file_name );
[ node_xyz, face_order, face_node ] = ...
    obj_read ( input_file_name, node_num, face_num, normal_num, order_max ); %#ok<ASGLU>
shape.TRIV = face_node';
shape.X = node_xyz(1,:)';
shape.Y = node_xyz(2,:)';
shape.Z = node_xyz(3,:)';

function shape = load_ply(input_file_name)
[TRI,PTS] = ply_read ( input_file_name, 'tri' );
shape.TRIV = TRI';
shape.X = PTS(1,:)';
shape.Y = PTS(2,:)';
shape.Z = PTS(3,:)';

function shape = load_mat(input_file_name)
loadRes = load(input_file_name);
if isfield(loadRes,'shape')
    shape = loadRes.shape;
elseif isfield(loadRes,'surface')
    shape = loadRes.surface;
else
    error
end

    