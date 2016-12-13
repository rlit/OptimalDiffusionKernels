function shape_rotated = RotateShape(shape,y,p,r)

shapeV = [shape.X shape.Y shape.Z];

% meanV = shapeV);
meanV = mean([
    max(shape.X) , min(shape.X),
    max(shape.Y) , min(shape.Y),
    max(shape.Z) , min(shape.Z)]');

shapeV = bsxfun(@minus,shapeV,meanV);
shapeV = shapeV * angle2dcm(y,p,r,'ZYX' );
shapeV = bsxfun(@plus,shapeV,meanV);

shape_rotated.TRIV = shape.TRIV;
shape_rotated.X = shapeV(:,1);
shape_rotated.Y = shapeV(:,2);
shape_rotated.Z = shapeV(:,3);