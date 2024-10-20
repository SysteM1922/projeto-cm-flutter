from sqlalchemy import DATETIME, Column, UUID, String, Integer, Float
from uuid import uuid4
from random import randint

from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID, default=uuid4, primary_key=True)
    username = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    firebase_uid = Column(String, index=True, unique=True, nullable=False)
    card_number = Column(Integer, default=randint(1000000000000000, 9999999999999999), index=True, unique=True)

class Travel(Base):
    __tablename__ = "travels"

    id = Column(UUID, default=uuid4, primary_key=True)
    travel_history_id = Column(UUID, index=True, nullable=False)
    date = Column(DATETIME, nullable=False)
    route_number = Column(String, nullable=False)

class TravelHistory(Base):
    __tablename__ = "travel_history"

    id = Column(UUID, default=uuid4, primary_key=True)
    user_id = Column(UUID, index=True, nullable=False)

class Stop(Base):
    __tablename__ = "stops"

    id = Column(UUID, default=uuid4, primary_key=True)
    stop_name = Column(String, nullable=False)
    stop_location_lat = Column(Float, nullable=False)
    stop_location_long = Column(Float, nullable=False)

class Route(Base):
    __tablename__ = "routes"

    id = Column(UUID, default=uuid4, primary_key=True)
    route_name = Column(String, nullable=False)
    route_number = Column(Integer, nullable=False)

class Bus(Base):
    __tablename__ = "buses"

    id = Column(UUID, default=uuid4, primary_key=True)
    route_number = Column(Integer, nullable=False)
    bus_name = Column(String, nullable=False)
    route_id = Column(UUID, index=True, nullable=False)

class BusStop(Base):
    __tablename__ = "bus_stops"

    id = Column(UUID, default=uuid4, primary_key=True)
    stop_id = Column(UUID, index=True, nullable=False)
    bus_id = Column(UUID, index=True, nullable=False)
    route_id = Column(UUID, index=True, nullable=False)
    stop_time = Column(DATETIME, nullable=True)

class System(Base):
    __tablename__ = "system"

    id = Column(UUID, default=uuid4, primary_key=True)
    last_update = Column(DATETIME, nullable=False)