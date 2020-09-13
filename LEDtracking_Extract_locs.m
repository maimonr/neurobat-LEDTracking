function [filtered_xy, filledGaps_xy] = LEDtracking_Extract_locs(file, varargin)
% First-pass analysis of location data taken from the raw results of the LED_tracking model for a given day. 

% first, we remove douplicaitons of color per frame (if you already have the variable locs saved you can load it and it will skip this first part*) 
% We then transpose the xy values to be able to empose the XY limts of cage top
% next, we filter and fill in gaps in data. finally, we calcuate measures of the distances and movments of bats. then plot 
% INPUTS: 
% 1)file: the dir location and and name of prediction results to load (could be Day_predciton alone )
% optional: 
% 2)filtRank: the rank of the median filter used to smooth data (scalar, #frames) 
% 3)movWindow: the size of the moving window for filling the gaps if useing defult (movMedian), (scalar, #frames) 
% 4)GapTh: if we want to limit to only gaps of a certain size or under we specify this (scalar, #frames)
% 5)GapMethod: if we gave Gapth, we can now choose the method, e.g change to 'spline', (string)
 
% * the variable should be named locs in the workspace, it is a variable with 3D. the 1D(rows) is number of frames for the whole day
% the 2D(colomns) is number of colors(e.g 8), 3D is x,y values for each frame. e.g for dimentions: 144314x8x2.    

pnames = {'filtRank','movWindow','GapTh','GapMethod'};
dflts  = {5,40,[],'linear'};
[filtRank, movWindow, GapTh, GapMethod] = internal.stats.parseArgs(pnames,dflts,varargin{:});

% prepare some things:
load(file); 

     

load('color_pred_model_august'); 
color_names = color_pred_model_august.ClassificationSVM.ClassNames;    % should be this: {'az','ch','gr','or','rd','re','sp','vi'}' 
numberOfcolors = size(color_names,1); 
 
if ~exist('locs') % if you already calc. locs, then you can skip part 1. 
    
% (1) Remove times when a color is predicted more then once by taking only the max posterior predcition blob. 
for MovieNum = 1:size(centroidLocs,2) 
    for frame_k = 1:size(centroidLocs{1,MovieNum},2)  
        for color_k = 1:numberOfcolors 
        current_color_idx = strcmp(predColors{MovieNum}{frame_k},color_names{color_k}); 
            if sum(current_color_idx) > 1 
            pred_class_idx = strcmp(color_names,color_names(color_k,:)); 
            current_pred_posteriors = predPosterior{MovieNum}{frame_k}(current_color_idx,pred_class_idx);  
                if length(unique(current_pred_posteriors)) == 1 
                pred_centroids(frame_k,color_k,1:2) = NaN; 
                    continue
                else % This catches all times when we have more then one prediction of a specifc color, and usues max posterior choose one. 
                [~,pred_posterior_idx] = max(current_pred_posteriors);
                current_color_idx = find(current_color_idx);
                current_color_idx = current_color_idx(pred_posterior_idx);
                end
         elseif sum(current_color_idx) == 0
            pred_centroids(frame_k,color_k,1:2) = NaN;
                continue
         end
        pred_centroids(frame_k,color_k,:) = centroidLocs{MovieNum}{frame_k}(current_color_idx,:); 
        end
    end
    Day_prediction(MovieNum) = {pred_centroids}; 
    pred_centroids = []; 
end 
locs = cat(1,Day_prediction{:});
 else 
end     

%% (2) here we rotate so we can limit x,y to max limits, med_filter the data, fill gaps.  
load('ROI_rot.mat'); % this struc contains the rotation matrix, limts of x and y and center of cage values
for colorIndx = 1:8 % we run this analysis bat by bat (e.i color by color) 

% "rotate" pixels    
locsXY = [locs(:,colorIndx,1)';locs(:,colorIndx,2)']; % etract the x,y of a specific color 
C = repmat(ROI_rot.c,size(locsXY,2),1)'; % prepare a matrix to substrcut and readd the cetner values after rot. 
locsXY_rot=((ROI_rot.R*(locsXY-C))+C)'; % rotate all points around center(C) of polygon (cage top) 

% enforce x,y min/max limtis for stepping out of cage top bounds 
x = locsXY_rot(:,1); 
x(x<ROI_rot.xlims(1)) = ROI_rot.xlims(1);
x(x>ROI_rot.xlims(2)) = ROI_rot.xlims(2); 

y = locsXY_rot(:,2); 
y(y<ROI_rot.ylims(1)) = ROI_rot.ylims(1); 
y(y>ROI_rot.ylims(2)) = ROI_rot.ylims(2); 

% median filter 
x = medfilt1(x,filtRank); 
y = medfilt1(y,filtRank); 

% gap filling: 
  if ~isempty(GapTh) % if gapTh was given, then we fill gap by gap  
       xGapMatrix = bwlabel(isnan(x)); % fast way to tag gaps by using bwlable to find "connceted" regions of logical mtraix in 1D, and lable them
        NumofGaps = max(xGapMatrix); 
    xF = x; % will will be making changes directly to vector, so we create a duplicate 
    yF = y; % same 
            for gapIndx = 1:NumofGaps  
     gapFrames = find(xGapMatrix == gapIndx); % find the frames that we need to fill 
     Gapstart = gapFrames(1)-5; % add smaples before and after gap for extrapolating. 
     Gapend = gapFrames(end)+5;
                if size(gapFrames,1) < GapTh &&  Gapstart>=1 && Gapend<=size(xF,1) % only if the gap is small enough, and not out of bounds 
        xfill = fillmissing(xF(Gapstart:Gapend),GapMethod,'SamplePoints',(Gapstart:Gapend)); 
        xF(Gapstart:Gapend) = xfill; 
        yfill = fillmissing(yF(Gapstart:Gapend),GapMethod,'SamplePoints',(Gapstart:Gapend)); 
        yF(Gapstart:Gapend) = yfill; 
                else  
                end     
            end         
  else % if we did not give a gapTh, then we run it on the whole trace using the median moving window
        xF = fillmissing(x,'movmedian',movWindow); 
        yF = fillmissing(y,'movmedian',movWindow);
  end  

% collecting the results: 
filtered_xy{colorIndx} = [x,y]; 
filledGaps_xy{colorIndx} = [xF,yF]; 
end 


%% plotting data 
rgb_colors = {0 0.5 1;0.5 1 0;0 1 0;1 0.5 0;1 0 0;1 0 0.5;0 1 0.5;0.5 0 1}; % this makes sense for AgustModel. it might not if we make another...

figure; 
set(gcf,'Color','white','Position',[80 80 1100 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    plot(filledGaps_xy{colorIdx}(:,1),'k', 'lineWidth',0.1); hold on; 
    plot(filtered_xy{colorIdx}(:,1),'Color',cell2mat(rgb_colors(colorIdx,:))); 
    title(color_names(colorIdx));  
end 
suptitle('x,y over time (fills in black)');

figure; 
set(gcf,'Color','white','Position',[80 80 1100 550]);
for colorIdx = 1:numberOfcolors
    subplot(2,4,colorIdx)
    scatter(filledGaps_xy{colorIdx}(:,1),filledGaps_xy{colorIdx}(:,2),2,'r.'); hold on; 
    scatter(filtered_xy{colorIdx}(:,1),filtered_xy{colorIdx}(:,2),2,'k.'); hold on; 
    title(color_names(colorIdx)); % xlim([ROI_rot.xlims(1) ROI_rot.xlims(2)]); ylim([ROI_rot.ylims(1) ROI_rot.ylims(2)]) 
end 



end 



