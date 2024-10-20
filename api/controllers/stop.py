from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm.session import Session
from uuid import UUID

from app.database import get_session
from app.models import Stop, Bus, BusStop
from app.schemas import StopCreate
from controllers.system import update_system

router = APIRouter(prefix="/stop", tags=["Stop"])

@router.post("/create")
async def create_stop(data: StopCreate, db: Session = Depends(get_session)):
    stop = Stop(stop_name=data.stop_name, stop_location_lat=data.stop_location_lat, stop_location_long=data.stop_location_long)

    try:
        db.add(stop)
        db.commit()
        db.refresh(stop)
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    await update_system(db)
    
    return {"stop_id": stop.id}

@router.get("/schedule/{stop_id}")
async def get_stop_schedule(stop_id: UUID, db: Session = Depends(get_session)):
    route_stops = db.query(BusStop).filter(BusStop.stop_id == stop_id).all()

    if not route_stops:
        return JSONResponse(content={"message": "No buses scheduled for this stop"}, status_code=404)

    arrival_times = []
    for route_stop in route_stops:
        bus = db.query(Bus).filter(Bus.id == route_stop.bus_id).first()
        arrival_times.append({"bus_id": bus.id, "route_id": bus.route_id, "route_number": bus.route_number, "arrival_time": route_stop.stop_time})

    return arrival_times

@router.get("/location/{stop_id}")
async def get_stop_location(stop_id: UUID, db: Session = Depends(get_session)):
    stop = db.query(Stop).filter(Stop.id == stop_id).first()

    if stop is None:
        return JSONResponse(content={"message": "Stop not found"}, status_code=404)

    return {"stop_name": stop.stop_name, "location": {"lat": stop.stop_location_lat, "long": stop.stop_location_long}}

@router.get("/all")
async def get_all_stops(db: Session = Depends(get_session)):
    stops = db.query(Stop).all()

    if not stops:
        return JSONResponse(content={"message": "No stops found"}, status_code=404)

    return [{"stop_id": stop.id, "stop_name": stop.stop_name, "location": {"lat": stop.stop_location_lat, "long": stop.stop_location_long}} for stop in stops]

@router.get("/all_names")
async def get_all_stop_names(db: Session = Depends(get_session)):
    stops = db.query(Stop).all()

    if not stops:
        return JSONResponse(content={"message": "No stops found"}, status_code=404)

    return [{"stop_id": stop.id, "stop_name": stop.stop_name} for stop in stops]

@router.delete("/{stop_id}")
async def delete_stop(stop_id: UUID, db: Session = Depends(get_session)):
    stop = db.query(Stop).filter(Stop.id == stop_id).first()

    if stop is None:
        return JSONResponse(content={"message": "Stop not found"}, status_code=404)
    
    bus_stops = db.query(BusStop).filter(BusStop.stop_id == stop_id).all()

    for bus_stop in bus_stops:
        db.delete(bus_stop)

    db.delete(stop)
    db.commit()

    await update_system(db)

    return {"message": "Stop deleted"}