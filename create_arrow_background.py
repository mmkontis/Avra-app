#!/usr/bin/env python3
"""
WhisperMe DMG Background Creator
Creates a beautiful background image with arrow guide for DMG installer
"""

import os
import sys

# Try to import PIL, install if not available
try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Installing Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "--break-system-packages", "Pillow"])
    from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_dmg_background(width=600, height=400):
    """Create a beautiful DMG background with arrow guide"""
    
    # Create new image with gradient background
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    # Create gradient background
    for y in range(height):
        # Gradient from light blue to white
        r = 240 + int((255 - 240) * y / height)
        g = 248 + int((255 - 248) * y / height)
        b = 255
        draw.rectangle([(0, y), (width, y + 1)], fill=(r, g, b))
    
    # Add subtle pattern overlay
    for x in range(0, width, 50):
        for y in range(0, height, 50):
            draw.ellipse([(x-2, y-2), (x+2, y+2)], fill=(230, 240, 255, 50))
    
    # Draw the arrow
    arrow_color = (100, 150, 255)
    arrow_start_x = 180
    arrow_end_x = 420
    arrow_y = 200
    
    # Arrow shaft
    draw.line([(arrow_start_x, arrow_y), (arrow_end_x - 20, arrow_y)], 
              fill=arrow_color, width=4)
    
    # Arrow head
    arrow_points = [
        (arrow_end_x, arrow_y),
        (arrow_end_x - 20, arrow_y - 10),
        (arrow_end_x - 20, arrow_y + 10)
    ]
    draw.polygon(arrow_points, fill=arrow_color)
    
    # Add text instructions
    try:
        # Try to use a nice font if available
        font_size = 18
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
    except:
        font = None
    
    # Draw instruction text
    text_color = (60, 60, 60)
    if font:
        # Title
        title_text = "Install WhisperMe"
        title_bbox = draw.textbbox((0, 0), title_text, font=font)
        title_width = title_bbox[2] - title_bbox[0]
        draw.text(((width - title_width) // 2, 40), title_text, 
                  fill=text_color, font=font)
        
        # Instruction
        instruction_text = "Drag WhisperMe to Applications"
        inst_bbox = draw.textbbox((0, 0), instruction_text, font=font)
        inst_width = inst_bbox[2] - inst_bbox[0]
        draw.text(((width - inst_width) // 2, 250), instruction_text, 
                  fill=text_color, font=font)
    
    # Add app icon placeholder circle
    app_x, app_y = 120, 180
    draw.ellipse([(app_x - 40, app_y - 40), (app_x + 40, app_y + 40)], 
                 fill=(255, 255, 255), outline=arrow_color, width=2)
    
    # Add "🎤" emoji representation in the circle
    if font:
        draw.text((app_x - 15, app_y - 20), "🎤", fill=text_color, font=font)
    
    # Add Applications folder icon
    folder_x, folder_y = 480, 180
    draw.rectangle([(folder_x - 40, folder_y - 30), (folder_x + 40, folder_y + 30)], 
                   fill=(255, 255, 255), outline=arrow_color, width=2)
    
    # Add folder tab
    draw.rectangle([(folder_x - 40, folder_y - 40), (folder_x - 10, folder_y - 30)], 
                   fill=(255, 255, 255), outline=arrow_color, width=2)
    
    # Add "A" for Applications
    if font:
        draw.text((folder_x - 8, folder_y - 15), "A", fill=text_color, font=font)
    
    # Add subtle branding at bottom
    if font:
        brand_text = "WhisperMe - Audio Transcription Made Easy"
        try:
            small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 12)
        except:
            small_font = font
        
        brand_bbox = draw.textbbox((0, 0), brand_text, font=small_font)
        brand_width = brand_bbox[2] - brand_bbox[0]
        draw.text(((width - brand_width) // 2, height - 30), brand_text, 
                  fill=(150, 150, 150), font=small_font)
    
    return img

def main():
    """Main function to create and save the background"""
    print("🎨 Creating DMG background with arrow guide...")
    
    # Create the background
    background = create_dmg_background()
    
    # Save the background
    output_dir = "dmg-assets"
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, "dmg-background.png")
    background.save(output_path, "PNG")
    
    print(f"✅ Background saved to: {output_path}")
    print(f"📐 Size: 600x400 pixels")
    
    # Also create a retina version
    retina_background = create_dmg_background(1200, 800)
    retina_path = os.path.join(output_dir, "dmg-background@2x.png")
    retina_background.save(retina_path, "PNG")
    print(f"✅ Retina background saved to: {retina_path}")

if __name__ == "__main__":
    main() 