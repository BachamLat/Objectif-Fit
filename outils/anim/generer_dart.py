"""Régénère lib/widgets/anim_data.dart depuis outils/anim/anim.json (à lancer depuis la racine du projet)."""
import json
d = json.load(open('outils/anim/anim.json', encoding='utf-8'))
s = json.dumps(d, ensure_ascii=False, separators=(',', ':'))
assert "'''" not in s and '$' not in s
open('lib/widgets/anim_data.dart', 'w', encoding='utf-8').write(
    "// Généré depuis outils/anim/anim.json (schémas animés des machines). Ne pas modifier à la main.\nconst String animJson = r'''" + s + "''';\n")
print('lib/widgets/anim_data.dart régénéré')
