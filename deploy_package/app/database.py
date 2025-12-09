"""
Database Configuration
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 🔴 Na szybko – na sztywno connection string
# docelowo wyniesiemy to z powrotem do ENV
_DB_URL = "mssql+pymssql://sqladmin:soQvm7kSnYxLZ98z@smart-brewery-sql-v3.database.windows.net:1433/smartbrewerydb"

engine = create_engine(
    _DB_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database - create all tables"""
    Base.metadata.create_all(bind=engine)
