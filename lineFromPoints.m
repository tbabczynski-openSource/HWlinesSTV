function [linesTab, lineNums] = lineFromPoints(initialPoints, AH, sigma, im)
%LINEFROMPOINTS generates array of lines from series of points

i=0;
linesTab = {};
while(true)
	P=FindStarting(initialPoints);
	if isempty(P)
		break
	end
	points=P;
	while P(1) < size(initialPoints,2)
		[initialPoints, Q]=NextPoint(initialPoints, P, sigma, round(AH/2));
		if isempty(Q)
			break
		end
		points=[points; Q]; %#ok<AGROW>
		P=Q;
	end
	%Add only polylines containing enough lines
	if  size(points,1)>1 && points(end,1)-points(1,1) > 3*AH

      i=i+1;
      linesTab{i}=points; %#ok<AGROW>
 
      linesTab{i}=unique(...
        [max(1,linesTab{i}(1,1)-sigma), linesTab{i}(1,2);...
        linesTab{i};...
        min(size(initialPoints,2),linesTab{i}(end,1)+sigma), linesTab{i}(end,2)],...
        'rows'); %#ok<AGROW>

	else
		initialPoints(P(2),P(1))=0;
	end
end

mmm = cellfun(@(x) mean(x(:,2)), linesTab); %line sorting
[~,mmmo]=sort(mmm);
linesTab = linesTab(mmmo);

[linesTab, lineNums] = removeRedundantLines(linesTab,im, AH);

% imshow(im);
% hold on
% kol = lines;
% cellfun(@(x,y) plot(x(:,1),x(:,2), '-o', 'Color',kol(y,:)),linesTab, num2cell(lineNums));
% figure
% imshow(im);
% hold on
% cellfun(@(x) plot(x(:,1),x(:,2), '-o'),lines1);

end


%% helper functions


function [P] = FindStarting(inputImg)
%FINDSTARTING Find starting point in image looking left to right and up to down

  x_start=find(sum(inputImg(:,1:uint16(size(inputImg,2)*(2/2)))));
  if isempty(x_start)
    P=[];
    return
  end
  x_start=x_start(1);
  y_start=find(inputImg(:,x_start));
  y_start=y_start(1);
  P=[x_start, y_start];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [inputImg, Q] = NextPoint(inputImg, P, sigma, AH)
%NEXTPOINT Find next candidate point to be attached to the line

frame_xp=P(1);
frame_xk=min(P(1)+2*sigma-1, size(inputImg,2));
frame_yp=max(P(2)-AH, 1);
frame_yk=min(P(2)+AH, size(inputImg,1));
frame=inputImg(frame_yp:frame_yk , frame_xp+1:frame_xk);
% hold on; rectangle('Position',[frame_xp,frame_yp,frame_xk-frame_xp,frame_yk-frame_yp]);
% imshow(~frame);
[y, x]=find(frame);
if length(x)<2
    Q = [];
    return
end

P_local = P-[frame_xp,frame_yp];
dists=abs(y-P_local(2));
a = sum(x.*(y-P_local(2)))/sum(x.^2);

if abs(a)>tan(10*pi/180)
%     warning('jest zle');
    a = sign(a)*tan(10*pi/180);
end
y1=round(a*x+P_local(2));
dists=abs(y1-P_local(2));

minDist=min(dists);
idx = find(abs(dists-minDist) < 5);
nearest=[x(idx), y(idx)];

if isempty(nearest) 
  Q=[];
  inputImg(P(2),P(1))=0;
  return
end    
%Choose the farthest point in x coordinate
Q_local=nearest(end,:);
%Choose the nearest point in x coordinate
% Q_local=nearest(1,:);
%Transform local coordinates of Q to global ones
Q = Q_local+[frame_xp,frame_yp];
%Cleaning of already analyzed points
inputImg(frame_yp:frame_yk , frame_xp:Q(1))=0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [linesTab, lineNums] = removeRedundantLines(linesTab,im, AH)
%REMOVEREDUNDANTLINES removes lines pointing only to already pointed
%regions

	stats = regionprops(~im, 'BoundingBox');
	bboxes = cat(1,stats.BoundingBox);
  
	ind = bboxes(:,4)<AH/2 | bboxes(:,3)<3;
	bboxes(ind,:)=[];
	M = zeros(size(linesTab,2),size(bboxes,1),'logical');
	for bbind=1:size(bboxes,1)
		bb=bboxes(bbind,:);
		xlimit = [ceil(bb(1)), floor(bb(1))+bb(3)];
		ylimit = [ceil(bb(2)), floor(bb(2))+bb(4)];
		xbox = xlimit([1 1 2 2]);
		ybox = ylimit([1 2 2 1]);
		poly = polyshape(xbox,ybox);
		for llind=1:size(linesTab,2)
			ll=linesTab{llind};
			if max(ylimit)<min(ll(:,2)) ||... %whole bbox above line
               min(ylimit)>max(ll(:,2))       %whole bbox below line
				continue;
			end
			[in,~] = intersect(poly,ll);
			if ~isempty(in)
				M(llind,bbind) = true;
			end
		end
	end
	m1 = sum(M,1);
	ind = zeros(size(linesTab),'logical');
  for llind=1:size(linesTab,2)
    touchOthers = sum(m1(M(llind,:))>1);
    touchMy = sum(m1(M(llind,:))>0);
    if touchOthers>0 && touchOthers+3 > touchMy
      %all but max 3 crossed by another line
      ind(llind)=true;
    end
  end
	linesTab(ind)=[];
  
  %% glue lines

  lineNums = 1:size(linesTab,2);
  for linInd=1:size(linesTab,2)-1
    s1 = linesTab{linInd};
    s2 = linesTab{linInd+1}; %lines are sorted in y
 		if (abs(s1(1,2)-s2(end,2))< AH && ... % close in y dir (orig)
				abs(s1(1,1)-s2(end,1))<size(im,2)/2) || ... % close in x dir
				(abs(s2(1,2)-s1(end,2))< AH && ...
				abs(s2(1,1)-s1(end,1))<size(im,2)/2)
			lineNums(linInd+1:end) = lineNums(linInd+1:end)-1;
    elseif isLineNear(s1,s2,AH)
      lineNums(linInd+1:end) = lineNums(linInd+1:end)-1;
		end
  end

end

function b = isLineNear(l1, l2, AH)
%ISLINENEAR returns distance between two polylines in vertical direction

  if abs(max(l1(:,2))-min(l2(:,2))) > 2*AH && ...
      abs(max(l2(:,2))-min(l1(:,2))) > 2*AH
    b = false;
    return
  end
  try
    l2(l2(:,1)<(l1(1,1)-AH),:)=[];
    l1(l1(:,1)<(l2(1,1)-AH),:)=[];
    l2(l2(:,1)>(l1(end,1)+AH),:)=[];
    l1(l1(:,1)>(l2(end,1)+AH),:)=[];
  catch
    if isempty(l1) || isempty(l2)
      b = false;
      return
    end
  end
  if isempty(l1) || isempty(l2)
      b = false;
      return
  end
  maxdist = -1;
  for p1=l1'
    diffs = abs(l2-p1');
    try
      dists = hypot(diffs(1,:),diffs(2,:));
    catch
      dists = hypot(diffs(1),diffs(2));
    end
    if min(dists) > maxdist
      maxdist = min(dists);
    end
  end
  b=maxdist<0.7*AH;
end
