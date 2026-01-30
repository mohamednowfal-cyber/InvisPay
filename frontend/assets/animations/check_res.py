import cv2
import sys

def check_video(path):
    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        print(f"Error: Could not open video {path}")
        return
    
    width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
    height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
    fps = cap.get(cv2.CAP_PROP_FPS)
    count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    
    print(f"Resolution: {int(width)}x{int(height)}")
    print(f"FPS: {fps}")
    print(f"Frame count: {int(count)}")
    cap.release()

if __name__ == "__main__":
    check_video("assets/animations/splash_animation.mp4")
