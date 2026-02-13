import os

root_dir = r"c:\Users\Mujjo\Desktop\Zovetica"
target_dirs = ["lib", "test"]

replacements = {
    "package:zovetica/": "package:pets_and_vets/",
    "Zovetica": "Pets & Vets",
    "zovetica": "pets_and_vets",
    "paw_logo.png": "logo.png"
}

for d in target_dirs:
    target_path = os.path.join(root_dir, d)
    if not os.path.exists(target_path):
        continue
    for root, dirs, files in os.walk(target_path):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = content
                    for old, new in replacements.items():
                        new_content = new_content.replace(old, new)
                    
                    if new_content != content:
                        with open(file_path, 'w', encoding='utf-8', newline='') as f:
                            f.write(new_content)
                        print(f"Updated: {file_path}")
                except Exception as e:
                    print(f"Error updating {file_path}: {e}")
