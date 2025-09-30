# Casos_de_uso/consultar_usuarios.py
from typing import Any, Dict, List
from sqlmodel import Session

from Adaptadores.adaptadorClienteSQL import AdaptadorClienteSQL


class ConsultarUsuariosCase:
    def __init__(self, session: Session):
        self.session = session
        self.repositorio_clientes = AdaptadorClienteSQL(session)
    
    def ejecutar(self, filtros: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        usuarios = self.repositorio_clientes.listar_clientes(filtros)
        
        # Enriquecer datos con estadísticas
        usuarios_enriquecidos = []
        for usuario in usuarios:
            stats = self._obtener_estadisticas_usuario(usuario.dni)
            usuarios_enriquecidos.append({
                **usuario.dict(),
                'total_inscripciones': stats['total_inscripciones'],
                'inscripciones_activas': stats['inscripciones_activas'],
                'total_pagado': stats['total_pagado'],
                'ultimo_pago': stats['ultimo_pago']
            })
        
        return usuarios_enriquecidos
    
    def _obtener_estadisticas_usuario(self, dni: str) -> Dict[str, Any]:
        # Implementar lógica de estadísticas
        pass