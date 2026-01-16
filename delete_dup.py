
file_path = r"c:\Users\misal\Documents\link_saver_app\lib\main.dart"
start_line = 2542 # 1-based, inclusive
end_line = 2789   # 1-based, inclusive

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Adjust to 0-based
start_idx = start_line - 1
end_idx = end_line # Slice endpoint is exclusive, so this covers up to end_line-1.
# wait, if I want to delete up to end_line (index end_line-1), I should slice up to start_idx and from end_line.

new_lines = lines[:start_idx] + lines[end_idx:]

print(f"Original lines: {len(lines)}")
print(f"Deleting {end_idx - start_idx} lines.")
print(f"New lines: {len(new_lines)}")

# Debug check
print("Last kept line before cut:")
print(lines[start_idx-1])
print("First kept line after cut:")
print(lines[end_idx])

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
