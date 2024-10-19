from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from datetime import datetime

sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

connect_args = {"check_same_thread": False}

engine = create_engine(sqlite_url, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def create_db_and_tables():
    from app.models import Base
    Base.metadata.create_all(bind=engine)
    # create an initial system
    from app.models import System
    from sqlalchemy.orm import Session
    db = SessionLocal()
    last_update = db.query(System).first()
    if last_update is not None:
        return
    system = System(last_update=datetime.now())
    db.add(system)
    db.commit()
    db.close()

def get_session():
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()