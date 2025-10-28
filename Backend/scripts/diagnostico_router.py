# scripts/diagnostico_router.py
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    print("🔍 Intentando importar mercado_pago_router...")
    from routers.admin.mercado_pago_router import mercado_pago_router
    print("✅ Import exitoso!")
    
    # Verificar los endpoints del router
    print("📋 Endpoints en el router:")
    for route in mercado_pago_router.routes:
        print(f"  {route.methods} {route.path}")
        
except Exception as e:
    print(f"❌ Error importando router: {e}")
    import traceback
    traceback.print_exc()