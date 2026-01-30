import cv2
import numpy as np

video_path = r"d:\Invispay\frontend\assets\animations\splash_animation.mp4"
cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print("Error: Could not open video.")
else:
    ret, frame = cap.read()
    if ret:
        # Sample top center and bottom center pixels
        height, width, _ = frame.shape
        top_pixel = frame[5, width // 2]
        bottom_pixel = frame[height - 6, width // 2]
        
        # Convert BGR to Hex
        def bgr_to_hex(pixel):
            return "#{:02x}{:02x}{:02x}".format(pixel[2], pixel[1], pixel[0])
            
        print(f"Top boundary pixel (Hex): {bgr_to_hex(top_pixel)}")
        print(f"Bottom boundary pixel (Hex): {bgr_to_hex(bottom_pixel)}")
        
        # Check if they are the same
        if np.array_equal(top_pixel, bottom_pixel):
            print("Solid background detected.")
        else:
            print("Gradient background detected.")

cap.release()
