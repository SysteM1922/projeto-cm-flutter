from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from datetime import datetime
from sqlalchemy.orm.session import Session

from app.models import Route, Bus, Stop, BusStop, System
from app.database import get_session


router = APIRouter(prefix="/system", tags=["System"])

@router.get("/is_updated/{date}")
async def is_updated(date: datetime, db: Session = Depends(get_session)):
    last_update = db.query(System).first()

    if last_update.last_update < date:
        return JSONResponse(content={"message": "System is updated"}, status_code=200)
    
    return JSONResponse(content={"message": "System is not updated"}, status_code=404)

@router.get("/last_update")
async def last_updated(db: Session = Depends(get_session)):

    routes = db.query(Route).all()
    buses = db.query(Bus).all()
    stops = db.query(Stop).all()
    bus_stops = db.query(BusStop).all()

    return {"message": "System updated", "last_updated": datetime.now(), "routes": routes, "buses": buses, "stops": stops, "bus_stops": bus_stops}

async def update_system(db: Session):
    system = db.query(System).first()
    system.last_update = datetime.now()

    try:
        db.commit()
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)

    return {"message": "System updated"}
    




