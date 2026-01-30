import cv2
import numpy as np

video_path = r"d:\Invispay\frontend\assets\animations\splash_animation.mp4"
cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print("Error: Could not open video.")
else:
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"Resolution: {width}x{height}")
    print(f"FPS: {fps}")

    # Read the first frame to save it as an image for review
    ret, frame = cap.read()
    if ret:
        cv2.imwrite(r"d:\Invispay\frontend\assets\animations\splash_frame_ref.png", frame)
        print("Reference frame saved to d:\\Invispay\\frontend\\assets\\animations\\splash_frame_ref.png")

cap.release()
