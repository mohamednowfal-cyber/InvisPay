import re
import os

def check_translations():
    filepath = r'd:\Invispay\frontend\lib\core\i18n\translations.dart'
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Simple regex to extract language sections
    # It looks for 'lang_code': { ... }
    sections = re.findall(r"'([a-z]{2})': \{([\s\S]*?)\},", content)
    
    translations = {}
    for lang, data in sections:
        # Extract keys: 'key': 'value'
        keys = re.findall(r"'([a-zA-Z0-9_]+)':", data)
        translations[lang] = set(keys)

    if 'en' not in translations:
        print("English translations not found.")
        return

    en_keys = translations['en']
    print(f"Total English keys: {len(en_keys)}")

    for lang, keys in translations.items():
        if lang == 'en':
            continue
        
        missing = en_keys - keys
        extra = keys - en_keys
        
        if missing:
            print(f"[{lang}] Missing keys ({len(missing)}): {sorted(list(missing))}")
        if extra:
            print(f"[{lang}] Extra keys ({len(extra)}): {sorted(list(extra))}")

if __name__ == "__main__":
    check_translations()
