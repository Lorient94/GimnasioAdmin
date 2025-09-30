def test_app_root(client):
    """Test básico para verificar que la app funciona"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "funcionando" in response.json()["message"].lower()

def test_health_check(client):
    """Test del endpoint health"""
    response = client.get("/health")
    assert response.status_code == 200
    assert "status" in response.json()