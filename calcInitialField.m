function [s, o] = calcInitialField(image)
%%CALCINITIALFIELD Create starting tensor field
%   in the form of saliency and orientation fields
%   put s=1 and o=0 on each position where 
%   original image has something in foreground (>0)
%
%   Input:
%    image - binary image with 1's as foreground
%
%   Returns scalar fields:
%    s - saliency field
%    o - orientation field (angle in radians)
%

  s = double(image>0);
  o = zeros(size(image));
end

