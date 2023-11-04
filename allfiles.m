% collect statistics for the whole directory

DirInfo = dir ('ICDAR2009/*.tif');

%filter out names that do not conform to competition naming schema: 3 digits dot tif
DirInfo(cellfun(@(x) isempty(regexp(x,'[0-9]{3}\.tif', 'once')),{DirInfo.name})) =[];

phis = [1,5:5:50];

sigmas = [30 50 70 90 100 110 130 150];

if (exist('results','var')==0 || size(results,1)~=size(DirInfo,1) || ...
    size(results,3)~=size(sigmas,2) || size(results,4)~=size(phis,2))
  results = zeros(size(DirInfo,1),3,size(sigmas,2),size(phis,2));
end
if (exist('bads','var')==0 || size(bads,1)~=size(DirInfo,1) || ...
    size(bads,3)~=size(sigmas,2) || size(bads,4)~=size(phis,2))
  bads = zeros(size(DirInfo,1),30,size(sigmas,2),size(phis,2));
end
alltime=tic;
for f=1:size(DirInfo,1)
% for f=[62] %if you want only one file to proceed
  inputPath = [DirInfo(f).folder, '/', DirInfo(f).name];
  fprintf(1,'%3d %s current time %0.1f(min)\n',f,inputPath,toc(alltime)/60);
  binImg = readExample(inputPath,0);
  sn=1;
  for sigma=sigmas
    pn=1;
    for phi=phis
      fprintf(1,'.');
      [labImg,~,linie,AH] = TextLineSepSTV(binImg,sigma,phi,0); %
      AHs(f) = AH; %#ok<SAGROW>
      [o2o_cnt, M, N, bad] = matchScore(labImg,inputPath);
      results(f,:,sn,pn)=[o2o_cnt, M, N]; %#ok<SAGROW>
      if ~isempty(bad)
        bads(f,1:length(bad),sn,pn)=bad; %#ok<SAGROW>
        fprintf(1,'s/p=%d/%d bad lines: ',sigma, phi);
        fprintf(1,'%d ',bad);
        fprintf(1,'\n');
      end
      pn=pn+1;
    end
    sn=sn+1;
  end

end

toc(alltime); 

result = squeeze(sum(results));
% stats(:,1,:)=o2o/M=RA, stats(:,2,:)=o2o/N=DR
stats = [results(:,1,:,:)./results(:,2,:,:), ...
	results(:,1,:,:)./results(:,3,:,:), ...
	FM(results(:,1,:,:)./results(:,2,:,:),results(:,1,:,:)./results(:,3,:,:))];
if numel(result)>3 %there was more than one values of parameters
	stat = [result(1,:,:)./result(2,:,:); result(1,:,:)./result(3,:,:); ...
		FM(result(1,:,:)./result(2,:,:), result(1,:,:)./result(3,:,:))];
else
	stat = [result(1)./result(2); result(1)./result(3); ...
		FM(result(1)./result(2), result(1)./result(3))];
end
return;

%% save results

%example
save(['TMP','results_ICDAR09_','STV_',datestr(now,'yymmdd'),...
'_lines_sr00_kat_',...
sprintf('_sWin%d-%d',int16(sigmas(1)),int16(sigmas(end))),...
sprintf('_Prog%d-%d',int16(10*phis(1)),int16(10*phis(end))),...
'.mat'],...
  'sigmas','phis','stat','stats','result','results','bads');
