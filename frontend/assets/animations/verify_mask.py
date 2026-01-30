import cv2
import numpy as np
import os

video_path = r"d:\Invispay\frontend\assets\animations\splash_animation.mp4"
output_path = r"d:\Invispay\frontend\assets\animations\splash_animation_temp.mp4"
frame_ref_path = r"d:\Invispay\frontend\assets\animations\test_mask.png"

# Watermark ROI (Region of Interest) at bottom right
# Based on 720x1280 resolution
# The "runway" text is roughly at 1150-1250 height and 550-700 width
# We will draw a white box on a black mask for this area.
mask_x, mask_y, mask_w, mask_h = 580, 1180, 130, 60

cap = cv2.VideoCapture(video_path)
ret, frame = cap.read()
if ret:
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.rectangle(mask, (mask_x, mask_y), (mask_x + mask_w, mask_y + mask_h), 255, -1)
    
    # Save a test image to verify the mask position
    test_frame = frame.copy()
    cv2.rectangle(test_frame, (mask_x, mask_y), (mask_x + mask_w, mask_y + mask_h), (0, 255, 0), 2)
    cv2.imwrite(frame_ref_path, test_frame)
    print(f"Verify mask location at: {frame_ref_path}")

cap.release()
