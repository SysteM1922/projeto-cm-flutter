from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm.session import Session
from uuid import UUID

from app.database import get_session
from app.models import Route, Bus, Stop, BusStop, BusStop
from app.schemas import RouteCreate
from controllers.system import update_system

router = APIRouter(prefix="/route", tags=["Route"])

@router.post("/create")
async def create_route(data: RouteCreate, db: Session = Depends(get_session)):
    route = Route(route_name=data.route_name, route_number=data.route_number)

    try:
        db.add(route)
        db.commit()
        db.refresh(route)
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    await update_system(db)
    
    return {"route_id": route.id}

@router.get("/all")
async def get_all_routes(db: Session = Depends(get_session)):
    routes = db.query(Route).all()

    if not routes:
        return JSONResponse(content={"message": "No routes found"}, status_code=404)

    return [{"route_id": route.id, "route_name": route.route_name} for route in routes]

@router.get("/{route_id}")
async def get_route(route_id: UUID, db: Session = Depends(get_session)):
    route = db.query(Route).filter(Route.id == route_id).first()

    if route is None:
        return JSONResponse(content={"message": "Route not found"}, status_code=404)

    route_buses = db.query(Bus).filter(Bus.route_id == route.id).all()
    
    if not route_buses:
        return JSONResponse(content={"message": "No buses found for this route"}, status_code=404)
    
    buses_stops = []

    for bus in route_buses:
        bus_stops = db.query(BusStop).filter(BusStop.bus_id == bus.id).all()
        buses_stops.append({"bus_id": bus.id, "stops": [{"stop_id": bus_stop.stop_id, "stop_name": db.query(Stop).filter(Stop.id == bus_stop.stop_id).first().stop_name, "arrival_time": bus_stop.stop_time} for bus_stop in bus_stops]})

    return {"route_name": route.route_name, "buses": buses_stops}

@router.get("/stops/{route_id}")
async def get_route_stops(route_id: UUID, db: Session = Depends(get_session)):
    stops = db.query(BusStop).filter(BusStop.route_id == route_id).distinct(BusStop.stop_id).all()

    if not stops:
        return JSONResponse(content={"message": "No stops found for this route"}, status_code=404)

    stops = db.query(Stop).filter(Stop.id.in_([stop.stop_id for stop in stops])).all()

    return [{"stop_id": stop.id, "stop_name": stop.stop_name, "location": {"lat": stop.stop_location_lat, "long": stop.stop_location_long}} for stop in stops]

@router.delete("/{route_id}")
async def delete_route(route_id: UUID, db: Session = Depends(get_session)):
    route = db.query(Route).filter(Route.id == route_id).first()

    if route is None:
        return JSONResponse(content={"message": "Route not found"}, status_code=404)
    
    buses = db.query(Bus).filter(Bus.route_id == route_id).all()

    for bus in buses:
        bus_stops = db.query(BusStop).filter(BusStop.bus_id == bus.id).all()
        for bus_stop in bus_stops:
            db.delete(bus_stop)
        
        db.delete(bus)

    db.delete(route)
    db.commit()

    await update_system(db)

    return {"message": "Route deleted"}