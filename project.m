% %working properly
% 
% clc; 
% clear all; 
% close all; 
% 
% %% ============================================================ 
% %% STEP-BY-STEP PROCESSING WITH BACKEND THEORY 
% %% ============================================================ 
% 
% %% ============================================================ 
% %% STEP 1: SELECT MRI 
% %% ============================================================ 
% showProgress('STEP 1: Loading MRI Image'); 
% [filename, pathname] = uigetfile({'*.jpg;*.png;*.jpeg;*.bmp'}, 'Select MRI Image'); 
% if isequal(filename,0) 
%     error('NO MRI image selected');
% end 
% 
% img = imread(fullfile(pathname, filename)); 
% figure('Name','STEP 1: Original Image'); 
% imshow(img); title('STEP 1: Original Image'); 
% disp('========== BACKEND STEP 1 =========='); 
% disp('Image selected:'); 
% disp(fullfile(pathname, filename)); 
% disp('Image size:'); 
% disp(size(img)); 
% disp("theory(step 1):");    
% disp("In this step, the MRI scan is loaded into the workspace. It is the raw input image"); 
% disp("for the tumor detection pipeline. No processing is applied yet."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 2: GRAYSCALE CONVERSION 
% %% ============================================================ 
% showProgress('STEP 2: Converting to Grayscale'); 
% if size(img,3)==3 
%     gray = rgb2gray(img); 
% else 
%     gray = img; 
% end 
% figure('Name','STEP 2: Grayscale Image'); 
% imshow(gray); title('STEP 2: Grayscale'); 
% disp('========== BACKEND STEP 2 =========='); 
% disp(gray(1:10,1:10)); 
% disp("THEORY (STEP 2):"); 
% disp("MRI images are converted to grayscale because intensity-based segmentation"); 
% disp("techniques work on single-channel images. This reduces complexity and noise."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 3: GAUSSIAN HIGH-PASS FILTER 
% %% ============================================================ 
% showProgress('STEP 3: Gaussian High Pass Filtering'); 
% h = fspecial('gaussian',[3 3],0.5); 
% lowpass = imfilter(im2double(gray), h); 
% highpass = imsubtract(im2double(gray), lowpass); 
% figure('Name','STEP 3: High Pass Filter'); 
% imshow(highpass,[]); title('STEP 3: High-Pass Filter'); 
% disp('========== BACKEND STEP 3 =========='); 
% disp('Gaussian Kernel:'); 
% disp(h); 
% disp("THEORY (STEP 3):"); 
% disp("High-pass filtering enhances edges by removing slow-varying intensities."); 
% disp("Tumor boundaries become more visible, helping in segmentation."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 4: MEDIAN FILTER 
% %% ============================================================ 
% showProgress('STEP 4: Median Filtering'); 
% med = medfilt2(gray,[15 15]); 
% figure('Name','STEP 4: Median Filtered'); 
% imshow(med); title('STEP 4: Median Filtered Image'); 
% disp('========== BACKEND STEP 4 =========='); 
% disp(med(1:10,1:10)); 
% disp("THEORY (STEP 4):"); 
% disp("Median filtering removes salt-and-pepper noise while preserving edges."); 
% disp("This improves tumor detection accuracy during thresholding stages."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 5: SUBTRACTION ENHANCEMENT 
% %% ============================================================ 
% showProgress('STEP 5: Image Enhancement'); 
% sub = imsubtract(im2double(gray), im2double(med)); 
% figure('Name','STEP 5: Enhanced by Subtraction'); 
% imshow(sub,[]); title('STEP 5: Enhanced by Subtraction'); 
% disp('========== BACKEND STEP 5 =========='); 
% disp(sub(1:10,1:10)); 
% disp("THEORY (STEP 5):"); 
% disp("Subtracting the median image enhances sharp regions like tumors."); 
% disp("It highlights intensity differences between normal and abnormal tissues."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 6: HISTOGRAM EQUALIZATION 
% %% ============================================================ 
% showProgress('STEP 6: Histogram Equalization'); 
% histEq = histeq(sub); 
% figure('Name','STEP 6: Histogram Equalized'); 
% imshow(histEq); title('STEP 6: Histogram Equalized'); 
% [counts, bins] = imhist(histEq); 
% disp("THEORY (STEP 6):"); 
% disp("Histogram equalization spreads intensity values and improves contrast."); 
% disp("Dark tumors or bright tumors become more distinguished from surroundings."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 7: HISTOGRAM GRAPH 
% %% ============================================================ 
% figure('Name','STEP 7: Histogram'); 
% imhist(histEq); title('STEP 7: Histogram'); grid on; 
% disp("THEORY (STEP 7):"); 
% disp("Histogram shows distribution of pixel intensities."); 
% disp("It helps in understanding contrast and segmentation thresholds."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 8: GRADIENT MAGNITUDE 
% %% ============================================================ 
% showProgress('STEP 8: Gradient Magnitude'); 
% gmag = imgradient(histEq); 
% figure('Name','STEP 8: Gradient Magnitude'); 
% imshow(gmag,[]); title('STEP 8: Gradient Magnitude'); 
% disp("THEORY (STEP 8):"); 
% disp("Gradient magnitude highlights rapid intensity changes."); 
% disp("Tumor edges produce strong gradients, useful for segmentation."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 9: INTENSITY-BASED TUMOR CANDIDATE ISOLATION 
% %% ============================================================ 
% showProgress('STEP 9: Tumor Candidate Isolation'); 
% smoothed = imgaussfilt(mat2gray(histEq),1);
% seTop = strel('disk',12);
% tophat = imtophat(smoothed, seTop);
% 
% Tglob = graythresh(tophat);
% bw_glob = imbinarize(tophat, Tglob + 0.02);
% bw_local = imbinarize(tophat, adaptthresh(tophat,0.45));
% 
% bw_comb = bw_glob | bw_local;
% bw_comb = imopen(bw_comb, strel('disk',3));
% bw_comb = imfill(bw_comb,'holes');
% bw_comb = bwareaopen(bw_comb,120);
% 
% figure('Name','STEP 9: Initial Tumor Candidates'); 
% imshow(bw_comb); title('STEP 9: Initial Tumor Candidates'); 
% disp("THEORY (STEP 9):"); 
% disp("Enhance bright blobs and use global + local thresholds to capture tumor."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 10: REMOVE BORDER / FILTER CANDIDATES 
% %% ============================================================ 
% showProgress('STEP 10: Remove border artifacts & filter candidates'); 
% bw_no_border = imclearborder(bw_comb);
% CC = bwconncomp(bw_no_border);
% props = regionprops(CC, 'Area','Centroid','Solidity','BoundingBox','Eccentricity');
% 
% areas = [props.Area]; sols=[props.Solidity]; eccs=[props.Eccentricity];
% validIdx = find(areas>200 & sols>0.4 & eccs<0.95);
% if isempty(validIdx)
%     validIdx = find(areas>200 & eccs<0.98);
% end
% if isempty(validIdx)
%     validIdx = 1:numel(props);
% end
% 
% mask_valid = false(size(bw_no_border));
% for ii=validIdx
%     mask_valid(CC.PixelIdxList{ii}) = true;
% end
% mask_valid = imfill(mask_valid,'holes');
% mask_valid = bwareaopen(mask_valid,100);
% 
% figure('Name','STEP 10: Valid Candidate Regions'); 
% imshow(mask_valid); title('STEP 10: Valid Candidate Regions (Filtered)'); 
% disp("THEORY (STEP 10):"); 
% disp("Filter candidate blobs by area, solidity, and shape to exclude non-tumor regions."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 11: SELECT MAIN TUMOR 
% %% ============================================================ 
% showProgress('STEP 11: Select main tumor region'); 
% CC2 = bwconncomp(mask_valid);
% props2 = regionprops(CC2,histEq,'Area','BoundingBox','Centroid','MeanIntensity');
% 
% [~, pickIdx] = max([props2.Area]);
% tumorMask = false(size(mask_valid));
% tumorMask(CC2.PixelIdxList{pickIdx}) = true;
% tumorMask = imclose(tumorMask, strel('disk',6));
% tumorMask = imfill(tumorMask,'holes');
% tumorMask = bwareaopen(tumorMask, round(props2(pickIdx).Area*0.03));
% 
% figure('Name','STEP 11: Selected Tumor Mask'); 
% imshow(tumorMask); title('STEP 11: Selected Tumor (Final Mask)'); 
% disp("THEORY (STEP 11):"); 
% disp("Select the largest interior blob as the plausible tumor."); 
% pause; 
% 
% %% ============================================================ 
% %% STEP 12: TUMOR DETECTION 
% %% ============================================================ 
% showProgress('STEP 12: Tumor Detection'); 
% stats = regionprops(tumorMask, histEq, 'Area','Centroid','BoundingBox','MeanIntensity'); 
% 
% figure('Name','STEP 12: Tumor Highlighted'); 
% imshow(gray); hold on; 
% 
% I = stats(1).MeanIntensity;
% if I>0.6, c='r'; tag='Malignant';
% elseif I>0.3, c='y'; tag='Benign';
% else, c='g'; tag='Normal'; end
% 
% rectangle('Position',stats(1).BoundingBox,'EdgeColor',c,'LineWidth',2); 
% plot(stats(1).Centroid(1),stats(1).Centroid(2),'b*'); 
% text(stats(1).Centroid(1),stats(1).Centroid(2)-10,tag,'Color',c,'FontSize',10,'FontWeight','bold'); 
% 
% disp("THEORY (STEP 12):"); 
% disp("Regionprops measures geometric properties of detected tumor region."); 
% disp("Mean intensity helps classify tumor as benign/malignant."); 
% pause; 
% 
% %% ============================================================ 
% %% DONE 
% %% ============================================================ 
% disp("==================================================="); 
% disp("PROCESSING COMPLETE — ALL BACKEND SHOWN"); 
% disp("==================================================="); 
% 
% %% ============================================================ 
% %% LOCAL FUNCTION — MUST STAY AT END 
% %% ============================================================ 
% function showProgress(msg) 
%     fprintf('\n%s', msg); 
%     pause(0.2); fprintf('.'); 
%     pause(0.2); fprintf('.'); 
%     pause(0.2); fprintf('.'); 
%     fprintf(' Done!\n\n'); 
% end
% 
% 
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


