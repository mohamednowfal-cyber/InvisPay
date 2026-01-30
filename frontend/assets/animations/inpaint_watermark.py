import cv2
import numpy as np
import os

video_path = r"d:\Invispay\frontend\assets\animations\splash_animation.mp4"
output_path = r"d:\Invispay\frontend\assets\animations\splash_animation_temp.mp4"

# Watermark ROI coordiantes (720x1280 resolution)
# These are conservative estimates to cover "runway" without touching "INVISPAY"
mask_x, mask_y, mask_w, mask_h = 560, 1170, 150, 80

cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print("Error: Could not open video.")
    exit()

width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS)
fourcc = cv2.VideoWriter_fourcc(*'mp4v') # Using mp4v for compatibility

out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

# Create persistent mask
mask = np.zeros((height, width), dtype=np.uint8)
cv2.rectangle(mask, (mask_x, mask_y), (mask_x + mask_w, mask_y + mask_h), 255, -1)

print("Starting pixel-level inpainting...")
frame_count = 0
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Inpaint the region to remove watermark
    # radius of 3 is usually good for text
    dst = cv2.inpaint(frame, mask, 3, cv2.INPAINT_TELEA)
    
    out.write(dst)
    frame_count += 1
    if frame_count % 10 == 0:
        print(f"Processed {frame_count} frames...")

cap.release()
out.release()
print(f"Finished. Output saved to {output_path}")
