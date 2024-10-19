from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm.session import Session
from uuid import UUID

from app.database import get_session
from app.models import Travel, TravelHistory, Bus
from app.schemas import TravelCreate

from datetime import datetime

router = APIRouter(prefix="/travel", tags=["Travel"])

@router.post("/register")
async def register_travel(data: TravelCreate, db: Session = Depends(get_session)):
    travel_history = db.query(TravelHistory).filter(TravelHistory.user_id == data.user_id).first()
    if not travel_history:
        travel_history = TravelHistory(user_id=data.user_id)

        try:
            db.add(travel_history)
            db.commit()
            db.refresh(travel_history)
        except Exception:
            return JSONResponse(content={"message": "An error occurred"}, status_code=500)

    bus = db.query(Bus).filter(Bus.id == data.bus_id).first()

    travel = Travel(travel_history_id=travel_history.id, date=datetime.now(), route_number=bus.route_number)

    try:
        db.add(travel)
        db.commit()
        db.refresh(travel)
    except Exception:    
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    return {"travel_id": travel.id}

@router.delete("/{travel_id}")
async def delete_travel(travel_id: UUID, db: Session = Depends(get_session)):
    travel = db.query(Travel).filter(Travel.id == travel_id).first()

    if travel is None:
        return JSONResponse(content={"message": "Travel not found"}, status_code=404)
    
    try:
        db.delete(travel)
        db.commit()
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)
    
    return {"message": "Travel deleted"}