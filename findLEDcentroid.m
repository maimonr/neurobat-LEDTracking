function [centroidLocs,props,labelIm] = findLEDcentroid(bw,varargin)

% find the centroids of the connected region(s) in a binary image mask and
% merge close-by regions if requested.
% INPUTS:
% bw: binary mask of an image (h x w)
% mergeThresh: number of pixels below which nearby regions are recursively
% merged. Leave empty if merging is not requested.
% connectivity: input for function bwlabel, should probably leave at 8
% minArea: minimum area for an region to be considered
% OUTPUTS:
% centroidLocs: location (in pixels) of centroids of region(s) in bw
% props: regionprops output regarding the region(s) in bw
% labelIm: image mask of the same size as bw with each region labeled as a
% unique number

pnames = {'mergeThresh','connectivity','minArea'};
dflts  = {[],8,50};
[mergeThresh,conn,minArea] = internal.stats.parseArgs(pnames,dflts,varargin{:});

labelIm = bwlabel(bw,conn); % find connected regions (everything that is near a pixl (8 options))
props = regionprops(bw,{'Area','Centroid','BoundingBox'}); % regionprops is the function that gives us centroids and area
centroidLocs = round(vertcat(props.Centroid)); % round centroids to pixel values

% merge close by centrodis
if size(centroidLocs,1) > 1 && ~isempty(mergeThresh)
    [centroidLocs,props,labelIm]  = mergeCentroids(labelIm,mergeThresh);
    usedIdx = ~all(isnan(centroidLocs),2);
    centroidLocs = centroidLocs(usedIdx,:);
    props = props(usedIdx);
end

usedIdx = [props.Area] > minArea;
centroidLocs = centroidLocs(usedIdx,:);
props = props(usedIdx);
imLabels = labelIm(labelIm~=0);
imLabels = setdiff(unique(imLabels(:)),0)';
for k = imLabels(~usedIdx)
    labelIm(labelIm == k) = 0;
end

end

function [centroidLocs,props,labelIm] = mergeCentroids(labelIm,mergeThresh)

props = regionprops(labelIm,{'Area','Centroid','BoundingBox'}); % regionprops is the function that gives us centorides and such
centroidLocs = round(vertcat(props.Centroid)); % store centroids for use using cat function to put them together. also round them as they represent a pixel

D = pdist(centroidLocs);
D = squareform(D);

mergeIdx = D < mergeThresh;
mergeIdx(logical(eye(size(mergeIdx)))) = false;
[row,col] = find(mergeIdx);

if ~isempty(row)
    mergePairs = [row col];
    mergePairs = sort(mergePairs,2);
    mergePairs = unique(mergePairs,'rows');
    
    n_merge_pairs = size(mergePairs,1);
    mergeDist = zeros(1,n_merge_pairs);
    for pair_k = 1:n_merge_pairs
        mergeDist(pair_k) = D(mergePairs(pair_k,1),mergePairs(pair_k,2));
    end
    
    [~,min_dist_idx] = min(mergeDist);
    min_dist_pair = mergePairs(min_dist_idx,:);
    labelIm(labelIm == min_dist_pair(2)) = min_dist_pair(1);
    
    [centroidLocs,props,labelIm] = mergeCentroids(labelIm,mergeThresh);
    
else
    return
end

end