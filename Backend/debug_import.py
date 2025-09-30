import sys, traceback, importlib
# Aseguramos que el path actual ('Backend') está en sys.path
sys.path.insert(0, '.')
try:
    importlib.import_module('routers.admin.admin_clase_router')
    print('IMPORT_OK')
except Exception:
    traceback.print_exc()
