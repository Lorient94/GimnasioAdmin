from sqlmodel import create_engine, Session
from typing import Generator

# Configuración CORRECTA con la contraseña 123456
DATABASE_URL = "mysql+pymysql://root:123456@localhost:3308/gimnasio"
engine = create_engine(DATABASE_URL, echo=True)

def get_session() -> Generator[Session, None, None]:
    session = Session(engine)
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()