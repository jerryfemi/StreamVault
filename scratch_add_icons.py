# pyrefly: ignore [missing-import]
from pbxproj import XcodeProject
import os

project_path = r"c:\Users\jerem\StudioProjects\stream_vault\ios\Runner.xcodeproj\project.pbxproj"
project = XcodeProject.load(project_path)

icons = [
    "basic_icon@2x.png",
    "basic_icon@3x.png",
    "neon_icon@2x.png",
    "neon_icon@3x.png",
    "cyberpunk_icon@2x.png",
    "cyberpunk_icon@3x.png",
    "light_icon@2x.png",
    "light_icon@3x.png"
]

for icon in icons:
    icon_path = os.path.join(r"c:\Users\jerem\StudioProjects\stream_vault\ios\Runner", icon)
    try:
        project.add_file(icon_path, force=False)
        print(f"Added {icon}")
    except Exception as e:
        print(f"Failed to add {icon}: {e}")

project.save()
print("Saved project.")
