import os
import zipfile
import shutil
import sys
import time
import re

# Input folder (contains subfolders with zips)
BASE_DIR = "/home/guga/Documents/Thesis/testing/collections/DIST_OBS_RESULTS"
# Output folder
OUTPUT_DIR = "/home/guga/Documents/Thesis/testing/filtered_collections"
# Websites file
WEBSITES_FILE = "/home/guga/Documents/Thesis/testing/resources/websites.txt"

INTERNAL_ZIP_DIR = "/testing/logs/wireshark"
ALT_INTERNAL_ZIP_DIR = "/home/guga/Documents/Thesis/testing/logs/wireshark"
# Map each folder name to a sample number
SAMPLE_MAP = {
    # "authority": 1,
    # "relay1": 2,
    # "relay2": 3,
    "exit1": 0,
    "client": 1,
}

SAMPLES_PER_WEBSITE = 50

pattern = re.compile(r"^www\.([a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+)_(\d+)\.pcap$")

# Ensure output dir exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

print(f"📂 Base directory: {BASE_DIR}")
print(f"📂 Output directory: {OUTPUT_DIR}")
print(f"📄 Websites file: {WEBSITES_FILE}")
print("-" * 60)
website_to_index = {}
with open(WEBSITES_FILE, "r") as f:
    for idx, line in enumerate(f):
        website = line.strip()
        if website:
            website_to_index[website] = idx

print(f"✅ Loaded {len(website_to_index)} websites from {WEBSITES_FILE}")
print("-" * 60)


def spinner():
    """Simple console spinner generator."""
    while True:
        for cursor in "||||||||||||////////////------------\\\\\\\\\\\\\\\\\\\\\\\\":
            yield cursor


spin = spinner()

# Walk through test folders
for test_folder in os.listdir(BASE_DIR):
    test_path = os.path.join(BASE_DIR, test_folder)
    if not os.path.isdir(test_path):
        continue

    print(f"🔧 Processing test folder: {test_folder}")

    # Find the zip file in this test folder
    for f in os.listdir(test_path):
        if f.endswith(".zip"):
            zip_path = os.path.join(test_path, f)
            print(f"   📦 Found zip file: {f}")

            # Prepare temp folder
            temp_dir = os.path.join(test_path, "temp_extract")
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
            os.makedirs(temp_dir, exist_ok=True)

            # Extract zip with progress
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                members = zip_ref.infolist()
                total = len(members)
                print(f"   📂 Extracting {total} files...")

                for i, member in enumerate(members, start=1):
                    zip_ref.extract(member, temp_dir)
                    sys.stdout.write(
                        f"\r   {next(spin)} Extracted {i}/{total} files..."
                    )
                    sys.stdout.flush()
                    time.sleep(0.001)

            sys.stdout.write("\r   ✅ Extraction complete!                      \n")
            sys.stdout.flush()

            # Process extracted folders
            for folder, sample_num in SAMPLE_MAP.items():
                folder_path = f"{temp_dir}{INTERNAL_ZIP_DIR}/{folder}"
                print(folder_path)
                # print(os.listdir(folder_path))
                if not os.path.exists(folder_path):
                    print(
                        f"   ⚠️ Folder '{folder}' not found inside zip, trying alternative folder structure."
                    )
                    folder_path = f"{temp_dir}{ALT_INTERNAL_ZIP_DIR}/{folder}"
                    if not os.path.exists(folder_path):
                        print(f"   ⚠️ Folder '{folder}' not found inside zip, skipping.")
                        continue

                dir_size = len(os.listdir(folder_path))
                print(f"   🔍 Looking into: {folder} [{dir_size} files]")

                for pcap_file in os.listdir(folder_path):
                    if not pcap_file.endswith(".pcap"):
                        continue

                    match = pattern.match(pcap_file)

                    if match:
                        website, id_num = match.groups()
                    else:
                        print(
                            f"❌ Error: filename '{pcap_file}' does not match expected pattern 'www.[website]_[id].pcap'"
                        )
                        continue

                    if website not in website_to_index:
                        print(f"   ⚠️ Extracted website '{website}' not in {WEBSITES_FILE}, skipping.")
                        continue

                    index = website_to_index[website]
                    new_name = f"{index}_{int(sample_num)*SAMPLES_PER_WEBSITE+int(id_num)}.pcap"
                    src = os.path.join(folder_path, pcap_file)
                    test_output_dir = f"{OUTPUT_DIR}/{test_folder}"
                    os.makedirs(test_output_dir, exist_ok=True)
                    dst = os.path.join(test_output_dir, new_name)

                    print(f"      📤 Copying {pcap_file} → {new_name}")
                    shutil.copy(src, dst)

            # Cleanup
            print(f"   🧹 Cleaning up temporary folder: {temp_dir}")
            shutil.rmtree(temp_dir)

    print(f"✅ Finished test folder: {test_folder}")
    print("-" * 60)

print("🎉 All done! All .pcap files collected.")
