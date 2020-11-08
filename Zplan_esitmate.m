function  Zplan_esitmate(DataDir,SaveDir)
tic
ROIIDX =[620,890,1,1040]; % ROI lims for social side cage;  
maxArea = 200; 
lightsTh = exp(16.5);
labFunc = @rgb2lab;
load('color_pred_model_august.mat'); 
minLum = 15;

MovieFolders = dir(DataDir);
MovieFolders = MovieFolders(3:end); 

for folderNum = 2:size(MovieFolders,1)
folderName = [MovieFolders(folderNum).folder,'\',MovieFolders(folderNum).name]; 
folderName

MovieFiles = dir(folderName);
MovieFiles = MovieFiles(3:end); 

centroidLocs = [];
Areas = []; 
Zbats = []; 
Zresults  = []; 
predColors = []; 
predPosterior = [];

for fileNum = 1:size(MovieFiles,1) 
fileNum
fileName = [MovieFiles(fileNum).folder,'\',MovieFiles(fileNum).name]; 
v = VideoReader(fileName);

i = 1;
v.CurrentTime = 0;
while hasFrame(v) 
   f = readFrame(v);
   if sum(f,'all') < lightsTh
   bw = getFrameMask(f,'ROI',ROIIDX);
  [centros,prop,cc] = findLEDcentroid(bw); 
  centroidLocs{i} = centros;
  Areas{i} = [prop.Area];
  Zbats(i)= sum([prop.Area]<maxArea); 
  
  regionLabels = 1:cc.NumObjects; % prepare to iterate through each region detected in findLEDCentroid
    if ~isempty(regionLabels)
        for region_k = regionLabels
            if prop(region_k).Area > maxArea 
            regionIdx = cc.PixelIdxList{region_k};
            f = reshape(f,[],3);
            regionRGB = f(regionIdx,:);
            regionLab = labFunc(regionRGB);
            regionLab = regionLab(regionLab(:,1) > minLum,:);
            color_mat(region_k,:) = squeeze(median(regionLab(:,2:3))); % take the median a and b values for those pixels
            else
            
            end
        end
  
   [predColors{i},predPosterior{i}] = predict(color_pred_model_august.ClassificationSVM  ,color_mat);
  
   i = i+1;
   else
   end
   end 
end

Zresults(fileNum).centroidLocs = centroidLocs;
Zresults(fileNum).Areas = Areas; 
Zresults(fileNum).Zbats = Zbats;
Zresults(fileNum).predColors = predColors;
Zresults(fileNum).predPosterior = predPosterior;
end

saveName = [SaveDir,'\Zresults_',MovieFolders(folderNum).name]; 
save(saveName,'Zresults')  


end

end

