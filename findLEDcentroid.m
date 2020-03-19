
function [centroidLocs, BigestCentro, meanCentro] = findLEDcentroid(bw) 
 meanCentro = []; 

CC = bwconncomp(bw, 8); % find connected regions (everything that is near a pixl (8 options))
Props = regionprops(CC); % regionprops is the function that gives us centorides and such 
centroidLocs = round((cat(1,Props.Centroid))); % store centroids for use using cat function to put them together. also round them as they represent a pixel  
[areamax indexmax]  = max(max(cat(1,Props.Area))); % store areas of centroides 
 
% find biggest area centorid 
if areamax >= 5
    BigestCentro(1,1) = centroidLocs(indexmax,1); 
    BigestCentro(1,2) = centroidLocs(indexmax,2);
else
       BigestCentro = [];
end

% merge close by centrodis 
if size(centroidLocs,1) > 1 
    
if (max(abs(diff(centroidLocs(:,1)))) < 250) && (max(abs(diff(centroidLocs(:,2)))) < 250) 
        meanCentro(1,1) = mean(centroidLocs(:,1));
        meanCentro(1,2) = mean(centroidLocs(:,2));
else
    meanCentro = []; 
end 
end
end 



% if centroidLocs > 1
% clusters = rangesearch(centroidLocs,centroidLocs,250,'SortIndices',false); % this gives indexes of nearby centorids
% clusters = unique(cell2mat(clusters),'rows'); % this turns cell to mat and removes duplicates of clustre
% clustredCentro = mean(centroidLocs((clusters)));
% end