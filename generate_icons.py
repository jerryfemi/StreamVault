import os
# pyrefly: ignore [missing-import]
from PIL import Image
import shutil

assets_dir = 'assets'
android_res_dir = 'android/app/src/main/res'
ios_runner_dir = 'ios/Runner'

# The generated images (update these paths)
cyberpunk_src = r'C:\Users\jerem\.gemini\antigravity-ide\brain\a7586ddc-d171-4265-9e39-85b357db5ef2\streamvault_cyberpunk_icon_1782557115763.png'
light_src = r'C:\Users\jerem\.gemini\antigravity-ide\brain\a7586ddc-d171-4265-9e39-85b357db5ef2\streamvault_light_icon_1782557128931.png'
basic_src = os.path.join(assets_dir, 'basic.png')

# Copy to assets/
cyberpunk_asset = os.path.join(assets_dir, 'cyberpunk.png')
light_asset = os.path.join(assets_dir, 'light.png')
shutil.copy(cyberpunk_src, cyberpunk_asset)
shutil.copy(light_src, light_asset)

icons = {
    'cyberpunk': cyberpunk_asset,
    'light': light_asset,
    'basic': basic_src,
}

android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

ios_sizes = {
    '@2x': 120,
    '@3x': 180,
}

for name, path in icons.items():
    print(f"Processing {name} from {path}")
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
    except Exception as e:
        print(f"Error opening {path}: {e}")
        continue
    
    # Android
    for folder, size in android_sizes.items():
        out_dir = os.path.join(android_res_dir, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f'ic_launcher_{name}.png')
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(out_path)
        print(f"  Saved {out_path}")
        
    # iOS
    for suffix, size in ios_sizes.items():
        out_path = os.path.join(ios_runner_dir, f'{name}_icon{suffix}.png')
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(out_path)
        print(f"  Saved {out_path}")

print("Done!")
