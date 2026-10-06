---
name: opencv-document-analysis
description: >-
  Preprocess scanned documents, detect optical marks (OMR, bubble forms, checkboxes, smileys),
  apply perspective transforms, adaptive thresholding, and contour analysis using Python OpenCV
  and NumPy. Use when building or debugging document evaluators, scanner pipelines, or image grading tools.
---

# OpenCV Document Analysis & OMR Skill

This skill provides patterns for robust optical mark recognition (OMR), questionnaire evaluation, and document preprocessing using OpenCV in Python.

## 1. Core Image Processing Pipeline

1. **Grayscale Conversion & Denoising**:
   - `cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)`
   - `cv2.GaussianBlur(gray, (5, 5), 0)`
2. **Edge Detection & Corner Finding**:
   - `cv2.Canny(blurred, 75, 200)`
   - Find document boundaries and apply 4-point perspective warp (`cv2.getPerspectiveTransform` and `cv2.warpPerspective`).
3. **Adaptive Thresholding / Binarization**:
   - `cv2.adaptiveThreshold(warped, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2)`
   - Alternative for solid fills: Otsu's thresholding (`cv2.threshold(..., cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)`).
4. **Contour Extraction & Filtering**:
   - Filter contours by aspect ratio, minimum/maximum area, and circularity/solidity.
   - Sort contours top-to-bottom and left-to-right for grid evaluation.

## 2. Bubble & Smiley Fill Ratio Calculation
- For each bounding box / ROI:
  - Count non-zero pixels: `total_pixels = cv2.countNonZero(roi_thresh)`
  - Calculate fill percentage against total ROI area.
  - Determine marked choice based on threshold percentage (e.g. > 45% filled).

## 3. Debugging & Verification
- Save intermediate visual debug masks (`alignment_diff.png`, `binary.jpg`, bounding box overlays).
- Ensure tolerance against minor rotations, uneven lighting, and mobile camera skew.
