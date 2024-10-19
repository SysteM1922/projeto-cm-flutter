from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class UserCreate(BaseModel):
    username: str
    email: str
    firebase_uid: str

class TravelCreate(BaseModel):
    bus_id: UUID
    user_id: UUID

class RouteCreate(BaseModel):
    route_name: str
    route_number: int

class BusCreate(BaseModel):
    bus_name: str
    route_id: UUID

class StopCreate(BaseModel):
    stop_name: str
    stop_location_lat: float
    stop_location_long: float

class AddStop(BaseModel):
    bus_id: UUID
    stop_id: UUID
    stop_time: datetime