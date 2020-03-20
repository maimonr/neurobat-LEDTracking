function hsvTable = get_hsv_lims(baseDir)

hsv_fnames = dir(fullfile(baseDir,'hsv_*.mat'));
color_names = arrayfun(@(x) regexp(x.name,'(?<=hsv_).*?(?=.mat)','match'),hsv_fnames,'un',0);
color_names = [color_names{:}];
nLims = length(hsv_fnames);
hsvLims = cell(1,nLims);
for color_k = 1:nLims
    s = load(fullfile(hsv_fnames(color_k).folder,hsv_fnames(color_k).name));
    hsvLims{color_k} = s.hsv;
end

hsvTable = table(hsvLims{:},'VariableNames',color_names);

end