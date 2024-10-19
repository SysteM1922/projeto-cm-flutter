from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm.session import Session
from uuid import UUID

from app.database import get_session

from app.models import Bus, BusStop, Route
from app.schemas import BusCreate, AddStop
from controllers.system import update_system

router = APIRouter(prefix="/bus", tags=["Bus"])

@router.post("/create")
async def create_bus(data: BusCreate, db: Session = Depends(get_session)):
    route = db.query(Route).filter(Route.id == data.route_id).first()
    bus = Bus(route_number=route.route_number, bus_name=data.bus_name, route_id=data.route_id)

    try:
        db.add(bus)
        db.commit()
        db.refresh(bus)
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    await update_system(db)
    
    return {"bus_id": bus.id}

@router.post("/add_stop")
async def add_stop(data: AddStop, db: Session = Depends(get_session)):
    route_id = db.query(Bus).filter(Bus.id == data.bus_id).first().route_id
    bus_stop = BusStop(bus_id=data.bus_id, stop_id=data.stop_id, stop_time=data.stop_time, route_id=route_id)

    try:
        db.add(bus_stop)
        db.commit()
        db.refresh(bus_stop)
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    await update_system(db)
    
    return {"bus_stop_id": bus_stop.id}

@router.get("/schedule/{bus_id}")
async def schedule_bus(bus_id: UUID, db: Session = Depends(get_session)):
    bus = db.query(Bus).filter(Bus.id == bus_id).first()

    if bus is None:
        return JSONResponse(content={"message": "Bus not found"}, status_code=404)

    bus_stops = db.query(BusStop).filter(BusStop.bus_id == bus.id).all()

    if not bus_stops:
        return JSONResponse(content={"message": "No stops found for this bus"}, status_code=404)
    
    return [{"stop_id": route_stop.stop_id, "arrival_time": route_stop.stop_time} for route_stop in bus_stops]

@router.delete("{bus_id}")
async def delete_bus(bus_id: UUID, db: Session = Depends(get_session)):
    bus = db.query(Bus).filter(Bus.id == bus_id).first()

    if bus is None:
        return JSONResponse(content={"message": "Bus not found"}, status_code=404)
    
    busStops = db.query(BusStop).filter(BusStop.bus_id == bus_id).all()

    for busStop in busStops:
        db.delete(busStop)

    db.delete(bus)
    db.commit()

    await update_system(db)

    return {"message": "Bus deleted"}

@router.delete("/stop/{bus_id}/{stop_id}")
async def delete_stop(bus_id: UUID, stop_id: UUID, db: Session = Depends(get_session)):
    bus_stop = db.query(BusStop).filter(BusStop.bus_id == bus_id, BusStop.stop_id == stop_id).first()

    if bus_stop is None:
        return JSONResponse(content={"message": "Stop not found"}, status_code=404)
    
    db.delete(bus_stop)
    db.commit()

    await update_system(db)

    return {"message": "Stop deleted"}


