# servicios/dashboard_service.py
import asyncio
from typing import Dict, Any
import httpx

class DashboardService:
    def __init__(self):
        self.base_url = "http://localhost:8000/api/admin"
    
    async def obtener_metricas_consolidadas(self) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            # Hacer requests paralelos a todos los dashboards
            tasks = [
                client.get(f"{self.base_url}/clientes/dashboard/estadisticas"),
                client.get(f"{self.base_url}/clases/reporte/ocupacion"),
                client.get(f"{self.base_url}/pagos/dashboard/estadisticas"),
                client.get(f"{self.base_url}/inscripciones/dashboard/estadisticas")
            ]
            
            responses = await asyncio.gather(*tasks)
            
            return {
                "clientes": responses[0].json(),
                "clases": responses[1].json(), 
                "pagos": responses[2].json(),
                "inscripciones": responses[3].json()
            }