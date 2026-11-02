import zipfile, struct

apk_path = r'C:\CP2077-Android-Engineering\dist\compatibility\Winlator_11.2.apk'
with zipfile.ZipFile(apk_path, 'r') as z:
    dex = z.read('classes.dex')

method_ids_off = struct.unpack('<I', dex[88:92])[0]
string_ids_off = struct.unpack('<I', dex[60:64])[0]

def get_string(idx):
    off = struct.unpack('<I', dex[string_ids_off + idx*4 : string_ids_off + (idx+1)*4])[0]
    p = off
    l = 0; s = 0
    while True:
        b = dex[p]; p += 1
        l |= (b & 0x7f) << s
        if not (b & 0x80): break
        s += 7
    return dex[p:p+l].decode('latin1', errors='ignore')

# Method 18340
m_off = method_ids_off + 18340 * 8
class_idx, proto_idx, name_idx = struct.unpack('<HHI', dex[m_off:m_off+8])
method_name = get_string(name_idx)
print(f'Method name for 18340: {method_name}')

# Print bytecode strings in method range (1755356 to 1755480)
code_bytes = dex[1755356:1755480]
print('Code bytes length:', len(code_bytes))
# Search for strings referenced in this range
for i in range(0, len(code_bytes)-2, 2):
    op = code_bytes[i]
    if op in (0x1a, 0x1b):
        reg = code_bytes[i+1]
        str_idx = struct.unpack('<H', code_bytes[i+2:i+4])[0]
        try:
            val = get_string(str_idx)
            print(f'  [offset {1755356+i}] const-string v{reg}, "{val}" (id {str_idx})')
        except:
            pass
