function new_angles = convert_cw2ccw(old_angles)
% converts clockwise rotations to counter-clockwise rotations

new_angles = 180-old_angles;
new_angles(new_angles<0) = new_angles(new_angles<0)+180;