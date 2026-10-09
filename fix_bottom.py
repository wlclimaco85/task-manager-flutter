import re
content = open('lib/mobile/screens/bottom_navbar_screen.dart', 'r', encoding='utf-8').read()
content = re.sub(r'if \(!ModuloAccess\.hasModulosConfigurados \|\| sec\.isMaster \|\| (tem[A-Za-z]+)\)', r'if (!ModuloAccess.hasModulosConfigurados || \1)', content)
open('lib/mobile/screens/bottom_navbar_screen.dart', 'w', encoding='utf-8').write(content)
print('Fixed bottom_navbar_screen.dart')
