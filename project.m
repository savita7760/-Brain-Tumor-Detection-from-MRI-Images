clc;
clear all;
close all;

%% ============================================================
%% STEP 1: SELECT MRI IMAGE
%% ============================================================
showProgress('STEP 1: Loading MRI Image');
[filename, pathname] = uigetfile({'*.jpg;*.png;*.jpeg;*.bmp'}, 'Select MRI Image');

if isequal(filename,0)
    error('NO MRI IMAGE SELECTED');
end

img = imread(fullfile(pathname, filename));

figure('Name','STEP 1: Original Image'); 
imshow(img); title('STEP 1: Original Image');
pause;


%% ============================================================
%% STEP 2: GRAYSCALE
%% ============================================================
showProgress('STEP 2: Converting to Grayscale');

if size(img,3)==3
    gray = rgb2gray(img);
else
    gray = img;
end

figure('Name','STEP 2: Grayscale');
imshow(gray); title('Grayscale');
pause;


%% ============================================================
%% STEP 3: HIGH-PASS FILTER
%% ============================================================
showProgress('STEP 3: Gaussian High-Pass Filter');

h = fspecial('gaussian',[3 3],0.5);
lowpass = imfilter(im2double(gray), h);
highpass = imsubtract(im2double(gray), lowpass);

figure('Name','STEP 3: High Pass');
imshow(highpass,[]); title('High-Pass Filter');
pause;


%% ============================================================
%% STEP 4: MEDIAN FILTER
%% ============================================================
showProgress('STEP 4: Median Filter');

med = medfilt2(gray,[15 15]);

figure('Name','STEP 4: Median Filter');
imshow(med); title('Median Filtered');
pause;


%% ============================================================
%% STEP 5: SUBTRACTION
%% ============================================================
showProgress('STEP 5: Subtraction Enhancement');

sub = imsubtract(im2double(gray), im2double(med));

figure('Name','STEP 5: Enhanced');
imshow(sub,[]); title('Enhanced by Subtraction');
pause;


%% ============================================================
%% STEP 6: HISTOGRAM EQUALIZATION
%% ============================================================
showProgress('STEP 6: Histogram Equalization');

histEq = histeq(sub);

figure('Name','STEP 6: Histogram Equalized');
imshow(histEq); title('Histogram Equalized');
pause;


%% ============================================================
%% STEP 7: HISTOGRAM
%% ============================================================
figure('Name','STEP 7: Histogram');
imhist(histEq); title('Histogram');
pause;


%% ============================================================
%% STEP 8: GRADIENT
%% ============================================================
showProgress('STEP 8: Gradient Magnitude');

gmag = imgradient(histEq);

figure('Name','STEP 8: Gradient Magnitude');
imshow(gmag,[]); title('Gradient Magnitude');
pause;


%% ============================================================
%% STEP 9: INITIAL TUMOR CANDIDATES
%% ============================================================
showProgress('STEP 9: Tumor Candidate Isolation');

smoothed = imgaussfilt(mat2gray(histEq),1);
se = strel('disk',12);
tophat = imtophat(smoothed, se);

Tglobal = graythresh(tophat);
bw_g = imbinarize(tophat, max(0, Tglobal - 0.02));
bw_l = imbinarize(tophat, adaptthresh(tophat, 0.45));

bw = bw_g | bw_l;
bw = imopen(bw, strel('disk',3));
bw = imfill(bw,'holes');
bw = bwareaopen(bw,80);


%% ============================================================
%% NEW STEP 9.5: REMOVE OUTSIDE-BRAIN AREAS
%% ============================================================
showProgress('STEP 9.5: Removing Outside-Brain Regions');

brainMask = imclose(gray > graythresh(gray)*255, strel('disk',20));
brainMask = bwareafilt(brainMask, 1);
brainMask = imfill(brainMask,'holes');

bw = bw & brainMask;
bw = bwareaopen(bw,100);


figure('Name','STEP 9: Initial Candidates');
imshow(bw); title('Initial Tumor Candidates (Cleaned)');
pause;


%% ============================================================
%% STEP 10: REMOVE BORDER REGIONS
%% ============================================================
showProgress('STEP 10: Removing Border Regions');

bw2 = imclearborder(bw);
CC = bwconncomp(bw2);
props = regionprops(CC,'Area','Solidity','Eccentricity');

areas = [props.Area];
sols  = [props.Solidity];
ecc   = [props.Eccentricity];

valid = find(areas > 50 & sols > 0.25 & ecc < 0.98);
if isempty(valid)
    valid = 1:numel(props);
end

mask = false(size(bw2));
for k = valid
    mask(CC.PixelIdxList{k}) = true;
end

mask = imfill(mask,'holes');
mask = bwareaopen(mask,50);

figure('Name','STEP 10: Filtered Regions');
imshow(mask); title('Filtered Regions');
pause;


%% ============================================================
%% STEP 11: TUMOR SELECTION (FINAL)
%% ============================================================
showProgress('STEP 11: Selecting Main Tumor Region');

origNorm = mat2gray(gray);
CC2 = bwconncomp(mask);
props2 = regionprops(CC2, origNorm, ...
    'Area','BoundingBox','Centroid','MeanIntensity','Solidity');

if isempty(props2)
    error("NO VALID TUMOR REGION DETECTED");
end

areas = [props2.Area];
ints  = [props2.MeanIntensity];
sols  = [props2.Solidity];

NA = areas / max(areas);
NI = ints / max(ints);
NS = sols / max(sols);

FinalScore = 0.6*NI + 0.3*NS + 0.1*NA;

[~, idx] = max(FinalScore);

tumorMask = false(size(mask));
tumorMask(CC2.PixelIdxList{idx}) = true;
tumorMask = imclose(tumorMask, strel('disk',5));
tumorMask = imfill(tumorMask,'holes');

figure('Name','STEP 11: Final Tumor Mask');
imshow(tumorMask); title('Final Tumor Mask');
pause;


%% ============================================================
%% STEP 12: FINAL OUTPUT
%% ============================================================
showProgress('STEP 12: Final Tumor Detection');

stats = regionprops(tumorMask, origNorm, ...
    'Area','BoundingBox','Centroid','MeanIntensity');

figure('Name','STEP 12: Tumor Detected');
imshow(gray); hold on;

M = stats(1).MeanIntensity;

if M > 0.65
    boxColor='r'; type='Malignant';
elseif M > 0.35
    boxColor='y'; type='Benign';
else
    boxColor='g'; type='Normal';
end

rectangle('Position',stats(1).BoundingBox,'EdgeColor',boxColor,'LineWidth',2);
plot(stats(1).Centroid(1),stats(1).Centroid(2),'b*','MarkerSize',10);
text(stats(1).Centroid(1),stats(1).Centroid(2)-15,...
     type,'Color',boxColor,'FontSize',12,'FontWeight','bold');

hold off;

disp("==== PROCESS COMPLETED SUCCESSFULLY ====");


%% ============================================================
%% LOCAL FUNCTION
%% ============================================================
function showProgress(msg)
    fprintf('\n%s', msg);
    pause(0.1); fprintf('.');
    pause(0.1); fprintf('.');
    pause(0.1); fprintf('.');
    fprintf(' Done!\n');
end

