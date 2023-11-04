function [labImg, linTab, linNums,AH] = TextLineSepSTV(binImg,sigma,phi, dbgLev)
  %TEXTLINESEPSTV Labeling of lines using tensor votig by steerable filters
  %   Function labels lines of text in binary image using the
  %   tensor votig by steerable filters
  %
  % input - binImg - binary image with 0s as background
  % sigma - voting scale
  % phi - angle threshold
  % dbgLev - level of debugging (showing the generated images at the stages of algorithm) - not implemented
  %
  % output - labImg - labeled image (uint8)
  % linTab - 
  % linNums - 
  % AH - average height of characters
  
  if ~(exist('dbgLev', 'var') && isnumeric(dbgLev))
    dbgLev = 0;
  end
  
  if ~(exist('sigma', 'var') && isnumeric(sigma))
    sigma = 50;
  end
  
  iw = size(binImg,2);
  saliency_threshold = 0.5; %maybe should be a parmeter but it was not varied in final experiments

%% 1: Calculate average character height
AH = average_height(binImg);

%% 2: Create initial tensor field
[sIn, oIn] = calcInitialField(binImg);

%% 3: Perform the dense voting
[sOut, bOut, oOut] = vote(sIn, oIn, sigma);

%% 4: Calculate the gradient
sOut = imgaussfilt(sOut,[3, 30]);
sOutMean = mean(sOut(:));
[dXsOut, dYsOut] = gradient(sOut);

%% 5: Select points probably belonging to lines
cond1_2 = [zeros(1,size(dYsOut,2),'logical');...
  dYsOut(3:end,:)<0 & dYsOut(1:end-2,:)>=0;...
  zeros(1,size(dYsOut,2),'logical')];
cond3  = sOut>saliency_threshold*sOutMean;
cond4  = abs(oOut) < phi*pi/180;

lineCandidates = cond1_2 & cond3 & cond4;

%% 6: Calculate lines
[linTab, linNums] = lineFromPoints(lineCandidates,AH,70,~binImg);

%% 7: Assign labels to pixels
  labImg(:,:) = labelsFromLines(linTab, linNums, binImg);
end

%% helper functions

function ah = average_height(img)
  if ~islogical(img)
    error('image should be binary but is %s', class(img));
  end
  s = regionprops(img, 'BoundingBox');
  bb = cat(1,s.BoundingBox);
  ah = round(mean(bb(:,4)));
end

