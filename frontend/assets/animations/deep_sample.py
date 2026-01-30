import cv2
import numpy as np

video_path = r"d:\Invispay\frontend\assets\animations\splash_animation.mp4"
cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print("Error: Could not open video.")
else:
    # Scan middle frame for better color representation
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    cap.set(cv2.CAP_PROP_POS_FRAMES, total_frames // 2)
    
    ret, frame = cap.read()
    if ret:
        height, width, _ = frame.shape
        
        # Sample the average of the first 10 rows and last 10 rows
        top_strip = frame[0:10, 0:width]
        bottom_strip = frame[height-10:height, 0:width]
        
        top_avg = np.mean(top_strip, axis=(0, 1))
        bottom_avg = np.mean(bottom_strip, axis=(0, 1))
        
        def bgr_to_hex(pixel):
            return "#{:02x}{:02x}{:02x}".format(int(pixel[2]), int(pixel[1]), int(pixel[0]))
            
        print(f"Top 10-row Average (Hex): {bgr_to_hex(top_avg)}")
        print(f"Bottom 10-row Average (Hex): {bgr_to_hex(bottom_avg)}")
        
        # Print RGB for precise Flutter Color objects
        print(f"Top RGB: {int(top_avg[2])}, {int(top_avg[1])}, {int(top_avg[0])}")
        print(f"Bottom RGB: {int(bottom_avg[2])}, {int(bottom_avg[1])}, {int(bottom_avg[0])}")

cap.release()
