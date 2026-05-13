import os
from PySide6.QtGui import QImage, QPainter, QColor
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtCore import QSize, Qt

# App name and paths
app_name = "识图"
android_dir = "android"
res_dir = os.path.join(android_dir, "res")

# Create directories
os.makedirs(android_dir, exist_ok=True)
os.makedirs(os.path.join(res_dir, "values"), exist_ok=True)

# Write strings.xml
strings_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">{app_name}</string>
</resources>
"""
with open(os.path.join(res_dir, "values", "strings.xml"), "w", encoding="utf-8") as f:
    f.write(strings_xml)

# Write AndroidManifest.xml (minimal Qt6 template)
manifest_xml = """<?xml version="1.0"?>
<manifest package="com.zhangalps.biblemap" xmlns:android="http://schemas.android.com/apk/res/android" android:versionName="1.0" android:versionCode="1" android:installLocation="auto">
    <application android:hardwareAccelerated="true" android:name="org.qtproject.qt.android.bindings.QtApplication" android:label="@string/app_name" android:icon="@mipmap/ic_launcher">
        <activity android:configChanges="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|layoutDirection|locale|fontScale|keyboard|keyboardHidden|navigation|mcc|mnc|density" android:name="org.qtproject.qt.android.bindings.QtActivity" android:label="@string/app_name" android:screenOrientation="unspecified" android:launchMode="singleTop" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <meta-data android:name="android.app.lib_name" android:value="appBibileMap"/>
        </activity>
    </application>
</manifest>
"""
with open(os.path.join(android_dir, "AndroidManifest.xml"), "w", encoding="utf-8") as f:
    f.write(manifest_xml)

# Generate Icons
icon_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

svg_path = "resource/map.svg"

# Use PySide6 to render SVG to PNG
renderer = QSvgRenderer(svg_path)

if renderer.isValid():
    for mipmap_folder, size in icon_sizes.items():
        folder_path = os.path.join(res_dir, mipmap_folder)
        os.makedirs(folder_path, exist_ok=True)
        
        img = QImage(QSize(size, size), QImage.Format.Format_ARGB32)
        img.fill(Qt.GlobalColor.transparent)
        
        painter = QPainter(img)
        renderer.render(painter)
        painter.end()
        
        out_path = os.path.join(folder_path, "ic_launcher.png")
        img.save(out_path)
        print(f"Generated {out_path} ({size}x{size})")
else:
    print(f"Failed to load SVG: {svg_path}")

print("Android template setup complete.")
