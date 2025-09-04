def test_siempre_pasa():
    """Test básico que siempre pasa"""
    assert 1 + 1 == 2

def test_otro_ejemplo():
    """Otro test básico"""
    nombre = "Juan"
    assert nombre == "Juan"

class TestClaseBasica:
    def test_metodo_clase(self):
        assert True
        
    def test_otro_metodo(self):
        resultado = 5 * 2
        assert resultado == 10